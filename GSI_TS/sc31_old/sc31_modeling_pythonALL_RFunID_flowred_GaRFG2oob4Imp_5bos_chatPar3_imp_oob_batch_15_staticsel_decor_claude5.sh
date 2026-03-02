#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500
#SBATCH --mem=500G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv

export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export depth=$depth ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth"
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,depth=$depth,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<EOF
import os
import gc
import warnings
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GroupKFold 
from sklearn.feature_selection import RFECV
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed
import psutil

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

# ============================================================================
# CONFIGURATION & INPUT PARSING
# ============================================================================

obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_i = int(os.environ['obs_split'])
depth_i = int(os.environ['depth'])
sample_f = float(os.environ['sample'])
N_EST_I = int(os.environ['N_EST'])

obs_leaf_s = str(obs_leaf_i)
obs_split_s = str(obs_split_i)
depth_s = str(depth_i)
sample_s = str(int(sample_f * 100))
N_EST_S = str(N_EST_I)

print(f'Config: N_EST={N_EST_I}, leaf={obs_leaf_i}, split={obs_split_i}, depth={depth_i}, sample={sample_f}')

# ============================================================================
# STATIC/DYNAMIC VARIABLE DEFINITIONS
# ============================================================================

static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg','channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg','AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine',
    'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev',
    'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dynamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# ============================================================================
# DATA TYPE DEFINITIONS
# ============================================================================

dtypes_X = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
}

climate_soil_cols = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
]

feature_cols = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg','channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg','AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine',
    'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev',
    'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dtypes_X.update({col: 'int32' for col in climate_soil_cols if col not in dtypes_X})
dtypes_X.update({col: 'float32' for col in feature_cols})

