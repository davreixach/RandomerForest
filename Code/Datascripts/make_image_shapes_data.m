close all
clear
clc

rng(1);

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

Train = 1:10000;
HoldOut = Train + 10000;
Test = HoldOut + 10000;
n = length(Train) + length(HoldOut) + length(Test);
ns = [50 100 200];
ih = 32;
iw = ih;
p = ih*iw;

X_image = zeros(ih,iw,n);
[rowidx,colidx] = ind2sub([ih,iw],1:p);
radius = ceil(rand(1,n)*3) + 9;
Y = zeros(n,1);

%Class 0
for i = 1:n/2
    centroid(i,:) = randi(ih-radius(i)*2,1,2) + radius(i);
    x = zeros(ih,iw);
    x(sqrt(sum(([rowidx',colidx'] - repmat(centroid(i,:),p,1)).^2,2)) <= radius(i)) = 1;
    X_image(:,:,i) = x;
end

%Class 1
for i = n/2+1:n
    centroid(i,:) = randi(ih-radius(i)*2,1,2) + radius(i);
    x = zeros(ih,iw);
    x(abs(rowidx-centroid(i,1))<=radius(i)&abs(colidx-centroid(i,2))<=radius(i)) = 1;
    X_image(:,:,i) = x;
end
Y(n/2+1:end) = 1;

NewOrdering = randperm(n);
X_image = X_image(:,:,NewOrdering);
Y = Y(NewOrdering);
Labels = unique(Y);

%Col 1==Train, 2=HoldOut, 3=Test
GrpIdx = false(n,3);
GrpIdx(Train,1) = true;
GrpIdx(HoldOut,2) = true;
GrpIdx(Test,3) = true;
Train = GrpIdx(:,1);
HoldOut = GrpIdx(:,2);
Test = GrpIdx(:,3);

ntrials = 10;

for k = 1:length(ns)
        nsub = ns(k);
    
    for trial = 1:ntrials

        Idx = [];
        for l = 1:length(Labels)
            Idx = [Idx randsample(find(Y==Labels(l)&GrpIdx(:,1)),round(nsub/length(Labels)))'];
        end
        TrainIdx{k}(trial,:) = Idx(randperm(length(Idx)));
    end
end

save([rerfPath 'RandomerForest/Data/image_shapes_data.mat'],'ns','ntrials',...
    'X_image','Y','TrainIdx','HoldOut','Test')