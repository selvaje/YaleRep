#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFrunMainRespRenk.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFrunMainRespRenk.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFrunMainRespRenk.sh
#SBATCH --array=200
#SBATCH --mem=350G

##### #SBATCH --array=200,400,500,600
#### for obs in 2 4 5 8 10 15  ; do sbatch --export=obs=$obs   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling_pythonALL_RFrunMainRespRenk.sh ; done 
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

export SAMPLE=9583643  # >= 0 all response rows   9584655 
echo "sampling" $SAMPLE

export N_EST=$SLURM_ARRAY_TASK_ID
# export N_EST=100
echo   "n_estimators"  $N_EST

#  awk '{if (NR==1) print $103="", $0}' $EXTRACT/stationID_x_y_valueALL_predictors.txt | sed  's/-/_/g' | sed -e's/  */ /g' | sed 's/^ *//g' > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt

#  awk '{ if (NR> 1 && $5>=0 && $6>=0 && $7>=0 && $8>=0 && $9>=0 && $10>=0 && $11>=0 && $12>=0) {print $103="",$0}}' $EXTRACT/stationID_x_y_valueALL_predictors.txt | grep -v "1e+05" | sed 's/^ *//g'  > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt

#  shuf -n $SAMPLE $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand${SAMPLE}_tmp.txt
#  mv $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand${SAMPLE}_tmp.txt $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand${SAMPLE}.txt

#  awk '{print $5,$9,$10 }' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt   > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randS3Y$SAMPLE.txt
#  awk '{print $5,$9,$10 }' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randS3Y$SAMPLE.txt

#  awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt | sed -e's/  */ /g' | sed 's/^ *//g' >   $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt
#  awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   | sed -e's/  */ /g' | sed 's/^ *//g' >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt  


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

print(X_train.shape)
print(Y_train.shape)

print("Run RF with - no testing ")
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=16 , oob_score=True ,  bootstrap=True ,   min_samples_leaf=obs_i , min_samples_split=obs_i)
RFreg.fit(X_train, Y_train)

#### make prediction using th oob
savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YpredictN{N_EST_S}_{obs_s}obs.txt', RFreg.oob_prediction_, delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")

print("OOB score" ,  RFreg.oob_score_) 
print("Score" ,  RFreg.score)

oob_r2 = np.array([RFreg.oob_score_])
r2 = RFreg.score(X_train, Y_train)

n=np.array(N_EST_I)
o=np.array(obs_i)

oob_mse = mean_squared_error(Y_train, RFreg.oob_prediction_)
mse = mean_squared_error(Y_train, RFreg.predict(X_train))

rMEAN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 0])[0]
rMIN  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 1])[0]
rMAX  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 2])[0]

merge=np.c_[n,o,r2,oob_r2,mse,oob_mse,rMEAN,rMIN,rMAX]
print(merge)
savetxt( rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YscoreN{N_EST_S}_{obs_s}obs.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train.columns)
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YimportanceN{N_EST_S}_{obs_s}obs.txt' , index=True , sep=' ' , header=False)

EOF