dtypes_Y = {
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',
}
dtypes_Y.update({col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']})

# ============================================================================
# DATA LOADING (Chunked for memory efficiency)
# ============================================================================

def load_with_dtypes(filepath, usecols=None, dtype_dict=None, chunksize=50000):
    chunks = []
    for chunk in pd.read_csv(filepath, header=0, sep='\s+', 
                             usecols=usecols, dtype=dtype_dict, 
                             engine='c', chunksize=chunksize):
        chunks.append(chunk)
        if len(chunks) % 10 == 0:
            gc.collect()
    return pd.concat(chunks, ignore_index=True) if chunks else pd.DataFrame()

print('Loading predictor importance...')
importance = pd.read_csv('varX_list.txt', header=None, sep='\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)

print('Loading Y data...')
Y = load_with_dtypes('stationID_x_y_valueALL_predictors_Y_floredSFD.txt', dtype_dict=dtypes_Y)

print('Loading X data...')
X = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', usecols=lambda col: col in include_variables, dtype_dict=dtypes_X)

print(f'X shape: {X.shape}, Y shape: {Y.shape}')

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# ============================================================================
# EFFICIENT STATION-LEVEL AGGREGATION
# ============================================================================

print('Loading station coordinates...')
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
                        sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

print('Filtering stations by observation count...')
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index.values
print(f'Filtered training to {len(valid_idr_train)} stations with >10 observations')

# ============================================================================
# SPATIAL TRAIN/TEST SPLIT WITH SINGLETON-CLUSTER HANDLING
# ============================================================================

unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates().reset_index(drop=True)

print('Performing KMeans clustering for spatial separation...')
kmeans = KMeans(n_clusters=20, random_state=24, n_init=10)
unique_stations['cluster'] = kmeans.fit_predict(unique_stations[['Xcoord', 'Ycoord']])

train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']].copy()

cluster_counts = train_stations['cluster'].value_counts()
print(f'Cluster distribution: {cluster_counts.to_dict()}')
print(f'Singleton clusters: {(cluster_counts == 1).sum()}')

sufficient_clusters = cluster_counts[cluster_counts > 1].index.values
filtered_train_stations = train_stations[train_stations['cluster'].isin(sufficient_clusters)].copy()

if filtered_train_stations.empty:
    raise RuntimeError('No clusters with >1 member remain. Adjust KMeans n_clusters or lower stratification threshold.')

print(f'Performing stratified split on {len(sufficient_clusters)} non-singleton clusters...')

train_rasters, test_rasters = train_test_split(
    filtered_train_stations,
    test_size=0.2,
    random_state=24,
    stratify=filtered_train_stations['cluster']
)

print(f'Train stations: {len(train_rasters)}, Test stations: {len(test_rasters)}')

X_train = X[X['IDr'].isin(train_rasters['IDr'].values)].reset_index(drop=True)
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'].values)].reset_index(drop=True)
X_test = X[X['IDr'].isin(test_rasters['IDr'].values)].reset_index(drop=True)
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'].values)].reset_index(drop=True)

print(f'Train: X={X_train.shape}, Y={Y_train.shape}')
print(f'Test:  X={X_test.shape}, Y={Y_test.shape}')

# ✓ PRESERVE ORIGINAL INDICES FOR LATER ALIGNMENT
X_train_orig_idx = X_train.index.values
Y_train_orig_idx = Y_train.index.values
X_test_orig_idx = X_test.index.values
Y_test_orig_idx = Y_test.index.values

# ✓ SORT FOR FILE OUTPUT (preserve sorting key)
sort_key_train = ['IDs', 'IDr', 'YYYY', 'MM']
sort_key_test = ['IDs', 'IDr', 'YYYY', 'MM']

X_train_sorted = X_train.sort_values(by=sort_key_train).reset_index(drop=True)
Y_train_sorted = Y_train.sort_values(by=sort_key_train).reset_index(drop=True)
X_test_sorted = X_test.sort_values(by=sort_key_test).reset_index(drop=True)
Y_test_sorted = Y_test.sort_values(by=sort_key_test).reset_index(drop=True)

print('Train/test data summary:')
print(f'Y_train: {Y_train_sorted.describe()}')
print(f'Y_test: {Y_test_sorted.describe()}')

# ✓ SAVE SORTED DATA
fmt = ' '.join(['%.f'] * X_train_sorted.shape[1])
X_column_names = np.array(X_train_sorted.columns)
X_column_names_str = ' '.join(X_column_names)

np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
           X_train_sorted.values, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
           X_test_sorted.values, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

fmt_Y = '%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names = np.array(Y_train_sorted.columns)
Y_column_names_str = ' '.join(Y_column_names)

np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',Y_train_sorted.values, delimiter=' ', fmt=fmt_Y, header=Y_column_names_str, comments='')
np.savetxt(f'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',Y_test_sorted.values, delimiter=' ', fmt=fmt_Y, header=Y_column_names_str, comments='')

del X_train_sorted, Y_train_sorted, X_test_sorted, Y_test_sorted
gc.collect()

# ============================================================================
# PREPARE NUMPY ARRAYS FOR MODELING (USE ORIGINAL INDICES, NOT SORTED)
# ============================================================================

X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy(dtype='float32')
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy(dtype='float32')

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy(dtype='float32')
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy(dtype='float32')

X_train_mm = X_train['MM'].values.astype('int32')
groups_train = X_train['IDr'].to_numpy(dtype='int32')
X_train_column_names = np.array(X_train.drop(columns=['YYYY', 'MM', 'IDr', 'IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']).columns)

print(f'X_train_np shape: {X_train_np.shape}')
print(f'Y_train_np shape: {Y_train_np.shape}')
print(f'groups_train shape: {groups_train.shape}')

# ✓ VERIFY INDEX ALIGNMENT
print(f'✓ Index alignment check:')
print(f'  X_train original indices: {len(X_train_orig_idx)} samples')
print(f'  Y_train original indices: {len(Y_train_orig_idx)} samples')
print(f'  X_test original indices: {len(X_test_orig_idx)} samples')
print(f'  Y_test original indices: {len(Y_test_orig_idx)} samples')

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

class GroupAwareMultiOutput(BaseEstimator, RegressorMixin):
    def __init__(self, base_estimator, n_cv_folds=5, n_jobs=1, inner_n_jobs=1,
                 random_state=24, oob_metric='r2', verbose=0):
        self.base_estimator = base_estimator
        self.n_cv_folds = n_cv_folds
        self.n_jobs = n_jobs
        self.inner_n_jobs = inner_n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.verbose = verbose
        
        self.models_ = []
        self.oob_predictions_ = None
        self.oob_r2_per_target_ = None
        self.oob_r2_mean_ = None
        self.oob_scores_ = None
        self.final_importances_ = None
        self._groups = None
        self.X_column_names_ = None
        self._fitted = False

    def fit(self, X, Y, groups=None, X_column_names=None, do_oob_cv=True):
        X = np.asarray(X, dtype=np.float32)
        Y = np.asarray(Y, dtype=np.float32)
        
        if X_column_names is None:
            X_column_names = [f'feat_{i}' for i in range(X.shape[1])]
        self.X_column_names_ = list(X_column_names)
        
        if groups is not None:
            self._groups = np.asarray(groups, dtype=np.int32)
        
        n_samples, n_features = X.shape
        n_targets = Y.shape[1] if Y.ndim == 2 else 1
        
        if groups is None or (not bool(do_oob_cv)):
            if self.verbose > 0:
                print('Fitting final model on all data (no OOB CV)')
            
            final_model = self.base_estimator(
                random_state=self.random_state,
                n_jobs=self.inner_n_jobs
            )
            final_model.fit(X, Y)
            self.models_ = [final_model]
            
            self._extract_importances(final_model)
            
            self.oob_predictions_ = np.full((n_samples, n_targets), np.nan, dtype=np.float32)
            self.oob_r2_per_target_ = np.array([np.nan] * n_targets)
            self.oob_r2_mean_ = np.nan
            self.oob_scores_ = np.array([np.nan] * n_targets)
            self._fitted = True
            return self
        
        if self._groups is None or self._groups.size == 0:
            raise ValueError('groups must be provided for group-aware OOB CV')
        
        n_splits = min(self.n_cv_folds, len(np.unique(self._groups)))
        gkf = GroupKFold(n_splits=n_splits)
        oob_preds = np.full((n_samples, n_targets), np.nan, dtype=np.float32)
        
        if self.verbose > 0:
            print(f'Running GroupKFold OOB CV with {n_splits} splits...')
        
        rng = np.random.RandomState(self.random_state)
        seeds = rng.randint(0, 100000, size=n_splits)
        
        def _fit_fold(fold_idx, train_idx, test_idx, seed):
            try:
                est = self.base_estimator(
                    random_state=int(seed),
                    n_jobs=self.inner_n_jobs
                )
                est.fit(X[train_idx], Y[train_idx])
                preds = est.predict(X[test_idx])
                
                if self.verbose > 1:
                    print(f'  Fold {fold_idx+1}/{n_splits} completed')
                
                return test_idx, preds
            except Exception as e:
                print(f'Error in fold {fold_idx+1}: {e}')
                raise
        
        fold_results = Parallel(n_jobs=self.n_jobs, backend='threading', 
                               verbose=max(0, self.verbose-1))(
            delayed(_fit_fold)(i, trn, tst, seeds[i])
            for i, (trn, tst) in enumerate(gkf.split(X, y=Y, groups=self._groups))
        )
        
        for test_idx, preds in fold_results:
            oob_preds[test_idx] = preds
        
        self.oob_predictions_ = oob_preds
        self._compute_oob_scores(Y, oob_preds)
        
        if self.verbose > 0:
            print('Fitting final model on all data...')
        
        final_model = self.base_estimator(
            random_state=self.random_state,
            n_jobs=self.inner_n_jobs
        )
        final_model.fit(X, Y)
        self.models_ = [final_model]
        
        self._extract_importances(final_model)
        self._fitted = True
        
        if self.verbose > 0:
            print(f'OOB R² (mean): {self.oob_r2_mean_:.4f}')
        
        return self

    def _extract_importances(self, model):
        if hasattr(model, 'feature_importances_'):
            self.feature_importances_ = model.feature_importances_.astype(np.float32)
            self.final_importances_ = pd.Series(
                self.feature_importances_, index=self.X_column_names_
            ).sort_values(ascending=False)
        elif hasattr(model, 'coef_'):
            self.coef_ = model.coef_
            self.final_importances_ = None
        else:
            self.final_importances_ = None

    def _compute_oob_scores(self, Y_true, Y_pred_oob):
        n_targets = Y_true.shape[1]
        r2_list = []
        score_list = []
        
        for i in range(n_targets):
            y_true = Y_true[:, i]
            y_pred = Y_pred_oob[:, i]
            valid = ~np.isnan(y_pred)
            
            if int(valid.sum()) < 2:
                r2_list.append(np.nan)
                score_list.append(np.nan)
                continue
            
            r2 = r2_score(y_true[valid], y_pred[valid])
            r2_list.append(r2)
            
            if self.oob_metric == 'r2':
                score_list.append(r2)
            elif self.oob_metric == 'rmse':
                score_list.append(np.sqrt(mean_squared_error(y_true[valid], y_pred[valid])))
            else:
                score_list.append(r2)
        
        self.oob_r2_per_target_ = np.array(r2_list, dtype=np.float32)
        self.oob_r2_mean_ = np.nanmean(r2_list)
        self.oob_scores_ = np.array(score_list, dtype=np.float32)

    def predict(self, X):
        if len(self.models_) == 0 or not self._fitted:
            raise ValueError('Model not fitted.')
        return self.models_[0].predict(X)

    def get_importances(self):
        return self.final_importances_

    def print_oob_summary(self):
        if self.oob_r2_per_target_ is None:
            print('Model not fitted yet or OOB not computed.')
            return
        
        print(f'Overall OOB R² (mean across targets): {self.oob_r2_mean_:.4f}')
        labels = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
        for lbl, val in zip(labels, self.oob_r2_per_target_):
            status = f'{val:.4f}' if not np.isnan(val) else 'nan'
            print(f'  {lbl:6s}: {status}')


def decorrelate_group_fast(df, group_name, threshold=0.70, verbose=True):
    '''Remove highly correlated features using Spearman correlation (optimized).'''
    
    if df.empty or len(df.columns) <= 1:
        if verbose and not df.empty:
            print(f' {group_name:20s}: {len(df.columns)} vars (no decorrelation needed)')
        return df

    corr = df.corr(method='spearman').abs()
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))
    to_drop = set()

    for col in upper.columns:
        high_corr_with = upper.index[upper[col] > threshold].tolist()
        for drop_col in high_corr_with:
            if drop_col not in to_drop and drop_col != col:
                to_drop.add(drop_col)
    
    kept = [c for c in df.columns if c not in to_drop]
    if verbose:
        print(f' {group_name:20s}: {len(df.columns):3d} → {len(kept):3d} (ρ > {threshold:.2f})')
    
    del corr, upper
    gc.collect()
    
    return df[kept]

# ============================================================================
# FAST STATION-MONTH LEVEL FEATURE SELECTION (OPTIMIZED)
# ============================================================================

print('\n===== FAST STATION-MONTH LEVEL FEATURE SELECTION =====')
print('Building station-month level matrices for faster feature selection...')

all_cols = X_train_column_names.astype(str)

static_present = [c for c in static_var if c in all_cols]
dynamic_present = [c for c in dynamic_var if c in all_cols]

print(f'Feature inventory:')
print(f'  Static variables: {len(static_present)}/{len(static_var)}')
print(f'  Dynamic variables: {len(dynamic_present)}/{len(dynamic_var)}')

if len(static_present) == 0:
    print('WARNING: No static variables found. Using dynamic only.')
    combined_names = dynamic_present
    final_mask = np.isin(all_cols, combined_names)
    X_train_selected = X_train_np[:, final_mask]
    X_test_selected = X_test_np[:, final_mask]
    selected_names = all_cols[final_mask]
else:
    # Build station-MONTH level aggregates
    station_df_full = pd.DataFrame(X_train_np, columns=all_cols)
    station_df_full['IDr'] = groups_train
    station_df_full['MM'] = X_train_mm
    
    station_summary = station_df_full.groupby(['IDr', 'MM'])[static_present].first().reset_index(drop=False)
    station_idr_mm = station_summary[['IDr', 'MM']].copy()
    station_summary = station_summary[static_present].reset_index(drop=True)
    del station_df_full
    gc.collect()
    
    Y_train_station = pd.DataFrame(Y_train_np, columns=['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX'])
    Y_train_station['IDr'] = groups_train
    Y_train_station['MM'] = X_train_mm
    Y_train_station_mean = Y_train_station.groupby(['IDr', 'MM'])[['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']].mean().reset_index(drop=True)
    del Y_train_station
    gc.collect()
    
    print(f'Station-month level matrices: X={station_summary.shape} (vs. full {X_train_np.shape})')
    print(f'                              Y={Y_train_station_mean.shape}')
    print(f'Speedup factor: ~{int(X_train_np.shape[0] / len(station_summary))}x\n')
    
    static_dec_df = decorrelate_group_fast(station_summary[static_present], 'Static', threshold=0.70, verbose=True)
    static_decorr = static_dec_df.columns.tolist()
    
    if len(static_decorr) == 0:
        print('WARNING: No static vars left after decorrelation. Using dynamic only.')
        combined_names = dynamic_present
        final_mask = np.isin(all_cols, combined_names)
        X_train_selected = X_train_np[:, final_mask]
        X_test_selected = X_test_np[:, final_mask]
        selected_names = all_cols[final_mask]
    else:
        X_static_station = station_summary[static_decorr].values.astype('float32')
        
        print(f'\nRunning FAST RFECV on station-month level data: {X_static_station.shape}')
        print(f'  (saves ~{int(X_train_np.shape[0] / len(station_summary))}x computation vs. full data)')
        
        print('Fitting RFECV on station-month level data...')
        station_groups = station_idr_mm['IDr'].values.astype('int32')
        
        # ✓ OPTIMIZED: Larger step size for faster convergence
        step_size = max(10, int(len(static_decorr) * 0.50))
        min_features = max(5, int(len(static_decorr) * 0.15))
        
        selector_fast = RFECV(
            estimator=ExtraTreesRegressor(
                n_estimators=50,
                max_depth=10,
                n_jobs=1,
                random_state=24,
                min_samples_leaf=5,
                min_samples_split=10
            ),
            step=step_size,
            min_features_to_select=min_features,
            cv=GroupKFold(n_splits=3),
            scoring='r2',
            n_jobs=16,
            verbose=1
        )
        
        selector_fast.fit(
            X_static_station,
            Y_train_station_mean.values.astype('float32'),
            groups=station_groups
        )
        
        # ============================================================================
        # EXTRACT AND DISPLAY RFECV RESULTS TABLE
        # ============================================================================
        
        support_mask_static = selector_fast.support_
        rfecv_rankings = selector_fast.ranking_
        rfecv_support = selector_fast.support_
        selected_static_names = np.array(static_decorr)[support_mask_static].tolist()
        
        rfecv_results_df = pd.DataFrame({
            'Feature': static_decorr,
            'Selected': rfecv_support,
            'Rank': rfecv_rankings
        })
        
        max_rank = rfecv_results_df['Rank'].max()
        
        def interpret_feature(row):
            if row['Rank'] == 1:
                return 'Core predictor (selected)'
            elif row['Rank'] == 2:
                return 'Borderline – removed last'
            elif row['Rank'] <= max_rank / 2:
                return 'Moderately weak or redundant'
            else:
                return 'Very weak – removed early'
        
        rfecv_results_df['Interpretation'] = rfecv_results_df.apply(interpret_feature, axis=1)
        rfecv_results_df['Survival_Score'] = max_rank - rfecv_results_df['Rank'] + 1
        rfecv_results_df = rfecv_results_df.sort_values('Rank').reset_index(drop=True)
        
        print('\n' + '='*130)
        print('RFECV FEATURE SELECTION RANKING (Static Features - Station-Month Level)')
        print('='*130)
        print(rfecv_results_df.to_string(index=False))
        print('='*130)
        
        n_selected = rfecv_results_df['Selected'].sum()
        n_total = len(rfecv_results_df)
        
        print(f'\nRFECV Summary:')
        print(f'  Total features evaluated: {n_total}')
        print(f'  Features selected: {n_selected}')
        print(f'  Features eliminated: {n_total - n_selected}')
        print(f'  Selection rate: {100*n_selected/n_total:.1f}%')
        print(f'  Max elimination rank: {max_rank}')
        
        selected_features_table = rfecv_results_df[rfecv_results_df['Selected']==True][['Feature', 'Rank', 'Survival_Score', 'Interpretation']]
        print('\nSELECTED FEATURES (Rank = 1):')
        print('-'*130)
        print(selected_features_table.to_string(index=False))
        
        eliminated_features_table = rfecv_results_df[rfecv_results_df['Selected']==False].head(10)[['Feature', 'Rank', 'Survival_Score', 'Interpretation']]
        if not eliminated_features_table.empty:
            print('\nTOP 10 ELIMINATED FEATURES (Removed Late = Nearly Competitive):')
            print('-'*130)
            print(eliminated_features_table.to_string(index=False))
        
        rfecv_results_df.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_RFECVrankingN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_static.txt',
                                index=False, sep=' ')
        print(f'\n✓ Full RFECV ranking saved')
        
        # ✓ CLEANUP INTERMEDIATE OBJECTS
        del rfecv_results_df, selected_features_table, eliminated_features_table
        gc.collect()
        
        print(f'\n✓ Selected {len(selected_static_names)}/{len(static_decorr)} static features by RFECV')
        print(f'  Features: {selected_static_names}')
        
        combined_names = list(selected_static_names) + list(dynamic_present)
        final_mask = np.isin(all_cols, combined_names)
        
        X_train_selected = X_train_np[:, final_mask]
        X_test_selected = X_test_np[:, final_mask]
        selected_names = all_cols[final_mask]

