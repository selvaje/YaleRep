#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 48  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFvarsel.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFvarsel.sh.%J.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFvarsel.sh
#SBATCH --mem=320G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling_pythonALL_RFvarsel.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv

# geom   103 # remove only geom
# order_hack    
# order_horton
# order_shreve
# order_strahler
# order_topo 

export SAMPLE=1000000  # > 0 row   9 588 312
echo "sampling"
echo $SAMPLE
awk '{if (NR==1 && $5>=0) print $103="", $0}' $EXTRACT/stationID_x_y_valueALL_predictors.txt | sed  's/-/_/g' | sed -e's/  */ /g' | sed 's/^ *//g' > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt
shuf -n $SAMPLE <(awk '{ gsub("NA","-1"); if (NR> 1 && $5>=0) print $103="",$0}' $EXTRACT/stationID_x_y_valueALL_predictors.txt ) | sed 's/^ *//g' > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt

awk '{print $5,$6,$7,$8,$9,$10,$11,$12 } ' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt   > $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randY$SAMPLE.txt
awk '{print $5,$6,$7,$8,$9,$10,$11,$12 } ' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randY$SAMPLE.txt

awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_header$SAMPLE.txt | sed -e's/  */ /g' | sed 's/^ *//g' >  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt
awk '{ print $1="",$2="",$3="",$4="",$5="",$6="",$7="",$8="",$9="",$10="",$11="",$12="",$0}' $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_rand$SAMPLE.txt   | sed -e's/  */ /g' | sed 's/^ *//g' >>  $EXTRACT/../extract4mod/stationID_x_y_valueALL_predictors_randX$SAMPLE.txt  



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

X = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}.txt', header=0, sep=' ')
Y = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}.txt', header=0, sep=' ')
print(X.head(10))
print(Y.head(10))

X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.5 ,  random_state=24)
del X
del Y

print(X_train.shape)
print(Y_train.shape)

print(X_test.shape)
print(Y_test.shape)

Y_train.to_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_train.txt', index=False , sep=' ' , header=True)
Y_test.to_csv(rf'./stationID_x_y_valueALL_predictors_randY{SAMPLE}_test.txt' , index=False , sep=' ' , header=True)

del Y_test

print("select most important predictors")
 
RFreg = RandomForestRegressor(random_state=24 , n_jobs=36 , oob_score=True , min_samples_leaf=10 , min_samples_split=10)

selected_var = [] 

for k in range(7):
    selected_RFECV_tmp   = RFECV( RFreg, min_features_to_select=10, cv=5, step=1,  n_jobs=36, scoring='neg_mean_squared_error')
    selected_RFECV_tmp.fit(X_train, Y_train.iloc[:,k])
    print(selected_RFECV_tmp.oob_score_)
    sel_tmp = np.array(np.array(X_train.columns))[selected_RFECV_tmp.support_]
    selected_var.extend(sel_tmp)
    del selected_RFECV_tmp
    del sel_tmp

# Print the list
print(selected_var)

selected_var_unique = np.unique(selected_var)
print(selected_var_unique)
print(len(selected_var_unique))

X_train_selected = X_train.loc[:,selected_var_unique]
X_test_selected = X_test.loc[:,selected_var_unique]

print(X_train_selected.head(10))
print(X_test_selected.head(10))

X_train_selected.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_train.txt', index=False , sep=' ' , header=True)
X_test_selected.to_csv(rf'./stationID_x_y_valueALL_predictors_randX{SAMPLE}_test.txt' , index=False , sep=' ' , header=True)



EOF


exit 


large dataset
https://stats.stackexchange.com/questions/487173/fitting-a-random-forest-classifier-on-a-large-dataset
https://stackoverflow.com/questions/68668460/how-to-train-random-forest-on-large-datasets-in-python


merge rf trees  https://stackoverflow.com/questions/28489667/combining-random-forest-models-in-scikit-learn



create by https://www.perplexity.ai/ 

python
from sklearn.datasets import make_regression
from sklearn.linear_model import LinearRegression
from sklearn.metrics import make_scorer, mean_absolute_error
from sklearn.model_selection import cross_val_score

# Generate a non-normally distributed dataset
X, y = make_regression(n_samples=100, n_features=1, noise=10, random_state=0)

# Create a custom scoring function
def custom_scorer(y_true, y_pred):
    # Calculate the mean absolute error
    mae = mean_absolute_error(y_true, y_pred)
    # Apply a transformation to the error, e.g., taking the square root
    transformed_error = np.sqrt(mae)
    return -transformed_error  # Return the negative error for minimization

# Create a linear regression model
model = LinearRegression()

# Evaluate the model using cross-validation with the custom scoring function
scores = cross_val_score(model, X, y, scoring=make_scorer(custom_scorer), cv=5)
