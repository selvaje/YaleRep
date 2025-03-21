#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFrunMainRespRenk.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFrunMainRespRenk.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFrunMainRespRenk.sh
#SBATCH --array=300
#SBATCH --mem=400G

##### #SBATCH --array=200,400,500,600
#### for obs in 2 4 5 8 10 15  ; do sbatch --export=obs=$obs   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc30_modeling_pythonALL_RFrunMainRespRenk.sh ; done 
#### 2 4 5 8 10 15 

### RAM error a 400G n_estimators300obs15 n_estimators400obs5  n_estimators300obs10 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract
EXTRACTpy=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv


export obs=$obs 
export N_EST=$SLURM_ARRAY_TASK_ID
#### export obs=50
#### export N_EST=100
echo   "n_estimators"  $N_EST   "obs" $obs
~/bin/echoerr   n_estimators${N_EST}obs${obs}


# awk '{ if (NR> 1) print }' $EXTRACT/stationID_x_y_valueALL_predictors.txt  | shuf -n $SAMPLE  > $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}_tmp.txt
# head -1  $EXTRACT/stationID_x_y_valueALL_predictors.txt               > $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}.txt
# cat $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}_tmp.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}.txt
# rm $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}_tmp.txt

# cut -d " " -f6-16   $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_randY.txt
# cut -d " " -f17-    $EXTRACTpy/stationID_x_y_valueALL_predictors_rand${SAMPLE}.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_randX.txt 

### full dataset 
##  cut -d " " -f1-16       $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt
##  cut -d " " -f1-5,17-    $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt 

#### check importing of $EXTRACTpy/stationID_x_y_valueALL_predictors_randY.txt  .. 

module load miniconda/23.5.2

source activate env_gsi_ts
echo $CONDA_DEFAULT_ENV

echo "start python modeling"

#### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

cd $EXTRACTpy
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

obs_s=(os.environ["obs"])
print(obs_s)

obs_i=int(os.environ["obs"])

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_X.txt', header=0, sep=' ', usecols=lambda column: column not in ["ID","YYYY","MM","lon","lat"])
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_Y.txt', header=0, sep=' ', usecols=lambda column: column not in ["ID","YYYY","MM","lon","lat"])

print(X_train.shape)
print(Y_train.shape)

print("Run RF with - no testing ")
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=16 , oob_score=True ,  bootstrap=True ,   min_samples_leaf=obs_i , min_samples_split=obs_i)
RFreg.fit(X_train, Y_train)

#### make prediction using th oob
savetxt(rf'./stationID_x_y_valueALL_predictors_YOOBpredictN{N_EST_S}_{obs_s}obs.txt', RFreg.oob_prediction_, delimiter=' ', fmt='%f', header="QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")

savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictN{N_EST_S}_{obs_s}obs.txt', RFreg.predict(X_train), delimiter=' ', fmt='%f', header="QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")

print("OOB score" ,  RFreg.oob_score_) 
print("Score" ,  RFreg.score)

oob_r2 = np.array([RFreg.oob_score_])
r2 = RFreg.score(X_train, Y_train)

n=np.array(N_EST_I)
o=np.array(obs_i)

oob_mse = mean_squared_error(Y_train, RFreg.oob_prediction_)
mse = mean_squared_error(Y_train, RFreg.predict(X_train))

rQMIN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 0])[0]
rQ10  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 1])[0]
rQ20  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 2])[0]
rQ30  = stats.pearsonr(RFreg.oob_prediction_[:,3],Y_train.iloc[:, 3])[0]  
rQ40  = stats.pearsonr(RFreg.oob_prediction_[:,4],Y_train.iloc[:, 4])[0] 
rQ50  = stats.pearsonr(RFreg.oob_prediction_[:,5],Y_train.iloc[:, 5])[0]
rQ60  = stats.pearsonr(RFreg.oob_prediction_[:,6],Y_train.iloc[:, 6])[0]
rQ70  = stats.pearsonr(RFreg.oob_prediction_[:,7],Y_train.iloc[:, 7])[0]
rQ80  = stats.pearsonr(RFreg.oob_prediction_[:,8],Y_train.iloc[:, 8])[0]
rQ90  = stats.pearsonr(RFreg.oob_prediction_[:,9],Y_train.iloc[:, 9])[0]
rQMAX = stats.pearsonr(RFreg.oob_prediction_[:,10],Y_train.iloc[:, 10])[0]

merge=np.c_[n,o,r2,oob_r2,mse,oob_mse,rQMIN,rQ10,rQ20,rQ30,rQ40,rQ50,rQ60,rQ70,rQ80,rQ90,rQMAX]

print(merge)
savetxt( rf'./stationID_x_y_valueALL_predictors_YscoreN{N_EST_S}_{obs_s}obs.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train.columns)
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_s}obs.txt' , index=True , sep=' ' , header=False)

EOF
