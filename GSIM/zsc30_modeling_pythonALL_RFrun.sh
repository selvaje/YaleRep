#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFrun.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFrun.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFrun.sh
#SBATCH --array=100,200,500,800,1000
#SBATCH --mem=100G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling_pythonALL_RFrun.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# geom   103 # remove only geom
# order_hack    
# order_horton
# order_shreve
# order_strahler
# order_topo 

export SAMPLE=9588312  # > 0 row   9 588 312
echo "sampling"
echo $SAMPLE

export N_EST=$SLURM_ARRAY_TASK_ID
echo   "n_estimators"
echo N_EST

# awk '{if (NR==1 && $5>=0) print $103="", $0}' $EXTRACT/stationID_x_y_valueALL_predictors.txt | sed  's/-/_/g' | sed -e's/  */ /g' | sed 's/^ *//g' > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt
# shuf -n $SAMPLE <(awk '{ gsub("NA","-1"); if (NR> 1 && $5>=0) print $103="",$0}' $EXTRACT/stationID_x_y_valueALL_predictors.txt ) | sed 's/^ *//g' > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt

# awk '{print $5,$6,$7,$8,$9,$10,$11,$12 } ' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt   > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randY$SAMPLE.txt
# awk '{print $5,$6,$7,$8,$9,$10,$11,$12 } ' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randY$SAMPLE.txt

# awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt | sed -e's/  */ /g' | sed 's/^ *//g' >  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt
# awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   | sed -e's/  */ /g' | sed 's/^ *//g' >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt  


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
from scipy import stats
from scipy.stats import pearsonr

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}.txt', header=0, sep=' ')

print(X_train.shape)
print(Y_train.shape)

print("Run RF with - no testing ")
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=12 , oob_score=True ,  bootstrap=True ,   min_samples_leaf=50 , min_samples_split=50)
RFreg.fit(X_train, Y_train)

print("OOB score" ,  RFreg.oob_score_) 

oob_score = np.array([RFreg.oob_score_])
N=np.array(N_EST_I)

merge=np.c_[N,oob_score]
print(merge)

savetxt( rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_scoreN{N_EST_S}_50obs.txt' , merge, delimiter=' ')
                                   
# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train.columns)
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_importanceN{N_EST_S}_50obs.txt' , index=True , sep=' ' , header=False)

EOF