print(f'\nFinal feature set: {X_train_selected.shape[1]} features')
print(f'  Static (selected): {len([n for n in selected_names if n in static_var])}')
print(f'  Dynamic: {len(dynamic_present)}')

# ============================================================================
# FINAL MODEL TRAINING
# ============================================================================

def make_rf(**kw):
    if 'n_jobs' not in kw:
        kw['n_jobs'] = 1
    return RandomForestRegressor(
        n_estimators=N_EST_I,
        max_depth=depth_i,
        min_samples_leaf=obs_leaf_i,
        min_samples_split=obs_split_i,
        max_features=sample_f,
        **kw
    )

print(f'Initializing final model with {N_EST_I} trees...')
RFreg = GroupAwareMultiOutput(
    base_estimator=make_rf,
    n_cv_folds=5,
    n_jobs=16,
    inner_n_jobs=1,
    random_state=24,
    oob_metric='r2',
    verbose=1
)

print('Training final model with GroupKFold OOB CV...')
RFreg.fit(
    X_train_selected,
    Y_train_np,
    groups=groups_train,
    X_column_names=selected_names.tolist(),
    do_oob_cv=True
)

RFreg.print_oob_summary()

print('\nTop 30 feature importances:')
importances = RFreg.get_importances()
if importances is not None:
    print(importances.head(30))
    RFreg.feature_importances_ = RFreg.final_importances_.values
    RFreg.kept_cols_ = selected_names.tolist()

