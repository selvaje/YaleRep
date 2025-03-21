#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 18  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptim.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh.%A_%a.err
#SBATCH --job-name=sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh
#SBATCH --array=300
#SBATCH --mem=300G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G

#### for obs_leaf in 2 4 5 8 10 12 ; do for obs_split in 2 4 5 8 10 12 ; do for sample in  0.4 0.5 0.55 0.6 0.65 0.7 0.75 0.8 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh ; done  ; done ; done 

#### for obs_leaf in 2 4 5 8 10 12   ; do for obs_split in 2 4 5 8 10 12 ; do for sample in  0.3 0.4 0.5 0.6 0.7 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc30_modeling_pythonALL_RFrunMainRespRenk.sh | awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }' ) /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFrunMainRespRenkOptim.sh ; done  ; done ; done 
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
echo obs_leaf  $obs_leaf
echo obs_split  $obs_split
echo sample $sample
export N_EST=$SLURM_ARRAY_TASK_ID
# export N_EST=100
echo   "n_estimators"  $N_EST

module load miniconda/23.5.2
# conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsim2  python=3  numpy scipy pandas matplotlib  scikit-learn
# conda search pandas 
source activate env_gsi_ts
echo $CONDA_DEFAULT_ENV
echo "start python modeling" #### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

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

obs_leaf_s=(os.environ["obs_leaf"])
obs_leaf_i=int(os.environ["obs_leaf"])

obs_split_s=(os.environ["obs_split"])
obs_split_i=int(os.environ["obs_split"])

sample_f=float(os.environ["sample"])
sample_s=str(int(sample_f*100))

print(obs_leaf_s)

N_EST_I=int(os.environ["N_EST"])
N_EST_S=(os.environ["N_EST"])
print(N_EST_S)

X  = pd.read_csv('./stationID_x_y_valueALL_predictors_X.txt', header=0, sep=' ')
Y  = pd.read_csv('./stationID_x_y_valueALL_predictors_Y.txt', header=0, sep=' ')

X_selected_var  = pd.read_csv('stationID_x_y_valueALL_predictors_XimportanceN300_4obs.txt', header=None , sep=' ')

#### base on score value 
X_selected_var = X_selected_var.loc[(X_selected_var[1] > 0.005)][0]
#### base on score index e.g. 50 
#### X_selected_var = X_selected_var.head(50)[0]
 
X = X.loc[:,X_selected_var]    ### at this point the X is already reduced 

print(Y.shape)
print(X.shape)

X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)

savetxt(rf'stationID_x_y_valueALL_predictors_XcolnamesN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt',  X_column_names , fmt='%s')
savetxt(rf'stationID_x_y_valueALL_predictors_Xselected_pyN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X,  delimiter=' ', header=X_column_names_str , comments="")  

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2 ,  random_state=24)
fmt = '%i %i %i %f %f %f %f %f %f %f %f %f %f %f %f %f'

