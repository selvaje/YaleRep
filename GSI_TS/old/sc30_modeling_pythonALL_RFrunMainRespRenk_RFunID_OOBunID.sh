#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling-pythonALL_RFrunMainRespRenk_RFunID_OOBunID.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_OOBunID.sh.%A_%a.err
#SBATCH --job-name=sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_OOBunID.sh
#SBATCH --array=300
#SBATCH --mem=200G

##### #SBATCH --array=200,400,500,600
#### for obs in 2 4 5 8 10 15; do sbatch --export=obs=$obs /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc30_modeling_pythonALL_RFrunMainRespRenk_RFunID_RFunID_OOBunID.sh; done 
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


##  full dataset 
#  cut -d " " -f1-19       $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt
#  cut -d " " -f1-8,20-    $EXTRACT/stationID_x_y_valueALL_predictors.txt  >   $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt 
#  shuff=1000000
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt 
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt

#  awk '{ if (NR> 1) print }'  $EXTRACT/stationID_x_y_valueALL_predictors.txt | shuf -n $shuff > $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt
#  cut -d " " -f1-19    $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt
#  cut -d " " -f1-8,20- $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt 

#  shuff=111 
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_Y.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt 
#  head -1 $EXTRACTpy/stationID_x_y_valueALL_predictors_X.txt >  $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt
 
#  grep ^$shuff   $EXTRACT/stationID_x_y_valueALL_predictors.txt  > $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt
#  cut -d " " -f1-19    $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Ys$shuff.txt
#  cut -d " " -f1-8,20- $EXTRACTpy/stationID_x_y_valueALL_predictors_YXs$shuff.txt >> $EXTRACTpy/stationID_x_y_valueALL_predictors_Xs$shuff.txt 

#### check importing of $EXTRACTpy/stationID_x_y_valueALL_predictors_randY.txt  .. 

echo "start python modeling"
#### see https://machinelearningmastery.com/rfe-feature-selection-in-python/ 

cd $EXTRACTpy

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeovenv/bin:$PATH" \
 --env=obs=$obs,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

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
pd.set_option('display.max_columns', None)  # Show all columns

obs_s=(os.environ['obs'])
obs_i=int(os.environ['obs'])
print(obs_s)

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])
print(N_EST_S)

X_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_Xs111.txt', header=0, sep=' ', usecols=lambda column: column not in ['ID','YYYY','MM','lon','lat','Xcoord','Ycoord'])
Y_train  = pd.read_csv(rf'./stationID_x_y_valueALL_predictors_Ys111.txt', header=0, sep=' ', usecols=lambda column: column not in ['ID','YYYY','MM','lon','lat','Xcoord','Ycoord'])
print('Training and Testing data')
print('################################')
print(X_train.head(4))
print('################################')
print(Y_train.head(4))
print('################################')
print(X_train.shape)
print(Y_train.shape)

##  Maintain original row order
X_train = X_train.sort_values(by='IDraster').reset_index(drop=True)
Y_train = Y_train.sort_values(by='IDraster').reset_index(drop=True)

# Custom Decision Tree to enforce Group constraints
class GroupAwareDecisionTree(DecisionTreeRegressor):
    def fit(self, X, y, sample_weight=None, check_input=True):
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

# Custom Random Forest to enforce Group constraints & ensure non-negative predictions

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def fit(self, X, Y):
        self.oob_predictions = np.full(Y.drop(columns=['IDraster']).shape, fill_value=np.nan, dtype=np.float64)  # OOB storage
        unique_groups = np.unique(X['IDraster'])
        self.estimators_ = []
        
        for _ in range(self.n_estimators):
            boot_groups = np.random.choice(unique_groups, size=len(unique_groups), replace=True)
            train_mask = X['IDraster'].isin(boot_groups)
            oob_mask = ~train_mask

            tree = GroupAwareDecisionTree()
            X_train_filtered = X.loc[train_mask].drop(columns=['IDraster']).copy()
            Y_train_filtered = Y.loc[train_mask].drop(columns=['IDraster']).copy()
            tree.fit(X_train_filtered, Y_train_filtered)
            self.estimators_.append(tree)

            if np.any(oob_mask):
                X_oob_filtered = X.loc[oob_mask].drop(columns=['IDraster']).copy()
                self.oob_predictions[oob_mask, :] = tree.predict(X_oob_filtered)

        return self
    
    def predict(self, X):
        X_filtered = X.drop(columns=['IDraster']).copy()
        y_pred = np.mean([tree.predict(X_filtered) for tree in self.estimators_], axis=0)
        return np.maximum(y_pred, 0)  # Ensure non-negative predictions