# ============================================================================
# PREDICTIONS & EVALUATION
# ============================================================================

print('\nGenerating predictions...')

Y_test_pred_nosort = RFreg.predict(X_test_selected)
Y_train_pred_nosort = RFreg.predict(X_train_selected)

def post_pred_check(Y_true_np, Y_pred_np, name='test'):
    print(f'{name} shapes: true {Y_true_np.shape}, pred {Y_pred_np.shape}')
    if Y_true_np.shape != Y_pred_np.shape:
        raise AssertionError('Shape mismatch between Y_true and Y_pred')
    
    for i in range(Y_true_np.shape[1]):
        tstd = np.nanstd(Y_true_np[:, i])
        pstd = np.nanstd(Y_pred_np[:, i])
        tnans = np.isnan(Y_true_np[:, i]).sum()
        pnans = np.isnan(Y_pred_np[:, i]).sum()
        print(f'  {name} col{i:2d} | true_std={tstd:.6f} pred_std={pstd:.6f} | true_NaN={tnans} pred_NaN={pnans}')

post_pred_check(Y_test_np, Y_test_pred_nosort, 'Y_test')
post_pred_check(Y_train_np, Y_train_pred_nosort, 'Y_train')

def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true)
    gamma = np.std(y_pred) / np.std(y_true)
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

