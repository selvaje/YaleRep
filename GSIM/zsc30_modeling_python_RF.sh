#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-python.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_python.sh.%J.err
#SBATCH --job-name=sc30_modeling_python.sh
#SBATCH --mem=200G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling_python_RF.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# geom   96  # remove only geom
# order_hack    
# order_horton
# order_shreve
# order_strahler
# order_topo 

export SAMPLE=9588312     # > 0 row   9588312 
awk '{ if (NR==1 && $5>=0) print $96="", $0}'    stationID_x_y_value_predictors.txt | sed  's/-/_/g' | sed -e's/  */ /g' | sed 's/^ *//g' > stationID_x_y_value_predictors_header$SAMPLE.txt
shuf -n $SAMPLE  <( awk '{ if (NR> 1 && $5>=0) print $91="" ,    $0} '  stationID_x_y_value_predictors.txt ) | sed 's/^ *//g'  > stationID_x_y_value_predictors_rand$SAMPLE.txt

awk '{print $5 } ' stationID_x_y_value_predictors_header$SAMPLE.txt   > stationID_x_y_value_predictors_randY$SAMPLE.txt
awk '{print $5 } ' stationID_x_y_value_predictors_rand$SAMPLE.txt   >> stationID_x_y_value_predictors_randY$SAMPLE.txt

awk '{ print $1="", $2="", $3="", $4="", $5="", $0}' stationID_x_y_value_predictors_header$SAMPLE.txt | sed -e's/  */ /g' | sed 's/^ *//g' >  stationID_x_y_value_predictors_randX$SAMPLE.txt  
awk '{ print $1="", $2="", $3="", $4="", $5="", $0}' stationID_x_y_value_predictors_rand$SAMPLE.txt   | sed -e's/  */ /g' | sed 's/^ *//g' >>  stationID_x_y_value_predictors_randX$SAMPLE.txt  


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
from sklearn import metrics
from scipy import stats
from scipy.stats import pearsonr
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

SAMPLE=(os.environ["SAMPLE"])
print(SAMPLE)

X = pd.read_csv(rf'./stationID_x_y_value_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y = pd.read_csv(rf'./stationID_x_y_value_predictors_randY{SAMPLE}.txt', header=0, sep=' ')
print(X.head(10))
print(Y.head(10))

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.5 ,  random_state=0)
print(X_train.shape)
print(Y_train.shape)

print(X_test.shape)
print(Y_test.shape)

Y_train=np.ravel(Y_train)

print("select most important predictors")
 
RFreg = RandomForestRegressor(random_state=24 , n_jobs=20 , oob_score=metrics.mean_squared_error , min_samples_leaf=4 )
selected_RFE = RFECV( RFreg, min_features_to_select=20, cv=10, step=1,  n_jobs=10, verbose=1, scoring='neg_mean_squared_error')
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

RFreg = RandomForestRegressor(random_state=24 , n_jobs=20 , oob_score=metrics.mean_squared_error , min_samples_leaf=4 ) 

RFreg.fit(X_train_selected,Y_train)

print("perform rf prediction using the RF defoult")
dic_pred = {}
dic_pred['train'] = RFreg.predict(X_train_selected)
dic_pred['test']  = RFreg.predict(X_test_selected)
pearsonr_all      = [pearsonr(dic_pred['train'],Y_train)[0],pearsonr(dic_pred['test'],np.ravel(Y_test))[0]]

print("pearsonr train test" , pearsonr_all)
print ("RF score pearsonr train",  np.sqrt(RFreg.score(X_train_selected,Y_train)))

print ("mse cv", RFreg.oob_score_)
print( "mse test" ,  metrics.mean_squared_error(Y_test, RFreg.predict(X_test_selected)))

EOF



exit

large dataset
https://stats.stackexchange.com/questions/487173/fitting-a-random-forest-classifier-on-a-large-dataset
https://stackoverflow.com/questions/68668460/how-to-train-random-forest-on-large-datasets-in-python


merge rf trees  https://stackoverflow.com/questions/28489667/combining-random-forest-models-in-scikit-learn
