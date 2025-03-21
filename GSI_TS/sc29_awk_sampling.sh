#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc29_awk_sampling.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc29_awk_sampling.sh.%J.err
#SBATCH --job-name=sc29_awk_sampling.sh 
#SBATCH --mem=10G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc29_awk_sampling.sh 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract
EXTRACTpy=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
EXTRACTpyS=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample
cd $EXTRACTpyS

module load StdEnv

# Number of folds
num_folds=5

# Create an associative array to store groups by IDraster
declare -A groups

# Read the input file and group rows by IDraster
while read -r line; do
    idraster=$(echo "$line" | awk '{print $4}')
    groups["$idraster"]+="$line\n"
done < $EXTRACT/stationID_x_y_valueALL_predictors.txt

# Distribute groups into folds
fold=0
for idraster in "${!groups[@]}"; do
    echo -e "${groups[$idraster]}" >> "stationID_x_y_valueALL_predictors_s${fold}.txt"
    fold=$(( (fold + 1) % num_folds ))
done

