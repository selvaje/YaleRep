#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_%A_%a.err
#SBATCH --job-name=sc31_fast
#SBATCH --array=500
#SBATCH --mem=100G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv

export obs_leaf=$obs_leaf
export obs_split=$obs_split
export sample=$sample
export depth=$depth
export N_EST=$SLURM_ARRAY_TASK_ID

echo "Parameters: n_est=${N_EST} leaf=${obs_leaf} split=${obs_split} depth=${depth} sample=${sample}"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
  --env OMP_NUM_THREADS=1 --env MKL_NUM_THREADS=1 --env OPENBLAS_NUM_THREADS=1 --env NUMEXPR_NUM_THREADS=1 \
  --env obs_leaf=$obs_leaf --env obs_split=$obs_split --env depth=$depth --env sample=$sample --env N_EST=$N_EST \
  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif bash -c "
python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GroupKFold
from sklearn.feature_selection import RFECV
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed, parallel_backend, dump, load
import warnings
warnings.filterwarnings('ignore')

pd.set_option('display.max_columns', None)

# ============================================================================
# PARAMETER SETUP
# ============================================================================
obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_i = int(os.environ['obs_split'])
depth_i = int(os.environ['depth'])
sample_f = float(os.environ['sample'])
N_EST_I = int(os.environ['N_EST'])
obs_leaf_s = str(obs_leaf_i)
obs_split_s = str(obs_split_i)
depth_s = str(depth_i)
sample_s = str(int(sample_f*100))
N_EST_S = str(N_EST_I)

print(f'Job parameters: n_est={N_EST_S}, leaf={obs_leaf_s}, split={obs_split_s}, depth={depth_s}, sample={sample_s}')

# ============================================================================
# DATA TYPE DEFINITIONS (Reduced memory footprint)
# ============================================================================
dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int16', 'MM': 'int8',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int16' for col in ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3',
                                  'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3',
                                  'soil0', 'soil1', 'soil2', 'soil3']},
    **{col: 'float32' for col in ['cti', 'spi', 'sti', 'slope', 'elev', 'accumulation']}
}

# ============================================================================
# LOAD DATA WITH MEMORY OPTIMIZATION
# ============================================================================
print('Loading X data...')
X = pd.read_csv('stationID_x_y_valueALL_predictors_X11_floredSFD.txt', 
                 sep='\s+', dtype=dtypes_X, engine='c', low_memory=False)

print('Loading Y data...')
Y = pd.read_csv('stationID_x_y_valueALL_predictors_Y11_floredSFD.txt',
                 sep='\s+', engine='c', low_memory=False)

# Align indices
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

print(f'Data loaded: X={X.shape}, Y={Y.shape}')

# ============================================================================
# STATION-LEVEL FILTERING & TRAIN/TEST SPLIT
# ============================================================================
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
                        sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

# Count observations per station
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index.tolist()
print(f'Stations with >10 observations: {len(valid_idr_train)}')

# Spatial clustering for stratified split
unique_stations = stations[stations['IDr'].isin(valid_idr_train)].copy()
kmeans = KMeans(n_clusters=min(20, len(unique_stations)//10), random_state=24, n_init=10)
unique_stations['cluster'] = kmeans.fit_predict(unique_stations[['Xcoord', 'Ycoord']])

train_stations, test_stations = train_test_split(
    unique_stations,
    test_size=0.2,
    random_state=24,
    stratify=unique_stations['cluster']
)

# Split data
train_idx = X['IDr'].isin(train_stations['IDr'].tolist())
test_idx = X['IDr'].isin(test_stations['IDr'].tolist())

X_train = X[train_idx].copy()
Y_train = Y[train_idx].copy()
X_test = X[test_idx].copy()
Y_test = Y[test_idx].copy()

groups_train = X_train['IDr'].values
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).values
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).values
X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).values
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).values

X_column_names = np.array(X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).columns)

