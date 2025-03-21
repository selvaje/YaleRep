#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc40_scatterplot.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc40_scatterplot.sh.%J.err
#SBATCH --job-name=sc40_scatterplot.sh
#SBATCH --mem=5G


#### sbatct    /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc40_scatterplot.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# export obs=50
export obs=$obs 
echo "obs" $obs

export SAMPLE=9584655  # >= 0 all response rows   9584655 
echo "sampling" $SAMPLE

export N_EST=$SLURM_ARRAY_TASK_ID
# export N_EST=100
echo   "n_estimators"  $N_EST

module load miniconda/23.5.2
# conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsim2  python=3  numpy scipy pandas matplotlib  scikit-learn
# conda search pandas 
source activate env_gsim2
echo $CONDA_DEFAULT_ENV

echo "start python modeling"

#### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

cd $EXTRACT/../extract4mod
python3 <<'EOF'
import os, sys 
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages

obs_pred  = pd.read_csv('./obs_pred.txt.txt', header=0, sep=' ')
df.plot(kind='scatter', x='MEANp', y='MEANo')
with PdfPages('scatterplotMEAN.pdf') as pdf:
    pdf.savefig()
plt.show()

EOF