# ============================================================================
# ✓ OPTIMIZED: Parallel metrics computation
# ============================================================================

print('COMPUTING ERROR METRICS (PARALLELIZED)...')

def compute_one_quantile(i, Y_pred, Y_true):
    '''Compute metrics for one quantile.'''
    y_pred = Y_pred[:, i]
    y_true = Y_true[:, i]
    
    r = pearsonr(y_pred, y_true)[0]
    rho = spearmanr(y_pred, y_true)[0]
    mae = mean_absolute_error(y_true, y_pred)
    kge_val = kge(y_true, y_pred)
    
    return r, rho, mae, kge_val

train_metrics = Parallel(n_jobs=8)(
    delayed(compute_one_quantile)(i, Y_train_pred_nosort, Y_train_np) for i in range(11)
)
test_metrics = Parallel(n_jobs=8)(
    delayed(compute_one_quantile)(i, Y_test_pred_nosort, Y_test_np) for i in range(11)
)

train_r_coll, train_rho_coll, train_mae_coll, train_kge_coll = zip(*train_metrics)
test_r_coll, test_rho_coll, test_mae_coll, test_kge_coll = zip(*test_metrics)

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)
train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)
train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)
train_kge_all = np.mean(train_kge_coll)
test_kge_all = np.mean(test_kge_coll)

