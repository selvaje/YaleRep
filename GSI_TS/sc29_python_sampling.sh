#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc29_python_sampling.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc29_python_sampling.sh.%J.err
#SBATCH --job-name=sc29_python_sampling.sh 
#SBATCH --mem=50G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc29_python_sampling.sh 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract
cd $EXTRACT

module load StdEnv


apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
 --env=obs=$obs,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'

import pandas as pd
import numpy as np

# Input file name
input_file = 'stationID_x_y_valueALL_predictors.txt'

# Output file prefix
output_prefix = 'stationID_x_y_valueALL_predictors_samp'

# Number of folds
num_folds = 5

# Read the input file into a pandas DataFrame
df = pd.read_csv(input_file, delim_whitespace=True)

# Group by 'IDraster' and split into 10 folds
groups = df.groupby('IDraster')
folds = [pd.DataFrame() for _ in range(num_folds)]

for i, (name, group) in enumerate(groups):
    folds[i % num_folds] = pd.concat([folds[i % num_folds], group])

# Write each fold to a separate file
for i, fold in enumerate(folds):
    fold.to_csv(f'{output_prefix}{i}.txt', sep='\s+', index=False , header=True)

EOF

"
