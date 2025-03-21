#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc32_modeling_pythonALL_RF_RenkSelection.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc32_modeling_pythonALL_RF_RenkSelection.sh.%A_%a.err
#SBATCH --job-name=sc32_modeling_pythonALL_RF_RenkSelection.sh
#SBATCH --array=1,2,3
#SBATCH --mem=350G

##### 
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc32_modeling_pythonALL_RF_RenkSelection.sh
#### 2 4 5 8 10 15 
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# geom   103 # remove only geom
# order_hack    
# order_horton
# order_shreve
# order_strahler
# order_topo 

# export obs=50
export obs=8
echo "obs" $obs

export Yvar=$(expr  $SLURM_ARRAY_TASK_ID - 1  ) 
# export Yvar=1
echo "Yvar" $Yvar

export SAMPLE=9584655  # >= 0 all response rows   9584655 
echo "sampling" $SAMPLE

export N_EST=200
echo  "n_estimators" $N_EST

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
from numpy import savetxt
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.feature_selection import RFECV
from sklearn.feature_selection import RFE
from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.metrics import mean_squared_error
from scipy import stats
from scipy.stats import pearsonr
from sklearn.metrics import r2_score

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)

Yvar_i=int(os.environ["Yvar"])
Yvar_s=(os.environ["Yvar"])
print(Yvar_s)

obs_i=int(os.environ["obs"])
obs_s=(os.environ["obs"])
print(obs_s)

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randS3Y{SAMPLE}.txt', header=0, sep=' ')

X_selected_var  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_importanceS3N{N_EST_S}_8obs.txt', header=None , sep=' ')

#### base on score value 
X_selected_var = X_selected_var.loc[(X_selected_var[1] > 0.002)][0]
#### base on score index e.g. 50 
#### X_selected_var = X_selected_var.head(50)[0]
 
X_train_selected = X_train.loc[:,X_selected_var]
del X_train

RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=16 , oob_score=True ,  bootstrap=True ,   min_samples_leaf=obs_i , min_samples_split=obs_i)

selected_RFECV_tmp   = RFECV( RFreg, min_features_to_select=10, cv=5, step=1,  n_jobs=16, scoring='neg_mean_squared_error')
selected_RFECV_tmp.fit(X_train_selected, Y_train.iloc[:,Yvar_i])
print(selected_RFECV_tmp.oob_score_)
sel_tmp = np.array(np.array(X_train_selected.columns))[selected_RFECV_tmp.support_]
selected_var.extend(sel_tmp)
del selected_RFECV_tmp
del sel_tmp

# Print the list
print(selected_var)

print(selected_var)
print(len(selected_var))

selected_var.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_Xsel_{Yvar_s}.txt', index=False , sep=' ' , header=True)

EOF
