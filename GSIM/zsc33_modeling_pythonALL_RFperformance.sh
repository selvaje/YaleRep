#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 5  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc33_modeling_pythonALL_RFperformance.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc33_modeling_pythonALL_RFperformance.sh.%J.err
#SBATCH --job-name=sc33_modeling_pythonALL_RFperformance.sh
#SBATCH --mem=80G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc33_modeling_pythonALL_RFperformance.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract4mod
cd $EXTRACT

module load StdEnv miniconda/23.5.2
source activate env_gsim2
echo "start python modeling"
export SAMPLE=10000

python3 <<'EOF'
import os, sys 
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.experimental import enable_halving_search_cv
from sklearn.model_selection import HalvingRandomSearchCV, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.multioutput import MultiOutputRegressor
from sklearn.metrics import make_scorer, mean_squared_error

from scipy import stats
from scipy.stats import pearsonr

import dill

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)

# Load the entire workspace from a file

with open(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_workspace.pkl' , 'rb') as f:
     dill.load_session(f)

print("OOB score" ,  RFreg.oob_score_) 
                                                                                                    
# Get feature importances and sort them in descending order     
importances = RFreg.feature_importances_
indices = np.argsort(importances)[::-1]

# Print feature names and their importance scores in descending order 
print("Feature ranking:")
importance = []
for f in range(X_train.shape[1]):
    importance  += ("%d. %s (%f)" % (f + 1, X_train.columns[indices[f]], importances[indices[f]]))
    print(importance)

# To save the output to a file
with open(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_importance.txt', "rb") as f:
    f.write(importance)

EOF

