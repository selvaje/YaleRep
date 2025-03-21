#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenk.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenk.sh.%A_%a.err
#SBATCH --job-name=sc31_modeling_pythonALL_RFrunMainRespRenk.sh
#SBATCH --array=200,400,500
#SBATCH --mem=300G

##### #SBATCH --array=200,400,500,600
#### for obs in 2 4 5 8 10  ; do sbatch --export=obs=$obs   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc31_modeling_pythonALL_RFrunMainRespRenk.sh ; done 
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

obs_s=(os.environ["obs"])
print(obs_s)

obs_i=int(os.environ["obs"])

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randS3Y{SAMPLE}.txt', header=0, sep=' ')

X_selected_var  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_importanceS3N{N_EST_S}_8obs.txt', header=None , sep=' ')

#### base on score value 
X_selected_var = X_selected_var.loc[(X_selected_var[1] > 0.01)][0]
#### base on score index e.g. 50 
#### X_selected_var = X_selected_var.head(50)[0]
 
X_train_selected = X_train.loc[:,X_selected_var]

print(Y_train.shape)
print(X_train.shape)
print(X_train_selected.shape)

del X_train

print("Run RF with - no testing ")
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=16 , oob_score=True ,  bootstrap=True ,   min_samples_leaf=obs_i , min_samples_split=obs_i)
RFreg.fit(X_train_selected, Y_train)

#### make prediction using th oob
savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YpredictN{N_EST_S}_{obs_s}obs_2RF.txt', RFreg.oob_prediction_, delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")

print("OOB score" ,  RFreg.oob_score_)
print("Score" ,  RFreg.score)

oob_r2 = np.array([RFreg.oob_score_])
r2 = RFreg.score(X_train_selected, Y_train)

N=np.array(N_EST_I)

oob_mse = mean_squared_error(Y_train, RFreg.oob_prediction_)
mse = mean_squared_error(Y_train, RFreg.predict(X_train_selected))

rMEAN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 0])[0]
rMIN  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 1])[0]
rMAX  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 2])[0]

merge=np.c_[N,oob_r2,oob_mse,r2,mse,rMEAN,rMIN,rMAX]
print(merge)
savetxt( rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YscoreN{N_EST_S}_{obs_s}obs_2RF.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train_selected.columns)
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YimportanceN{N_EST_S}_{obs_s}obs_2RF.txt' , index=True , sep=' ' , header=False)

EOF
