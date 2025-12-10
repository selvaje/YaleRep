#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 22  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500,800
#SBATCH --mem=800G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'
import pandas as pd
import numpy as np  # Only for sqrt in kge and array stacking in predict
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.base import RegressorMixin
from sklearn.metrics import mean_absolute_error, r2_score
from scipy.stats import spearmanr
from joblib import Parallel, delayed
import gc
import os 
pd.set_option('display.max_columns', None)

obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_i = int(os.environ['obs_split'])
sample_f = float(os.environ['sample'])
sample_s = str(int(sample_f * 100))
N_EST_I = int(os.environ['N_EST'])
N_EST_S = os.environ['N_EST']

# Define custom classes
class GroupAwareDecisionTree(DecisionTreeRegressor):
    def __init__(self, *, min_samples_leaf=1, min_samples_split=2):
        super().__init__(min_samples_leaf=min_samples_leaf, min_samples_split=min_samples_split)

    def fit(self, X, y, sample_weight=None, check_input=True):
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def __init__(self, *, n_estimators=100, min_samples_leaf=1, min_samples_split=2, max_samples=None, **kwargs):
        super().__init__(n_estimators=n_estimators, min_samples_leaf=min_samples_leaf, min_samples_split=min_samples_split, max_samples=max_samples, **kwargs)
        self.oob_score_ = None
        self.output_columns = None

    def fit(self, X, Y):
        X = X.astype('float32')
        Y = Y.astype('float32')
        self.n_features_ = X.shape[1] - 1  # Exclude IDr
        self.output_columns = Y.columns  # Store output columns
        unique_groups = X['IDr'].unique()

        # Initialize OOB predictions if enabled
        if self.oob_score and self.bootstrap:
            oob_predictions = pd.DataFrame(0.0, index=X.index, columns=Y.columns)
            oob_counts = pd.Series(0, index=X.index, dtype='int32')

        def train_tree(boot_groups, tree_idx):
            train_mask = X['IDr'].isin(boot_groups)
            tree = GroupAwareDecisionTree(
                min_samples_leaf=self.min_samples_leaf,
                min_samples_split=self.min_samples_split
            )
            X_train_filtered = X[train_mask].drop(columns=['IDr'])
            Y_train_filtered = Y[train_mask]
            tree.fit(X_train_filtered, Y_train_filtered)

            if self.oob_score and self.bootstrap:
                oob_mask = ~train_mask
                if oob_mask.any():
                    X_oob = X[oob_mask].drop(columns=['IDr'])
                    oob_pred = pd.DataFrame(tree.predict(X_oob), index=X_oob.index, columns=Y.columns)
                    oob_pred = oob_pred.fillna(0)  # Replace NaN predictions with 0
                    oob_predictions.loc[oob_mask] += oob_pred
                    oob_counts.loc[oob_mask] += 1

            del X_train_filtered, Y_train_filtered
            gc.collect()
            return tree

        self.estimators_ = Parallel(n_jobs=self.n_jobs, prefer='threads')(
            delayed(train_tree)(
                np.random.choice(unique_groups, size=len(unique_groups), replace=True), i
            ) for i in range(self.n_estimators)
        )

        if self.oob_score and self.bootstrap:
            valid_oob = oob_counts > 0
            oob_predictions[valid_oob] = oob_predictions[valid_oob].div(oob_counts[valid_oob], axis=0)
            oob_predictions = oob_predictions.fillna(0)  # Ensure no NaN in OOB predictions
            oob_r2_scores = [
                r2_score(Y.loc[valid_oob, col], oob_predictions.loc[valid_oob, col])
                for col in Y.columns if valid_oob.any() and not oob_predictions.loc[valid_oob, col].isna().all()
            ]
            self.oob_score_ = pd.Series(oob_r2_scores).mean() if oob_r2_scores else np.nan

        return self

    def predict(self, X):
        if 'IDr' in X.columns:
            X_pred = X.drop(columns=['IDr'])
        else:
            X_pred = X
        if X_pred.shape[1] != self.n_features_:
            raise ValueError(f'Expected {self.n_features_} columns, got {X_pred.shape[1]}')
        
        all_preds = Parallel(n_jobs=self.n_jobs, prefer='threads')(
            delayed(tree.predict)(X_pred) for tree in self.estimators_
        )
        # Stack predictions into a 3D NumPy array and compute mean across trees (axis=0)
        all_preds = np.stack(all_preds, axis=0)  # Shape: (n_estimators, n_samples, n_outputs)
        y_pred = np.mean(all_preds, axis=0)  # Shape: (n_samples, n_outputs)
        y_pred = pd.DataFrame(y_pred, columns=self.output_columns).clip(lower=0).fillna(0)  # Ensure no NaN
        return y_pred