print(f'Train: X={X_train_np.shape}, Y={Y_train_np.shape}')
print(f'Test: X={X_test_np.shape}, Y={Y_test_np.shape}')

# Clean up
del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

# ============================================================================
# MULTIOUTPUT WRAPPER CLASS
# ============================================================================
class GroupAwareMultiOutput(BaseEstimator, RegressorMixin):
    def __init__(self, base_estimator, n_cv_folds=5, n_jobs=1, inner_n_jobs=1,
                 random_state=24, oob_metric='r2', **kwargs):
        self.base_estimator = base_estimator
        self.n_cv_folds = n_cv_folds
        self.n_jobs = n_jobs
        self.inner_n_jobs = inner_n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.kwargs = kwargs
        self.models_ = []
        self.oob_predictions_ = None
        self.oob_r2_per_target_ = None
        self.oob_r2_mean_ = None
        self.final_importances_ = None
        self._groups = None
        self.X_column_names_ = None

    def fit(self, X, Y, groups=None, X_column_names=None, do_oob_cv=True):
        X = np.asarray(X)
        Y = np.asarray(Y)

        if X_column_names is None:
            X_column_names = [f'feat_{i}' for i in range(X.shape[1])]
        self.X_column_names_ = list(X_column_names)

        if groups is not None:
            self._groups = np.asarray(groups)

        n_samples, n_targets = X.shape[0], (Y.shape[1] if Y.ndim == 2 else 1)

        # Fit final model
        final_model = self.base_estimator(random_state=self.random_state,
                                          n_jobs=self.inner_n_jobs, **self.kwargs)
        final_model.fit(X, Y)
        self.models_ = [final_model]

        # Extract importances
        if hasattr(final_model, 'feature_importances_'):
            self.feature_importances_ = final_model.feature_importances_
            self.final_importances_ = pd.Series(self.feature_importances_, 
                                                index=self.X_column_names_).sort_values(ascending=False)

        # Compute OOB predictions if requested
        if groups is not None and do_oob_cv:
            gkf = GroupKFold(n_splits=min(self.n_cv_folds, len(np.unique(groups))))
            oob_preds = np.full((n_samples, n_targets), np.nan)
            
            rng = np.random.RandomState(self.random_state)
            seeds = rng.randint(0, 100000, size=gkf.get_n_splits())
            
            def _fit_fold(train_idx, test_idx, seed):
                est = self.base_estimator(random_state=int(seed), 
                                         n_jobs=self.inner_n_jobs, **self.kwargs)
                est.fit(X[train_idx], Y[train_idx])
                preds = est.predict(X[test_idx])
                return test_idx, preds
            
            results = Parallel(n_jobs=self.n_jobs)(
                delayed(_fit_fold)(trn, tst, seeds[i])
                for i, (trn, tst) in enumerate(gkf.split(X, y=Y, groups=groups))
            )
            
            for test_idx, preds in results:
                oob_preds[test_idx] = preds
            
            self.oob_predictions_ = oob_preds
            
            # Compute R2 scores
            r2_list = []
            for i in range(n_targets):
                y_true = Y[:, i]
                y_pred = oob_preds[:, i]
                valid = ~np.isnan(y_pred)
                if valid.sum() > 1:
                    r2_list.append(r2_score(y_true[valid], y_pred[valid]))
                else:
                    r2_list.append(np.nan)
            
            self.oob_r2_per_target_ = np.array(r2_list)
            self.oob_r2_mean_ = np.nanmean(r2_list)
        else:
            self.oob_predictions_ = np.full((n_samples, n_targets), np.nan)
            self.oob_r2_per_target_ = np.array([np.nan] * n_targets)
            self.oob_r2_mean_ = np.nan

        return self

    def predict(self, X):
        if len(self.models_) == 0:
            raise ValueError('Model not fitted.')
        return self.models_[0].predict(X)

    def get_importances(self):
        return self.final_importances_


