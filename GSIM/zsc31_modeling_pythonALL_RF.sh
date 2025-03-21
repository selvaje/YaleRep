#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 5 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RF.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RF.sh.%J.err
#SBATCH --job-name=sc31_modeling_pythonALL_RF.sh
#SBATCH --mem=80G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc31_modeling_pythonALL_RF.sh

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

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)
                                                                                                    
X_train = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_train.txt', sep=' ' , header=0).astype(float)
X_test  = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_test.txt' , sep=' ' , header=0).astype(float)

Y_train = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_train.txt', sep=' ' , header=0).astype(float)
Y_test  = pd.read_csv (rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_test.txt' , sep=' ' , header=0).astype(float)

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

RFreg = RandomForestRegressor(random_state=24 , min_samples_leaf=6 , n_jobs=10  )
multi_output_regressor = MultiOutputRegressor(RFreg)

parameters = {
        'estimator__max_features':(2,3),
        'estimator__max_samples':(0.4,0.7),
        'estimator__n_estimators':(100,200),
        'estimator__max_depth':(20,50)}

# parameters = {
#         'estimator__max_features':(2,3,4,5),
#         'estimator__max_samples':(0.4,0.5,0.6,0.7),
#         'estimator__n_estimators':(100,200),
#         'estimator__max_depth':(20,50,100,200,300,500)}


def custom_scorer(y_true, y_pred):
    mse = mean_squared_error(y_true, y_pred, multioutput="raw_values")
    return -mse                       # Negate the MSE to maximize the score

optimiz_search = HalvingRandomSearchCV(multi_output_regressor, param_distributions=parameters, cv=5, factor=3, n_jobs=10 , scoring='neg_mean_squared_error')

print(optimiz_search)

optimiz_search.fit(X_train, Y_train)

print(optimiz_search.best_params_)
print(optimiz_search.best_score_)

best_params = optimiz_search.best_params_
best_score  = optimiz_search.best_score_

print ("Best parameters")
print (best_params)

optimiz_search.fit(X_train, Y_train)

optimiz_search.predict(X_train)
optimiz_search.predict(X_test)


# print("perform rf prediction using the optimization  resoltus")
# dic_pred = {}
# dic_pred['train'] = Ytrain_predict
# dic_pred['test']  = Ytest_predict
# pearsonr_all      = [pearsonr(dic_pred['train'],Y_train)[0],pearsonr(dic_pred['test'],np.ravel(Y_test))[0]]
# print(pearsonr_all)

EOF