train_r_coll = np.array(train_r_coll).reshape(1, -1)
test_r_coll = np.array(test_r_coll).reshape(1, -1)
train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)
train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)
train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)

train_r_all = np.array([train_r_all]).reshape(1, -1)
test_r_all = np.array([test_r_all]).reshape(1, -1)
train_rho_all = np.array([train_rho_all]).reshape(1, -1)
test_rho_all = np.array([test_rho_all]).reshape(1, -1)
train_mae_all = np.array([train_mae_all]).reshape(1, -1)
test_mae_all = np.array([test_mae_all]).reshape(1, -1)
train_kge_all = np.array([train_kge_all]).reshape(1, -1)
test_kge_all = np.array([test_kge_all]).reshape(1, -1)

initial_array = np.array([[N_EST_I, sample_f, obs_split_i, obs_leaf_i]])

merge_r = np.concatenate((initial_array, train_r_all, test_r_all, train_r_coll, test_r_coll), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge, delimiter=' ', fmt=fmt)

del merge_r, merge_rho, merge_mae, merge_kge
gc.collect()

# ============================================================================
# SAVE FEATURE IMPORTANCES & PREDICTIONS
# ============================================================================

importance = pd.Series(RFreg.feature_importances_.values if hasattr(RFreg.feature_importances_, 'values') 
                       else RFreg.feature_importances_, 
                       index=X_train_column_names)
importance.sort_values(ascending=False, inplace=True)

print('\nTop 20 Final Feature Importances:')
print(importance.head(20))

importance.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',index=True, sep=' ', header=False)

# ✓ MAP PREDICTIONS BACK TO ORIGINAL TEST INDICES
Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_orig_idx[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_orig_idx[:Y_test_pred_nosort.shape[0]])

Y_train_pred_sort = Y_train_pred_indexed.sort_index().values
Y_test_pred_sort = Y_test_pred_indexed.sort_index().values

fmt_pred = '%.2f ' * 11
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt_pred.strip(),  header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort, delimiter=' ', fmt=fmt_pred.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print(f'✓ TRAINING COMPLETE')
print(f'Results saved to:')
print(f'  - Scores: ../predict_score_red/')
print(f'  - Importances: ../predict_importance_red/')
print(f'  - RFECV Ranking: ../predict_importance_red/')
print(f'  - Predictions: ../predict_prediction_red/')
print(f'  - Train/Test splits: ../predict_splitting_red/')

gc.collect()

EOF
"
# close the sif
exit