savetxt(rf'./stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt=fmt, header="ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")
savetxt(rf'./stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt=fmt, header="ID YYYY MM lon lat QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")

X_column_names_str = ' '.join(X_column_names)
savetxt(rf'./stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X_train,  delimiter=' ', header=X_column_names_str , comments="")  
savetxt(rf'./stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , X_test ,  delimiter=' ', header=X_column_names_str , comments="") 

print("Run RF on the training ") 
RFreg = RandomForestRegressor(random_state=24, n_estimators=N_EST_I, n_jobs=18, max_samples=sample_f, oob_score=True, bootstrap=True, min_samples_leaf=obs_leaf_i, min_samples_split=obs_split_i)

RFreg.fit(X_train, Y_train.iloc[:,5:16])  

#### make prediction using the oob
savetxt(rf'./stationID_x_y_valueALL_predictors_YOOBpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', RFreg.oob_prediction_, delimiter=' ', fmt='%f', header="QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")
savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', RFreg.predict(X_train), delimiter=' ', fmt='%f', header="QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")

print("OOB score" ,  RFreg.oob_score_)
print("Score" ,  RFreg.score)

train_r2 = RFreg.score(X_train, Y_train.iloc[:,5:16])
train_oob_r2 = np.array([RFreg.oob_score_])
test_r2 = RFreg.score(X_test, Y_test.iloc[:,5:16])

Y_test_pred = RFreg.predict(X_test)
savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_test_pred , delimiter=' ', fmt='%f', header="QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX", comments="")
train_mse = mean_squared_error(Y_train.iloc[:,5:16], RFreg.predict(X_train))
train_oob_mse = mean_squared_error(Y_train.iloc[:,5:16], RFreg.oob_prediction_)
test_mse = mean_squared_error(Y_test.iloc[:,5:16], Y_test_pred)

train_rQMIN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 5])[0]
train_rQ10  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 6])[0]
train_rQ20  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 7])[0]
train_rQ30  = stats.pearsonr(RFreg.oob_prediction_[:,3],Y_train.iloc[:, 8])[0]  
train_rQ40  = stats.pearsonr(RFreg.oob_prediction_[:,4],Y_train.iloc[:, 9])[0] 
train_rQ50  = stats.pearsonr(RFreg.oob_prediction_[:,5],Y_train.iloc[:, 10])[0]
train_rQ60  = stats.pearsonr(RFreg.oob_prediction_[:,6],Y_train.iloc[:, 11])[0]
train_rQ70  = stats.pearsonr(RFreg.oob_prediction_[:,7],Y_train.iloc[:, 12])[0]
train_rQ80  = stats.pearsonr(RFreg.oob_prediction_[:,8],Y_train.iloc[:, 13])[0]
train_rQ90  = stats.pearsonr(RFreg.oob_prediction_[:,9],Y_train.iloc[:, 14])[0]
train_rQMAX = stats.pearsonr(RFreg.oob_prediction_[:,10],Y_train.iloc[:, 15])[0]

test_rQMIN = stats.pearsonr(Y_test_pred[:,0],Y_test.iloc[:, 5])[0]                
test_rQ10  = stats.pearsonr(Y_test_pred[:,1],Y_test.iloc[:, 6])[0]    
test_rQ20  = stats.pearsonr(Y_test_pred[:,2],Y_test.iloc[:, 7])[0]    
test_rQ30  = stats.pearsonr(Y_test_pred[:,3],Y_test.iloc[:, 8])[0]        
test_rQ40  = stats.pearsonr(Y_test_pred[:,4],Y_test.iloc[:, 9])[0]
test_rQ50  = stats.pearsonr(Y_test_pred[:,5],Y_test.iloc[:, 10])[0]     
test_rQ60  = stats.pearsonr(Y_test_pred[:,6],Y_test.iloc[:, 11])[0]    
test_rQ70  = stats.pearsonr(Y_test_pred[:,7],Y_test.iloc[:, 12])[0]          
test_rQ80  = stats.pearsonr(Y_test_pred[:,8],Y_test.iloc[:, 13])[0]                  
test_rQ90  = stats.pearsonr(Y_test_pred[:,9],Y_test.iloc[:, 14])[0]                                  
test_rQMAX = stats.pearsonr(Y_test_pred[:,10],Y_test.iloc[:, 15])[0]         

n=np.array(N_EST_I)
leaf=np.array(obs_leaf_i)
split=np.array(obs_split_i)
sample=np.array(sample_f)

merge=np.c_[n,leaf,split,sample,train_r2,train_oob_r2,test_r2,train_mse,train_oob_mse,test_mse,train_rQMIN,train_rQ10,train_rQ20,train_rQ30,train_rQ40,train_rQ50,train_rQ60,train_rQ70,train_rQ80,train_rQ90,train_rQMAX,test_rQMIN,test_rQ10,test_rQ20,test_rQ30,test_rQ40,test_rQ50,test_rQ60,test_rQ70,test_rQ80,test_rQ90,test_rQMAX]

print(merge)
savetxt( rf'./stationID_x_y_valueALL_predictors_YscoreN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_test.columns)
importance.sort_values(ascending=False,inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , index=True , sep=' ' , header=False)

# for the intire session 
# with open(rf'./stationID_x_y_valueALL_predictors_YmodelN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.pkl' , 'w+b') as f:
#    dill.dump_session(f)

# Save the file
dill.dump(RFreg, file = open(f'./stationID_x_y_valueALL_predictors_YmodelN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.pkl', 'wb'))

EOF

exit   
