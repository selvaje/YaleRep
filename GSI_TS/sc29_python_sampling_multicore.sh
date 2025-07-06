#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 10  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc29_python_sampling_multicore.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc29_python_sampling_multicore.sh.%J.err
#SBATCH --job-name=sc29_python_sampling_multicore.sh 
#SBATCH --mem=100G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc29_python_sampling_multicore.sh 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract
cd $EXTRACT


module load StdEnv

# source /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin/activate 
apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'

import pandas as pd
from multiprocessing import Pool

# Input file name
input_file = 'stationID_x_y_valueALL_predictors.txt'

# Output file prefix
output_prefix = 'stationID_x_y_valueALL_predictors2_sampM'

# Number of folds
num_folds = 3

# Read the input file into a pandas DataFrame
df = pd.read_csv(input_file, sep='\s+' ) # 

# Group by 'IDr' and split into 5 folds
groups = df.groupby('IDr')
folds = [pd.DataFrame() for _ in range(num_folds)]

for i, (name, group) in enumerate(groups):
    folds[i % num_folds] = pd.concat([folds[i % num_folds], group])

# Function to write a fold to a file
def write_fold_to_file(fold_index):
    fold = folds[fold_index]
    fold.to_csv(f'/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample/{output_prefix}{fold_index}.txt', sep=' '  , index=False, header=True)

# Use multiprocessing to write folds to files in parallel
if __name__ == '__main__':
    with Pool(num_folds) as p:
        p.map(write_fold_to_file, range(num_folds))

EOF

"

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample
#### sample neeed for sc30 
for samp in 0 1 2  ; do
echo samp $samp 
head -1 $EXTRACT/stationID_x_y_valueALL_predictors2_sampM$samp.txt | cut -d " " -f1-19     > $EXTRACT/stationID_x_y_valueALL_predictors2_sampM${samp}_Ys.txt
awk '{ if (NR>1) print}' $EXTRACT/stationID_x_y_valueALL_predictors2_sampM$samp.txt | cut -d " " -f1-19 | sort -n -k 4,4 >> $EXTRACT/stationID_x_y_valueALL_predictors2_sampM${samp}_Ys.txt 

head -1 $EXTRACT/stationID_x_y_valueALL_predictors2_sampM$samp.txt | cut -d " " -f1-8,20- > $EXTRACT/stationID_x_y_valueALL_predictors2_sampM${samp}_Xs.txt
awk '{ if (NR>1) print}' $EXTRACT/stationID_x_y_valueALL_predictors2_sampM$samp.txt | cut -d " " -f1-8,20- | sort -n -k 4,4 >> $EXTRACT/stationID_x_y_valueALL_predictors2_sampM${samp}_Xs.txt 
done 

exit 
### full  dataset for the sc31
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
cut -d " " -f1-19       $EXTRACT/extract/stationID_x_y_valueALL_predictors.txt  >   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y.txt
cut -d " " -f1-8,20-    $EXTRACT/extract/stationID_x_y_valueALL_predictors.txt  >   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X.txt 

head -1  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y.txt       >  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y11.txt
grep -e ^11   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y.txt >>  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y11.txt

head -1  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X.txt       >  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X11.txt
grep -e ^11   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X.txt >>  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X11.txt

head -1  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y.txt       >  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y1.txt
grep -e ^1   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y.txt >>  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_Y1.txt

head -1  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X.txt       >  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X1.txt
grep -e ^1   $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X.txt >>  $EXTRACT/extract4py/stationID_x_y_valueALL_predictors_X1.txt

