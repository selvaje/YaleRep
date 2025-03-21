#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 20  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RFoptim.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFoptim.sh.%J.err
#SBATCH --job-name=sc31_modeling_pythonALL_RFoptim.sh
#SBATCH --mem=150G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc31_modeling_pythonALL_RFoptim.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract4mod
cd $EXTRACT

module load StdEnv miniconda/23.5.2
source activate env_gsim2
echo "start python modeling"
export SAMPLE=100000

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
                                                                                                    
X_train = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_train.txt', sep=' ' , header=0).astype(float)
X_test  = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_test.txt' , sep=' ' , header=0).astype(float)

Y_train = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_train.txt', sep=' ' , header=0).astype(float)
Y_test  = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_test.txt' , sep=' ' , header=0).astype(float)

Y_header = np.array(Y_train.columns)

print(Y_header)

print(X_train.head(10))
print(Y_train.head(10))

print(X_test.head(10))
print(Y_test.head(10))

print(X_train.shape)
print(Y_train.shape)

print(X_test.shape)
print(Y_test.shape)

# Y_train=np.ravel(Y_train)

print("select most important predictors")

print("perform the rf tonning")

RFreg = RandomForestRegressor(random_state=24 , min_samples_leaf=6 , n_jobs=20 ,  oob_score=True  )
multi_output_regressor = MultiOutputRegressor(RFreg)

# parameters = {
#         'estimator__max_features':(2,3),
#         'estimator__max_samples':(0.4,0.5),
#         'estimator__n_estimators':(100,200),
#         'estimator__max_depth':(20,50)}

parameters = {
         'estimator__max_features':(2,3,4,5),
         'estimator__max_samples':(0.4,0.5,0.6,0.7),
         'estimator__n_estimators':(100,200,500,750,1000),
         'estimator__max_depth':(20,50,100,200,300,500)}


def custom_scorer(Y_train, Y_test_predict):
    mse = mean_squared_error(y_true, y_pred, multioutput="raw_values")
    return -mse                       # Negate the MSE to maximize the score
# optimiz_search = HalvingGridSearchCV(multi_output_regressor, param_distributions=parameters, cv=5, factor=3, n_jobs=20 , scoring='neg_mean_squared_error' , error_score='raise' )
optimiz_search = HalvingGridSearchCV(multi_output_regressor, param_grid=parameters, cv=5, factor=3, n_jobs=20 , scoring='neg_mean_squared_error' , error_score='raise' )

print(optimiz_search)

optimiz_search.fit(X_train, Y_train)

print ("Best parameters")
best_params = optimiz_search.best_params_
print (best_params)

print ("Best score")
best_score  = optimiz_search.best_score_
print (best_score)

del RFreg
RFreg = RandomForestRegressor( n_estimators=list(best_params.values())[0],
                               max_samples=list(best_params.values())[1],
                               max_features=list(best_params.values())[2],
                               max_depth=list(best_params.values())[3], 
			       random_state=24 , n_jobs=20 ,  oob_score=True )

RFreg.fit(X_train, Y_train)

print(RFreg.oob_score_)

Y_train_predict = RFreg.predict(X_train)
Y_test_predict =  RFreg.predict(X_test)

# Y_train_predict = Y_train_predict.DataFrame(A, index=False , columns=Y_header) 
# Y_test_predict = Y_test_predict.DataFrame(A, index=False   , columns=Y_header) 

print(type(Y_train_predict))
print(type(Y_test_predict))
print(Y_train_predict.shape)
print(Y_test_predict.shape)

Y_train_predict  = pd.DataFrame(Y_train_predict, columns=Y_header)
Y_test_predict  = pd.DataFrame(Y_test_predict, columns=Y_header)

Y_train_predict.to_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_train_predict.txt', sep=' ', index=False , header=True )
Y_test_predict.to_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_test_predict.txt' , sep=' ', index=False , header=True )

# Save the entire workspace to a file
with open(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_workspace.pkl', 'wb') as f: 
    dill.dump_session(f)

EOF

cp ./stationID_x_y_valueALL_predictors_randY{SAMPLE}_workspace.pkl ./stationID_x_y_valueALL_predictors_randY{SAMPLE}_workspace_bk.pkl
