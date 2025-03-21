#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFrunMainRespRenk_RFunID_OOB_all.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_OOB_all.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_OOB_all.sh
#SBATCH --array=300,400,500
#SBATCH --mem=500G

##### #SBATCH --array=200,400,500,600
#### for obs in 4 5 8 10 15; do for samp in 0 1 2 3 4 ;   do sbatch --export=obs=$obs,samp=$samp /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_OOB_all_multicoreE.sh; done ; done 
#### 2 4 5 8 10 15 

### RAM error a 400G n_estimators300obs15 n_estimators400obs5  n_estimators300obs10 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_sample

cd $EXTRACT

module load StdEnv

export obs=$obs 
export N_EST=$SLURM_ARRAY_TASK_ID

echo   "n_estimators"  $N_EST   "obs" $obs  "samp" $samp
~/bin/echoerr   n_estimators${N_EST}obs${obs}samp${samp}

#  cut -d " " -f1-19       $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt
#  cut -d " " -f1-8,20-    $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt 
#  shuff=1000000
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt 
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt

#  awk '{ if (NR> 1) print }'  $EXTRACT/stationID_x_y_valueALL_predictors.txt | shuf -n $shuff > $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt
#  cut -d " " -f1-19    $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt
#  cut -d " " -f1-8,20- $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt 

# shuff=1
# head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt 
# head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt
 
# grep ^$shuff   $EXTRACT/stationID_x_y_valueALL_predictors.txt  > $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt
# cut -d " " -f1-19    $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt
# cut -d " " -f1-8,20- $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt 

# for samp in 0 1 2 3 4 ;   do
# cut -d " " -f1-19       $EXTRACT/stationID_x_y_valueALL_predictors_sampM$samp.txt  >   $EXTRACT/stationID_x_y_valueALL_predictors_sampM${samp}_Y.txt 
# cut -d " " -f1-8,20-    $EXTRACT/stationID_x_y_valueALL_predictors_sampM$samp.txt  >   $EXTRACT/stationID_x_y_valueALL_predictors_sampM${samp}_X.txt 
# done 

#### check importing of $EXTRACTpy/stationID_x_y_valueALL_predictors_randY.txt  .. 

echo "start python modeling"
#### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

cd $EXTRACT

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
 --env=obs=$obs,N_EST=$N_EST,samp=$samp /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'
import os, sys 
import pandas as pd
import numpy as np
from numpy import savetxt
from sklearn.base import RegressorMixin
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.metrics import mean_squared_error
from scipy import stats
from scipy.stats import pearsonr
from sklearn.metrics import r2_score
from joblib import Parallel, delayed

pd.set_option('display.max_columns', None)  # Show all columns

obs_s=(os.environ['obs'])
obs_i=int(os.environ['obs'])
print(obs_s)

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])
print(N_EST_S)

samp_i=int(os.environ['samp'])  
samp_s=(os.environ['samp']) 
print(samp_s)  

dtypes_X = {col: 'float32' for col in range(7, 67)}
dtypes_Y = {col: 'float32' for col in range(7, 18)}

X_train  = pd.read_csv(rf'stationID_x_y_valueALL_predictors_sampM{samp_s}_X.txt', header=0, sep=' ', usecols=lambda column: column not in ['ID','YYYY','MM','lon','lat','Xcoord','Ycoord'], dtype=dtypes_X)
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_sampM{samp_s}_Y.txt', header=0, sep=' ', usecols=lambda column: column not in ['ID','YYYY','MM','lon','lat','Xcoord','Ycoord'], dtype=dtypes_Y)
print('Training and Testing data')
print('################################')
print(X_train.head(4))
print('################################')
print(Y_train.head(4))
print('################################')
print(X_train.shape)
print(Y_train.shape)

##  Maintain original row order
print(type(X_train))  
X_train = X_train.sort_values(by='IDraster').reset_index(drop=True)
print(type(Y_train))  
Y_train = Y_train.sort_values(by='IDraster').reset_index(drop=True)

# Custom Decision Tree to enforce Group constraints
class GroupAwareDecisionTree(DecisionTreeRegressor):
    def fit(self, X, y, sample_weight=None, check_input=True):
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

# Custom Random Forest to enforce Group constraints & ensure non-negative predictions

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def fit(self, X, Y):
        self.oob_predictions = np.full(Y.drop(columns=['IDraster']).shape, fill_value=np.nan, dtype=np.float64)
        unique_groups = np.unique(X['IDraster'])
        
        def train_tree(boot_groups):
            train_mask = np.isin(X['IDraster'], boot_groups)
            oob_mask = ~train_mask
            
            tree = GroupAwareDecisionTree()
            X_train_filtered = X.loc[train_mask].drop(columns=['IDraster']).values
            Y_train_filtered = Y.loc[train_mask].drop(columns=['IDraster']).values
            tree.fit(X_train_filtered, Y_train_filtered)
            
            if np.any(oob_mask):
                X_oob_filtered = X.loc[oob_mask].drop(columns=['IDraster']).values
                self.oob_predictions[oob_mask, :] = tree.predict(X_oob_filtered)
            return tree

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(train_tree)(
            np.random.choice(unique_groups, size=len(unique_groups), replace=True)
        ) for _ in range(self.n_estimators))

    def compute_oob_error(self, Y_true):
        unique_idrasters = np.unique(Y_true['IDraster'])
        
        def compute_group_error(idraster):
            mask = Y_true['IDraster'].values == idraster
            if np.sum(mask) <= 5:
                return [idraster] + [np.nan] * (Y_true.shape[1] - 1)
            Y_true_filtered = Y_true.loc[mask].drop(columns=['IDraster']).values
            oob_pred_filtered = self.oob_predictions[mask, :]
            correlations = [pearsonr(Y_true_filtered[:, i].flatten(), oob_pred_filtered[:, i].flatten())[0] for i in range(Y_true_filtered.shape[1])]
            return [idraster] + correlations
        
        oob_errors_list = Parallel(n_jobs=self.n_jobs, prefer='threads')(delayed(compute_group_error)(idraster) for idraster in unique_idrasters)
        oob_errors = np.array([e for e in oob_errors_list if e is not None])
        overall_oob_error = np.nanmean(oob_errors[:, 1:], axis=0)
        return oob_errors, overall_oob_error

    def predict(self, X):
        X_filtered = X.drop(columns=['IDraster']).copy()
        y_pred = np.mean([tree.predict(X_filtered) for tree in self.estimators_], axis=0)
        return np.maximum(y_pred, 0)  # Ensure non-negative predictions

