# evaluate classifiers on benchmark datasets

rm(list=ls())
options(scipen = 999)

rerfPath <- "~/work/tyler/"
dataPath <- "~/work/tyler/Data/uci/processed/"
dataPath2 <- "~/work/tyler/Data/uci/gaussian_noise_p100.csv"
library(rerf)
library(AUC)
library(dummies)
source(paste0(rerfPath, "RandomerForest/R/Code/Utils/RerFEval.R"))
source(paste0(rerfPath, "RandomerForest/R/Code/Utils/GetCatMap.R"))
source(paste0(rerfPath, "RandomerForest/R/Code/Utils/GetFolds.R"))

classifiers <- c("rf", "rerf", "frc", "rr-rf")
nCl <- length(classifiers)

nTrees <- 500L
min.parent <- 2L
max.depth <- 0L
supervised = 0
num.cores <- 24L
seed <- 02072018L

testError <- list()
testAUC <- list()
OOBError <- list()
OOBAUC <- list()
trainTime <- list()
OOBTime <- list()
testTime <- list()
treeStrength <- list()
treeCorr <- list()
numNodes <- list()
bestIdx <- list()
params <- list()

dataSet <- "abalone"
fold <- GetFolds(paste0(dataPath, "cv_partitions/", dataSet, "_partitions.txt"))
nFolds <- length(fold)
X <- as.matrix(read.table(paste0(dataPath, "data/", dataSet, ".csv"), header = F, sep = ",", quote = "", row.names = NULL))
catMap <- NULL
p <- ncol(X) - 1L
Y <- as.integer(X[, p + 1L]) + 1L
X <- X[, -(p + 1L)]
# remove columns with zero variance
X <- X[, apply(X, 2, function(x) any(as.logical(diff(x))))]
# mean-center and scale by sd
X <- scale(X)
n <- nrow(X)

# read in noisy features and append to X
Xnoise <- as.matrix(read.table(dataPath2, header = F, sep = ",", quote = "", row.names = NULL, nrows = n))
X <- cbind(X, Xnoise)
p <- ncol(X)
p.ohe <- p

testError[[dataSet]] <- vector(mode = "list", length = nCl)
names(testError[[dataSet]]) <- classifiers
testAUC[[dataSet]] <- vector(mode = "list", length = nCl)
names(testAUC[[dataSet]]) <- classifiers
OOBError[[dataSet]] <- vector(mode = "list", length = nCl)
names(OOBError[[dataSet]]) <- classifiers
OOBAUC[[dataSet]] <- vector(mode = "list", length = nCl)
names(OOBAUC[[dataSet]]) <- classifiers
trainTime[[dataSet]] <- vector(mode = "list", length = nCl)
names(trainTime[[dataSet]]) <- classifiers
OOBTime[[dataSet]] <- vector(mode = "list", length = nCl)
names(OOBTime[[dataSet]]) <- classifiers
testTime[[dataSet]] <- vector(mode = "list", length = nCl)
names(testTime[[dataSet]]) <- classifiers
treeStrength[[dataSet]] <- vector(mode = "list", length = nCl)
names(treeStrength[[dataSet]]) <- classifiers
treeCorr[[dataSet]] <- vector(mode = "list", length = nCl)
names(treeCorr[[dataSet]]) <- classifiers
numNodes[[dataSet]] <- vector(mode = "list", length = nCl)
names(numNodes[[dataSet]]) <- classifiers
bestIdx[[dataSet]] <- vector(mode = "list", length = nCl)
names(bestIdx[[dataSet]]) <- classifiers
params[[dataSet]] <- vector(mode = "list", length = nCl)
names(params[[dataSet]]) <- classifiers

