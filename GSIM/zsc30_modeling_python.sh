#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 5 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-python.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_python.sh.%J.err
#SBATCH --job-name=sc30_modeling_python.sh
#SBATCH --mem=80G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling_python.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# geom   96  # remove only geom
# order_hack    
# order_horton
# order_shreve
# order_strahler
# order_topo 

awk '{ if (NR==1 && $5>=0) print $91="", $0}'    stationID_x_y_value_predictors.txt | sed  's/-/_/g' | sed -e's/  */ /g' | sed 's/^ *//g' > stationID_x_y_value_predictors_header.txt
shuf -n 10000  <( awk '{ if (NR> 1 && $5>=0) print $91="" ,    $0} '  stationID_x_y_value_predictors.txt ) | sed 's/^ *//g'  > stationID_x_y_value_predictors_rand.txt

awk '{print $5 } ' stationID_x_y_value_predictors_header.txt   > stationID_x_y_value_predictors_randY.txt
awk '{print $5 } ' stationID_x_y_value_predictors_rand.txt   >> stationID_x_y_value_predictors_randY.txt

awk '{ print $1="", $2="", $3="", $4="", $5="", $0}' stationID_x_y_value_predictors_header.txt  | sed -e's/  */ /g' | sed 's/^ *//g'  >  stationID_x_y_value_predictors_randX.txt  
awk '{ print $1="", $2="", $3="", $4="", $5="", $0}' stationID_x_y_value_predictors_rand.txt    | sed -e's/  */ /g' | sed 's/^ *//g' >>  stationID_x_y_value_predictors_randX.txt  


module load miniconda/23.5.2
# conda create --force  --prefix=/gpfs/gibbs/project/sbsc/ga254/conda_envs/env_gsim2  python=3  numpy scipy pandas matplotlib  scikit-learn
# conda search pandas 
source activate env_gsim2
echo $CONDA_DEFAULT_ENV

echo "start python modeling"

#### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

python3 <<'EOF'
import os, sys 
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split,GridSearchCV
from sklearn.feature_selection import RFECV
from sklearn.feature_selection import RFE
from sklearn.pipeline import Pipeline
from scipy import stats
from scipy.stats import pearsonr
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

X = pd.read_csv('./stationID_x_y_value_predictors_randX.txt', header=0, sep=' ')
Y = pd.read_csv('./stationID_x_y_value_predictors_randY.txt', header=0, sep=' ')
print(X.head(10))
print(Y.head(10))

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.5 ,  random_state=0)
print(X_train.shape)
print(Y_train.shape)

print(X_test.shape)
print(Y_test.shape)

Y_train=np.ravel(Y_train)

print("select most important predictors")
 
RFreg = RandomForestRegressor(random_state=24 )
selected_RFE = RFECV( RFreg, min_features_to_select=20, cv=5, step=4,  n_jobs=5, verbose=1, scoring='neg_mean_squared_error')
selected_RFE.fit(X_train, Y_train)

# list the predictors and count them 
print(np.array(np.array(X_train.columns))[selected_RFE.support_])

print(selected_RFE.n_features_)

print ("re-build the X_train and X_test base on the selected variables")
X_train_selected = selected_RFE.transform(X_train)
X_test_selected  = selected_RFE.transform(X_test)

print("perform the rf tonning")
RFreg = RandomForestRegressor(random_state=24)
pipeline = Pipeline([('rf',RFreg)])

parameters = {
        'rf__max_features':(2,3,4,5),
        'rf__max_samples':(0.4,0.5,0.6,0.7),
        'rf__n_estimators':(100,200),
        'rf__max_depth':(20,50,100,200,300,500)}

grid_search = GridSearchCV(pipeline,parameters,n_jobs=5,cv=5, scoring='neg_mean_squared_error', verbose=1) 
grid_search.fit(X_train_selected,Y_train)

print(grid_search.best_params_)
print(grid_search.best_score_)

print("perform rf prediction using the GridSearchCV resoltus")
dic_pred = {}
dic_pred['train'] = grid_search.predict(X_train_selected)
dic_pred['test']  = grid_search.predict(X_test_selected)
pearsonr_all      = [pearsonr(dic_pred['train'],Y_train)[0],pearsonr(dic_pred['test'],np.ravel(Y_test))[0]]
print(pearsonr_all)



EOF
