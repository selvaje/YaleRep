#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 24  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptim_samp.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptim_samp.sh.%A_%a.err
#SBATCH --job-name=sc31_modeling_pythonALL_RFrunMainRespRenkOptim_1sample.sh
#SBATCH --array=300
#SBATCH --mem=250G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G
#### for obs_leaf in 2 4 5 8 10 12   ; do for obs_split in 2 4 5 8 10 12 ; do for sample in  0.3 0.4 0.5 0.6 0.7 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc30_modeling_pythonALL_RFrunMainRespRenk.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }' ) /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh ; done  ; done ; done 
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# export obs=50
export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
echo obs_leaf  $obs_leaf
echo obs_split  $obs_split
echo sample $sample
export SAMPLE=9583643   # >= 0 all response rows   9584655 
echo "sampling" $SAMPLE
export N_EST=$SLURM_ARRAY_TASK_ID
# export N_EST=100
echo   "n_estimators"  $N_EST

module load miniconda/23.5.2
# conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsim2  python=3  numpy scipy pandas matplotlib  scikit-learn
# conda search pandas 
source activate env_gsi_ts
echo $CONDA_DEFAULT_ENV

echo "start python modeling" #### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

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
import dill 

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)

obs_leaf_s=(os.environ["obs_leaf"])
obs_leaf_i=int(os.environ["obs_leaf"])

obs_split_s=(os.environ["obs_split"])
obs_split_i=int(os.environ["obs_split"])

sample_f=float(os.environ["sample"])
sample_s=str(int(sample_f*10))

print(obs_leaf_s)

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randS3Y{SAMPLE}.txt', header=0, sep=' ')

X_selected_var  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YimportanceN200_2obs.txt', header=None , sep=' ')

#### base on score value 
X_selected_var = X_selected_var.loc[(X_selected_var[1] > 0.01)][0]
#### base on score index e.g. 50 
#### X_selected_var = X_selected_var.head(50)[0]
 
X = X.loc[:,X_selected_var]    ### at this point the X is already reduced 

print(Y.shape)
print(X.shape)

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2 ,  random_state=24)

# savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")
# savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")

print("Run RF on the training ") 
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=24 , max_samples=sample_f , oob_score=True , bootstrap=True , min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i) 

RFreg.fit(X_train, Y_train)

#### make prediction using th oob
# savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', RFreg.oob_prediction_, delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")

print("OOB score" ,  RFreg.oob_score_)
print("Score" ,  RFreg.score)

train_r2 = RFreg.score(X_train, Y_train)
train_oob_r2 = np.array([RFreg.oob_score_])
test_r2 = RFreg.score(X_test, Y_test)

Y_test_pred = RFreg.predict(X_test)
savetxt(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_test_pred , delimiter=' ', fmt='%f', header="MEAN MIN MAX", comments="")
train_mse = mean_squared_error(Y_train, RFreg.predict(X_train))
train_oob_mse = mean_squared_error(Y_train, RFreg.oob_prediction_)
test_mse = mean_squared_error(Y_test, Y_test_pred)

train_rMEAN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 0])[0]
train_rMIN  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 1])[0]
train_rMAX  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 2])[0]

test_rMEAN = stats.pearsonr(Y_test_pred[:,0],Y_test.iloc[:, 0])[0]    
test_rMIN  = stats.pearsonr(Y_test_pred[:,1],Y_test.iloc[:, 1])[0]  
test_rMAX  = stats.pearsonr(Y_test_pred[:,2],Y_test.iloc[:, 2])[0]     

n=np.array(N_EST_I)
leaf=np.array(obs_leaf_i)
split=np.array(obs_split_i)
sample=np.array(sample_f)

merge=np.c_[n,leaf,split,sample,train_r2,train_oob_r2,test_r2,train_mse,train_oob_mse,test_mse,train_rMEAN,train_rMIN,train_rMAX,test_rMEAN,test_rMIN,test_rMAX]
print(merge)
savetxt( rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YscoreN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train.columns)
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , index=True , sep=' ' , header=False)

with open(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_S3YmodelN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.pkl' , 'w+b') as f:
     dill.dump_session(f)

EOF