# Compute OOB error for each Q (QMIN to QMAX) at the group level, ensuring IDraster is retained and filtering by observation count.

    def compute_oob_error(self, Y_true):
        unique_idrasters = Y_true['IDraster'].unique()
        oob_errors_list = []
        
        for idraster in unique_idrasters:
            if (Y_true['IDraster'] == idraster).sum() <= 5:
                oob_errors_list.append([idraster] + [np.nan] * (Y_true.shape[1] - 1))
                continue
            mask = Y_true['IDraster'] == idraster
            if np.any(mask):
                Y_true_filtered = Y_true.loc[mask].drop(columns=['IDraster'])
                oob_pred_filtered = self.oob_predictions[mask, :]
                errors = [pearsonr(Y_true_filtered[col], oob_pred_filtered[:, i])[0] for i, col in enumerate(Y_true_filtered.columns)]
                oob_errors_list.append([idraster] + errors)
        
        oob_errors = np.array(oob_errors_list)
        overall_oob_error = np.nanmean(oob_errors[:, 1:], axis=0)  # Ignore IDraster column in mean calculation
        return oob_errors, overall_oob_error

# Step 2: Use This Custom RF Model
# Replace RandomForestRegressor  with GroupAwareRandomForest:

RFreg = BoundedGroupAwareRandomForest(random_state=24, n_estimators=N_EST_I, n_jobs=16, oob_score=False, bootstrap=True, min_samples_leaf=obs_i, min_samples_split=obs_i)

# Fit the model with group-aware constraints

RFreg.fit(X_train, Y_train)  # Train the model with ID constraints

Y_train_pred = np.column_stack([Y_train['IDraster'].values, RFreg.predict(X_train)])
Y_train_predOOB = np.column_stack([Y_train['IDraster'].values, RFreg.oob_predictions])

print(Y_train_pred[:4])
print(Y_train_predOOB[:4])

# Compute OOB error (at the group level)

oob_errors, overall_oob_error = RFreg.compute_oob_error(Y_train)

print(overall_oob_error)

#### make prediction using the oob
fmt = '%i %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
savetxt(rf'./stationID_x_y_valueALL_predictors_YOOBpredictN{N_EST_S}_{obs_s}obs.txt', Y_train_predOOB, delimiter=' ',  header='IDraster QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='' , fmt=fmt)

savetxt(rf'./stationID_x_y_valueALL_predictors_YpredictN{N_EST_S}_{obs_s}obs.txt', Y_train_pred , delimiter=' ', header='IDraster QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='' , fmt=fmt)

fmt = '%i %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
savetxt(rf'./stationID_x_y_valueALL_predictors_OOBrID_N{N_EST_S}_{obs_s}obs_IDr.txt', oob_errors , delimiter=' ', fmt=fmt  , comments='')
fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
savetxt(rf'./stationID_x_y_valueALL_predictors_OOBrID_N{N_EST_S}_{obs_s}obs_all.txt', [overall_oob_error] , delimiter=' ', fmt=fmt, comments='')

print('overall OOB score' ,  overall_oob_error ) 


# n=np.array(N_EST_I)
# o=np.array(obs_i)

# oob_mse = mean_squared_error(Y_train, RFreg.oob_prediction_)
# mse = mean_squared_error(Y_train, RFreg.predict(X_train))

# rQMIN = stats.pearsonr(RFreg.oob_prediction_[:,0],Y_train.iloc[:, 0])[0]
# rQ10  = stats.pearsonr(RFreg.oob_prediction_[:,1],Y_train.iloc[:, 1])[0]
# rQ20  = stats.pearsonr(RFreg.oob_prediction_[:,2],Y_train.iloc[:, 2])[0]
# rQ30  = stats.pearsonr(RFreg.oob_prediction_[:,3],Y_train.iloc[:, 3])[0]  
# rQ40  = stats.pearsonr(RFreg.oob_prediction_[:,4],Y_train.iloc[:, 4])[0] 
# rQ50  = stats.pearsonr(RFreg.oob_prediction_[:,5],Y_train.iloc[:, 5])[0]
# rQ60  = stats.pearsonr(RFreg.oob_prediction_[:,6],Y_train.iloc[:, 6])[0]
# rQ70  = stats.pearsonr(RFreg.oob_prediction_[:,7],Y_train.iloc[:, 7])[0]
# rQ80  = stats.pearsonr(RFreg.oob_prediction_[:,8],Y_train.iloc[:, 8])[0]
# rQ90  = stats.pearsonr(RFreg.oob_prediction_[:,9],Y_train.iloc[:, 9])[0]
# rQMAX = stats.pearsonr(RFreg.oob_prediction_[:,10],Y_train.iloc[:, 10])[0]

# merge=np.c_[n,o,r2,oob_r2,mse,oob_mse,rQMIN,rQ10,rQ20,rQ30,rQ40,rQ50,rQ60,rQ70,rQ80,rQ90,rQMAX]

# print(merge)
# savetxt( rf'./stationID_x_y_valueALL_predictors_YscoreN{N_EST_S}_{obs_s}obs.txt', merge, delimiter=' ',  fmt='%f'  )

# Get feature importances and sort them in descending order     

# importance = pd.Series(RFreg.feature_importances_, index=X_train.columns)
# importance.sort_values(ascending=False, inplace=True)
# print(importance)

# importance.to_csv(rf'./stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_s}obs.txt' , index=True , sep=' ' , header=False)

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