# Define column data types for X
dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo']},
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity', 'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
        'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
        'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale', 'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation']}
}

# Define column data types for Y
dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

# Read feature importance and select top 40 variables
importance = pd.read_csv('../extract4py_sample_red/importance_sampleAll.txt', header=None, sep='\s+', engine='c')
include_variables = importance.iloc[:40, 1].tolist() + ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']

# Read data
Y = pd.read_csv('stationID_x_y_valueALL_predictors_Y.txt', sep='\s+', dtype=dtypes_Y, engine='c')
X = pd.read_csv('stationID_x_y_valueALL_predictors_X.txt', sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c')

# Reset indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# Check for NaN in input data and impute with 0
X = X.fillna(0)
Y = Y.fillna(0)

# Read station data and create clusters based on coordinates
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt', sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()
stations['cluster'] = pd.qcut(stations['Xcoord'], q=50, labels=False)

# Split data based on clusters
train_rasters, test_rasters = train_test_split(stations['IDr'], test_size=0.2, random_state=24, stratify=stations['cluster'])
X_train = X[X['IDr'].isin(train_rasters)].reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_rasters)].reset_index(drop=True)
X_test = X[X['IDr'].isin(test_rasters)].reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_rasters)].reset_index(drop=True)

# Save train/test splits
X_train.to_csv(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
X_test.to_csv(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
Y_train.to_csv(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
Y_test.to_csv(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)

# Prepare data for modeling
X_train_model = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM'])
Y_train_model = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr'])
X_test_model = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM'])
Y_test_model = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr'])

# Check for NaN in modeling data and impute with 0
X_train_model = X_train_model.fillna(0)
Y_train_model = Y_train_model.fillna(0)
X_test_model = X_test_model.fillna(0)
Y_test_model = Y_test_model.fillna(0)

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

# Initialize and fit BoundedGroupAwareRandomForest
rf = BoundedGroupAwareRandomForest(
    n_estimators=N_EST_I,
    min_samples_leaf=obs_leaf_i,
    min_samples_split=obs_split_i,
    max_samples=sample_f,
    oob_score=True,
    bootstrap=True,
    random_state=24,
    n_jobs=-1
)
rf.fit(X_train_model, Y_train_model)

# Output OOB score
oob_r2 = rf.oob_score_
oob_error = 1 - oob_r2 if not pd.isna(oob_r2) else np.nan
pd.DataFrame([[N_EST_I, sample_f, obs_split_i, obs_leaf_i, oob_r2, oob_error]], 
             columns=['N_EST', 'sample', 'obs_split', 'obs_leaf', 'oob_r2', 'oob_error']).to_csv(
    f'../predict_score_red/stationID_x_y_valueALL_predictors_YscoreoobN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt',
    sep=' ', index=False)

# Make predictions
Y_train_pred = pd.DataFrame(rf.predict(X_train_model), columns=Y_train_model.columns).fillna(0)
Y_test_pred = pd.DataFrame(rf.predict(X_test_model), columns=Y_test_model.columns).fillna(0)

# Compute Kling-Gupta Efficiency
def kge(y_true, y_pred):
    if y_true.isna().any() or y_pred.isna().any():
        return np.nan
    r = y_true.corr(y_pred)
    beta = y_pred.mean() / y_true.mean() if y_true.mean() != 0 else np.nan
    gamma = y_pred.std() / y_true.std() if y_true.std() != 0 else np.nan
    if pd.isna(r) or pd.isna(beta) or pd.isna(gamma):
        return np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

# Calculate metrics with NaN handling
train_r_coll = []
test_r_coll = []
train_rho_coll = []
test_rho_coll = []
train_mae_coll = []
test_mae_coll = []
train_kge_coll = []
test_kge_coll = []

for i in range(Y_train_model.shape[1]):
    y_train_true = Y_train_model.iloc[:, i]
    y_train_pred = Y_train_pred.iloc[:, i]
    y_test_true = Y_test_model.iloc[:, i]
    y_test_pred = Y_test_pred.iloc[:, i]
    
    # Pearson correlation
    train_r_coll.append(y_train_true.corr(y_train_pred) if not y_train_true.isna().all() and not y_train_pred.isna().all() else np.nan)
    test_r_coll.append(y_test_true.corr(y_test_pred) if not y_test_true.isna().all() and not y_test_pred.isna().all() else np.nan)
    
    # Spearman correlation
    train_rho_coll.append(spearmanr(y_train_true, y_train_pred)[0] if not y_train_true.isna().all() and not y_train_pred.isna().all() else np.nan)
    test_rho_coll.append(spearmanr(y_test_true, y_test_pred)[0] if not y_test_true.isna().all() and not y_test_pred.isna().all() else np.nan)
    
    # MAE (skip if NaN present)
    train_mae_coll.append(mean_absolute_error(y_train_true, y_train_pred) if not y_train_true.isna().any() and not y_train_pred.isna().any() else np.nan)
    test_mae_coll.append(mean_absolute_error(y_test_true, y_test_pred) if not y_test_true.isna().any() and not y_test_pred.isna().any() else np.nan)
    
    # KGE
    train_kge_coll.append(kge(y_train_true, y_train_pred))
    test_kge_coll.append(kge(y_test_true, y_test_pred))

# Compute means, ignoring NaN
train_r_all = pd.Series(train_r_coll).mean(skipna=True)
test_r_all = pd.Series(test_r_coll).mean(skipna=True)
train_rho_all = pd.Series(train_rho_coll).mean(skipna=True)
test_rho_all = pd.Series(test_rho_coll).mean(skipna=True)
train_mae_all = pd.Series(train_mae_coll).mean(skipna=True)
test_mae_all = pd.Series(test_mae_coll).mean(skipna=True)
train_kge_all = pd.Series(train_kge_coll).mean(skipna=True)
test_kge_all = pd.Series(test_kge_coll).mean(skipna=True)

# Prepare output DataFrames
initial_df = pd.DataFrame([[N_EST_I, sample_f, obs_split_i, obs_leaf_i]], 
                          columns=['N_EST', 'sample', 'obs_split', 'obs_leaf'])
merge_r = pd.concat([initial_df, 
                     pd.DataFrame([[train_r_all, test_r_all]], columns=['train_r_all', 'test_r_all']),
                     pd.DataFrame([train_r_coll], columns=Y_train_model.columns),
                     pd.DataFrame([test_r_coll], columns=Y_test_model.columns)], axis=1)
merge_rho = pd.concat([initial_df, 
                       pd.DataFrame([[train_rho_all, test_rho_all]], columns=['train_rho_all', 'test_rho_all']),
                       pd.DataFrame([train_rho_coll], columns=Y_train_model.columns),
                       pd.DataFrame([test_rho_coll], columns=Y_test_model.columns)], axis=1)
merge_mae = pd.concat([initial_df, 
                       pd.DataFrame([[train_mae_all, test_mae_all]], columns=['train_mae_all', 'test_mae_all']),
                       pd.DataFrame([train_mae_coll], columns=Y_train_model.columns),
                       pd.DataFrame([test_mae_coll], columns=Y_test_model.columns)], axis=1)
merge_kge = pd.concat([initial_df, 
                       pd.DataFrame([[train_kge_all, test_kge_all]], columns=['train_kge_all', 'test_kge_all']),
                       pd.DataFrame([train_kge_coll], columns=Y_train_model.columns),
                       pd.DataFrame([test_kge_coll], columns=Y_test_model.columns)], axis=1)

# Save metrics
merge_r.to_csv(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
merge_rho.to_csv(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
merge_mae.to_csv(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
merge_kge.to_csv(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)

# Save feature importance
importance = pd.Series(rf.feature_importances_, index=X_train_model.columns[1:]).sort_values(ascending=False)
importance.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', header=False)

# Save predictions
Y_train_pred.to_csv(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)
Y_test_pred.to_csv(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_i}leaf_{obs_split_i}split_{sample_s}sample_2RF.txt', sep=' ', index=False)

EOF
" ## close the sif
exit
