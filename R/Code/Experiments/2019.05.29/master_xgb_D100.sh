#!/bin/bash

#SBATCH
#SBATCH --job-name=xgb_uci
#SBATCH --time=3-0:0:0
#SBATCH --nodes=1-23,25-106
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=24
#SBATCH --mem=120G
#SBATCH --partition=parallel
#SBATCH --exclusive
#SBATCH --mail-type=end
#SBATCH --mail-user=tmtomita87@gmail.com

# Print this sub-job's task ID
echo "My SLURM_ARRAY_TASK_ID: " $SLURM_ARRAY_TASK_ID

NAME_FILE=~/work/tyler/Data/uci/processed/names.txt
DATASET=$(sed "${SLURM_ARRAY_TASK_ID}q;d" $NAME_FILE)

sed "s/abalone/${DATASET}/g" run_Benchmarks_noise_D100_xgb_2019_05_29.R > task${SLURM_ARRAY_TASK_ID}_xgb.R

Rscript task${SLURM_ARRAY_TASK_ID}_xgb.R

rm task${SLURM_ARRAY_TASK_ID}_xgb.R

echo "job complete"