for (m in classifiers) {

  if (m == "rf") {
    random.matrix <- "rf"
    if (p < 5) {
      mtrys <- 1:p
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1))
    }
    sparsity <- 1/p # this parameter doesn't actually matter for RF
  } else if (m == "rr-rf" || m == "rr-rfr") {
    random.matrix <- "rf"
    if (p.ohe < 5) {
      mtrys <- 1:p.ohe
    } else {
      mtrys <- ceiling(p.ohe^c(1/4, 1/2, 3/4, 1))
    }
    sparsity <- 1/p.ohe # this parameter doesn't actually matter for RF
  } else if (m == "rerf" || m == "rerfr") {
    random.matrix <- "binary"
    if (p < 5) {
      mtrys <- c(1:p, p^2)
    } else if (p >= 5 && p <= 100) {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 2))
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 1.5))
    }
    sparsity <- (1:min(p-1, 5))/p
  } else if (m == "rerfc" || m == "rerfcr") {
    random.matrix <- "continuous"
    if (p < 5) {
      mtrys <- c(1:p, p^2)
    } else if (p >= 5 && p <= 100) {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 2))
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 1.5))
    }
    sparsity <- (1:min(p-1, 5))/p
  } else if (m == "rerfp" || m == "rerfpr") {
    random.matrix <- "poisson"
    if (p < 5) {
      mtrys <- c(1:p, p^2)
    } else if (p >= 5 && p <= 100) {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 2))
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 1.5))
    }
    sparsity <- (1:min(ceiling(p/2), 5))
  } else if (m == "frc" || m == "frank") {
    random.matrix <- "frc"
    if (p < 5) {
      mtrys <- c(1:p, p^2)
    } else if (p >= 5 && p <= 100) {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 2))
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 1.5))
    }
    sparsity <- (2:min(p, 5))
  } else if (m == "frcn") {
    random.matrix <- "frcn"
    if (p < 5) {
      mtrys <- c(1:p, p^2)
    } else if (p >= 5 && p <= 100) {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 2))
    } else {
      mtrys <- ceiling(p^c(1/4, 1/2, 3/4, 1, 1.5))
    }
    sparsity <- (2:min(p, 5))
  }

  if (m == "rr-rf" || m == "rr-rfr") {
    rotate <- T
  } else {
    rotate <- F
  }

  if (m == "rerfr" || m == "rerfpr" || m == "rerfcr" || m == "frank" || m == "rr-rfr") {
    rank.transform <- T
  } else {
    rank.transform <- F
  }

  params[[dataSet]][[m]] <- list(trees = nTrees, random.matrix = random.matrix, d = mtrys, sparsity = sparsity, rotate = rotate,
                                 rank.transform = rank.transform, min.parent = min.parent, max.depth = max.depth, num.cores = num.cores,
                                 seed = seed, cat.map = catMap, supervised = supervised)

  testError[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  testAUC[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  OOBError[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  OOBAUC[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  trainTime[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  OOBTime[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  testTime[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  treeStrength[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  treeCorr[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  numNodes[[dataSet]][[m]] <- matrix(as.double(rep(NA, nFolds*length(sparsity)*length(mtrys)*length(supervised))),
                                      nrow = nFolds, ncol = length(sparsity)*length(mtrys)*length(supervised))
  bestIdx[[dataSet]][[m]] <- as.integer(rep(NA, nFolds))

  # loop over folds
  for (k in seq.int(nFolds)) {
    print(paste0("fold ", k))

    trainIdx <- unlist(fold[-k])
    testIdx <- fold[[k]]

    # evaluate models
    res <- RerFEval(X[trainIdx, ], Y[trainIdx], X[testIdx, ], Y[testIdx], params[[dataSet]][[m]])

    testError[[dataSet]][[m]][k, ] <- res$testError
    testAUC[[dataSet]][[m]][k, ] <- res$testAUC
    OOBError[[dataSet]][[m]][k, ] <- res$oobError
    OOBAUC[[dataSet]][[m]][k, ] <- res$oobAUC
    trainTime[[dataSet]][[m]][k, ] <- res$trainTime
    OOBTime[[dataSet]][[m]][k, ] <- res$oobTime
    testTime[[dataSet]][[m]][k, ] <- res$testTime
    treeStrength[[dataSet]][[m]][k, ] <- res$treeStrength
    treeCorr[[dataSet]][[m]][k, ] <- res$treeCorrelation
    numNodes[[dataSet]][[m]][k, ] <- res$numNodes
    bestIdx[[dataSet]][[m]][k] <- res$best.idx

    save(testError, testAUC, OOBError, OOBAUC, trainTime, OOBTime, testTime, treeStrength, treeCorr, numNodes, bestIdx, params, file = paste0(rerfPath, "RandomerForest/R/Results/2019.05.29/", dataSet, "_noise_D100_2019_05_29.RData"))
  }
}