# ============================================================================
# FEATURE ENGINEERING: STATIC/DYNAMIC SEPARATION
# ============================================================================
static_var = ['cti', 'spi', 'sti', 'accumulation', 'slope', 'elev']  # Simplified list
dynamic_var = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3',
               'tmax0', 'tmax1', 'tmax2', 'tmax3', 'swe0', 'swe1', 'swe2', 'swe3',
               'soil0', 'soil1', 'soil2', 'soil3']

static_present = [c for c in static_var if c in X_column_names]
dynamic_present = [c for c in dynamic_var if c in X_column_names]

print(f'Static features: {len(static_present)}, Dynamic features: {len(dynamic_present)}')

# ============================================================================
# DECORRELATION FUNCTION
# ============================================================================
def decorrelate_group(df, group_name, threshold=0.60, verbose=True):
    if df.empty or len(df.columns) <= 1:
        if verbose and not df.empty:
            print(f'{group_name:20s}: {len(df.columns)} vars (no decorrelation)')
        return df
    
    corr = df.corr(method='spearman').abs()
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))
    to_drop = set()
    
    for col in upper.columns:
        if upper[col].max() > threshold:
            high_corr_vars = [col] + upper.index[upper[col] > threshold].tolist()
            if len(high_corr_vars) > 1:
                mean_corr = corr.loc[high_corr_vars, high_corr_vars].mean(axis=1)
                keep = mean_corr.idxmax()
                to_drop.update(v for v in high_corr_vars if v != keep)
    
    kept = [c for c in df.columns if c not in to_drop]
    if verbose:
        print(f'{group_name:20s}: {len(df.columns):3d} → {len(kept):3d} (ρ > {threshold:.2f})')
    
    return df[kept]


# ============================================================================
# MODEL TRAINING WITH PROPER PARALLELIZATION
# ============================================================================
def make_et(**kw):
    return ExtraTreesRegressor(
        n_estimators=N_EST_I,
        max_depth=depth_i,
        min_samples_leaf=obs_leaf_i,
        min_samples_split=obs_split_i,
        max_features=sample_f,
        n_jobs=1,  # IMPORTANT: Set to 1 to avoid nested parallelism
        random_state=24,
        **kw
    )

# Final model training
print('Training final model...')
RFreg = GroupAwareMultiOutput(
    base_estimator=make_et,
    n_cv_folds=5,
    n_jobs=16,  # Parallelize across CV folds ONLY
    inner_n_jobs=1,  # Tree training uses 1 thread each
    random_state=24,
    oob_metric='r2'
)

# IMPORTANT: Use sequential context when fitting
with parallel_backend('threading', n_jobs=1):
    RFreg.fit(X_train_np, Y_train_np, groups=groups_train,
              X_column_names=X_column_names.tolist(), do_oob_cv=True)

print(f'OOB R² mean: {RFreg.oob_r2_mean_:.4f}')

# ============================================================================
# PREDICTIONS
# ============================================================================
print('Generating predictions...')
Y_train_pred = RFreg.predict(X_train_np)
Y_test_pred = RFreg.predict(X_test_np)

# ============================================================================
# EVALUATION METRICS
# ============================================================================
def kge(y_true, y_pred):
    # Kling-Gupta Efficiency
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true)
    gamma = np.std(y_pred) / np.std(y_true)
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

# Compute metrics
test_r_all = np.mean([pearsonr(Y_test_pred[:, i], Y_test_np[:, i])[0] 
                      for i in range(Y_test_np.shape[1])])
test_mae_all = np.mean([mean_absolute_error(Y_test_np[:, i], Y_test_pred[:, i]) 
                        for i in range(Y_test_np.shape[1])])

print(f'Test Pearson r: {test_r_all:.4f}')
print(f'Test MAE: {test_mae_all:.4f}')

# Save predictions
np.savetxt(f'../predict_prediction_red/YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample.txt',
           Y_test_pred, delimiter=' ', fmt='%.2f')

print('✓ Script completed successfully')

EOF
" ## close apptainer
exit