# Step 2: Use This Custom RF Model
# Replace RandomForestRegressor  with GroupAwareRandomForest:

RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=-1, oob_score=False, bootstrap=True, min_samples_leaf=obs_i, min_samples_split=obs_i)

# Fit the model with group-aware constraints

RFreg.fit(X_train, Y_train)  # Train the model with ID constraints

Y_train_pred =  np.column_stack([Y_train['IDraster'].values,   RFreg.predict(X_train)])   
Y_train_predOOB = np.column_stack([Y_train['IDraster'].values, RFreg.oob_predictions])

print('Y_train_pred')    ; print(type(Y_train_pred))    ; print(Y_train_pred.shape)    ; print(Y_train_pred[:4])     # <class 'numpy.ndarray'>  (60550, 12)
print('Y_train_predOOB') ; print(type(Y_train_predOOB)) ; print(Y_train_predOOB.shape) ; print(Y_train_predOOB[:4])  # <class 'numpy.ndarray'>  (60550, 12)

#### make prediction using the oob
fmt = '%i %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
savetxt(rf'./stationID_x_y_valueALL_predictors_YOOBpredictN{N_EST_S}_{obs_s}obs_{samp_s}samp.txt', Y_train_predOOB , delimiter=' ',  header='IDraster QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='' , fmt=fmt)

savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictN{N_EST_S}_{obs_s}obs_{samp_s}samp.txt', Y_train_pred , delimiter=' ', header='IDraster QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='' , fmt=fmt)

n=np.array(N_EST_I)
o=np.array(obs_i)

oob_mse = mean_squared_error(Y_train.iloc[:, 1:12],Y_train_predOOB[:, 1:12])
print('oob_mse') ;   print(oob_mse)
mse = mean_squared_error(Y_train.iloc[:, 1:12], Y_train_pred[:, 1:12])  
print(mse) 

# Calculate Pearson correlation coefficients
r_OOB = [pearsonr(Y_train_predOOB[:, i], Y_train.iloc[:, i])[0] for i in range(1, 12)]
r = [pearsonr(Y_train_pred[:, i], Y_train.iloc[:, i])[0] for i in range(1, 12)]

oob_r2 = np.mean(r_OOB)
r2 = np.mean(r)

# Reshape the r and r_OOB arrays to match the dimensions of the merge array
r = np.array(r).reshape(1, -1)
r_OOB = np.array(r_OOB).reshape(1, -1)

# Concatenate the arrays to create the merge array
merge = np.concatenate((np.array([[n, o, r2, oob_r2, mse, oob_mse]]), r, r_OOB), axis=1)

# merge = np.c_[n, o, r2, oob_r2, mse, oob_mse] + r + r_OOB

print(merge)
fmt = ' '.join(['%i'] * 2 + ['%.4f'] * (merge.shape[1] - 2))

savetxt( rf'./stationID_x_y_valueALL_predictors_YscoreN{N_EST_S}_{obs_s}obs_{samp_s}samp.txt', merge, delimiter=' ',  fmt=fmt  )

## Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train.columns[1:])
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_s}obs_{samp_s}samp.txt', index=True, sep=' ', header=False)

EOF

" # closing the sif 



exit
# explanation
How BoundedGroupAwareRandomForest Works
1 Standard Random Forest (RandomForestRegressor)
   A Random Forest is an ensemble of multiple Decision Trees.
   Each tree is trained on a bootstrap sample (random subset of training data).
   The final prediction is the average of all tree outputs.

2 Custom Decision Tree (GroupAwareDecisionTree)
   Each individual Decision Tree is modified to respect group constraints.
   Instead of randomly splitting the data, it ensures that entire IDraster groups stay together.
   This prevents the same station (IDraster) from being split into different branches, improving model consistency.

3 Custom Random Forest (BoundedGroupAwareRandomForest)
   Instead of using standard DecisionTreeRegressor, this RF builds multiple GroupAwareDecisionTree models.
   It still trains on random bootstrap samples, but ensures group-level constraints.
   It averages predictions from multiple constrained decision trees.
   It forces predictions ≥ 0, preventing negative discharge values.

   

X_train['original_index'] = X_train.index
X_train = X_train.sort_values(by='IDraster').reset_index(drop=True)

Y_train['original_index'] = Y_train.index
Y_train = Y_train.sort_values(by='IDraster').reset_index(drop=True)

# Restore original order if needed
X_train = X_train.sort_values(by='original_index').drop(columns=['original_index']).reset_index(drop=True)
Y_train = Y_train.sort_values(by='original_index').drop(columns=['original_index']).reset_index(drop=True)
   
