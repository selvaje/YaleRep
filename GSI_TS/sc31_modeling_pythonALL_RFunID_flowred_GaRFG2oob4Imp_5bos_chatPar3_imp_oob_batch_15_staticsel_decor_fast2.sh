#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_partial_dataFast2.sh
#SBATCH --array=500
#SBATCH --mem=100G

##### #SBATCH --array=300,400,500,600  200,400 250G  500,600 380G
#### for obs_leaf in 25 50 75 100  ; do for obs_split in 25 50 75 10 ; do for depth in 20 25 30  ;  do for sample in 0.9  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,depth=$depth /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFunID_flowred_GaRFG2oob4Imp_5bos_chatPar3_imp_oob_batch_15_staticsel_decor_fast.sh ; done; done ; done ; done 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export depth=$depth ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"
~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
  --env OMP_NUM_THREADS=1  --env MKL_NUM_THREADS=1  --env OPENBLAS_NUM_THREADS=1  --env NUMEXPR_NUM_THREADS=1 \
  --env obs_leaf=$obs_leaf --env obs_split=$obs_split --env depth=$depth --env sample=$sample --env N_EST=$N_EST \
  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "
python3 <<'EOF'
import os
import gc
import sys
import psutil
import numpy as np
import pandas as pd
from datetime import datetime
from sklearn.model_selection import train_test_split, GroupKFold 
from sklearn.feature_selection import RFECV
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.ensemble import BaseEnsemble
from sklearn.tree import DecisionTreeRegressor
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn import metrics
from sklearn.utils import check_random_state
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy import stats
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed, parallel_backend, dump, load

# ========================================================================
# PARALLELIZATION MONITORING & CONFIGURATION
# ========================================================================
def print_system_info():
    \"\"\"Print system and parallelization configuration info\"\"\"
    print('='*70)
    print('SYSTEM & PARALLELIZATION CONFIGURATION')
    print('='*70)
    print(f'Timestamp: {datetime.now().isoformat()}')
    print(f'Process PID: {os.getpid()}')
    print(f'Total CPU cores available: {os.cpu_count()}')
    print(f'CPU percent: {psutil.cpu_percent(interval=1)}%')
    print(f'Available physical memory: {psutil.virtual_memory().available / 1e9:.2f} GB')
    print(f'Total memory: {psutil.virtual_memory().total / 1e9:.2f} GB')
    print(f'OMP_NUM_THREADS: {os.environ.get("OMP_NUM_THREADS", "not set")}')
    print(f'MKL_NUM_THREADS: {os.environ.get("MKL_NUM_THREADS", "not set")}')
    print(f'OPENBLAS_NUM_THREADS: {os.environ.get("OPENBLAS_NUM_THREADS", "not set")}')
    print(f'NUMEXPR_NUM_THREADS: {os.environ.get("NUMEXPR_NUM_THREADS", "not set")}')
    print('='*70)
    print()

print_system_info()

pd.set_option('display.max_columns', None)  # Show all columns

obs_leaf_s=(os.environ['obs_leaf'])
obs_leaf_i=int(os.environ['obs_leaf'])

obs_split_s=(os.environ['obs_split'])
obs_split_i=int(os.environ['obs_split'])

depth_s=(os.environ['depth'])
depth_i=int(os.environ['depth'])

sample_f=float(os.environ['sample'])
sample_s=str(int(sample_f*100))

N_EST_I=int(os.environ['N_EST'])
N_EST_S=(os.environ['N_EST'])

# Define column data types based on analysis
dtypes_X = {
    # Integer columns
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and spatial data)
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',

    # Integer - Precipitation, temperature, soil, and categorical values
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3',
        'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3',
        'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3',
        'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
        'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack','order_horton','order_shreve','order_strahler','order_topo']},

    # Float - Continuous measurements, spatial metrics
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg','channel_dist_up_cel','channel_dist_up_seg','channel_elv_dw_cel','channel_elv_dw_seg',
        'channel_elv_up_cel','channel_elv_up_seg','channel_grad_dw_seg','channel_grad_up_cel','channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm','accumulation']}
}

# Define column data types
dtypes_Y = {
    # Integer columns
    'IDs': 'int32',
    'IDr': 'int32',
    'YYYY': 'int32',
    'MM': 'int32',

    # Float columns (coordinates and flow values)
    'Xsnap': 'float32',
    'Ysnap': 'float32',
    'Xcoord': 'float32',
    'Ycoord': 'float32',

    # Float - Streamflow quantiles
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']}
}

## for var in $(head -1 stationID_x_y_valueALL_predictors_X11_floredSFD.txt) ; do echo -e \$var ; done | tail  -78  > varX_list.txt 
importance = pd.read_csv('varX_list.txt', header=None, sep='\s+', engine='c', low_memory=False)

include_variables = importance.iloc[:78, 0].tolist()
# Additional columns to add
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']

# Combine the lists
include_variables.extend(additional_columns)

# Read CSV with correct data types 
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt', header=0, sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_X11_floredSFD.txt', header=0, sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

# Ensure X and Y have the same index
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt', sep='\s+' , usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()

# Filter IDr with >5 observations for training
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10 ].index
print(f'Filtered training to {len(valid_idr_train)} stations with >5 observations')

# Ensure unique IDraster values are split while maintaining spatial separation
unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=24).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_
# Filter stations for training, keep all for testing
train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
test_stations = unique_stations[['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=24,
    stratify=train_stations['cluster']
)

X_train = X[X['IDr'].isin(train_rasters['IDr'])]
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])]
X_test =  X[X['IDr'].isin(test_rasters['IDr'])]
Y_test =  Y[Y['IDr'].isin(test_rasters['IDr'])]

print('Training and Testing data')
print('#### X TRAIN ###################')
print(X_train.head(4))
print('#### Y TRAIN ###################')
print(Y_train.head(4))
print('#### X TEST ####################')
print(X_test.head(4))
print('#### Y TEST ####################')
print(Y_test.head(4))
print('################################')
print(X_train.shape)
print(Y_train.shape)
print(X_test.shape)
print(Y_test.shape)

fmt = ' '.join(['%.f'] * (len(include_variables)))
X_column_names = np.array(X.columns)
X_column_names_str = ' '.join(X_column_names)
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', X_train , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='') 
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

#### the X_train and so on are sorted as the input

X_test = X_test.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_test_index = X_test.index.to_numpy()

Y_test = Y_test.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_test_index = Y_test.index.to_numpy()

X_train = X_train.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_train_index = X_train.index.to_numpy()

Y_train = Y_train.sort_values(by=['IDs','IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_train_index = Y_train.index.to_numpy()

print(Y_train.describe())
print(X_train.describe())

print(Y_test.describe())
print(X_test.describe())

fmt='%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names = np.array(Y.columns)     
Y_column_names_str = ' '.join(Y_column_names) 
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')

### contain only IDr + variables and _np are not sorted
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()        ### only this with IDr
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
groups_train = X_train['IDr'].to_numpy()  # only for grouping
X_train_column_names = np.array(X_train.drop(columns=['YYYY', 'MM', 'IDr', 'IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']).columns)

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])


class GroupAwareMultiOutput(BaseEstimator, RegressorMixin):
   
    def __init__(self, base_estimator, n_cv_folds=5, n_jobs=1, inner_n_jobs=1,
                 random_state=24, oob_metric='r2', **kwargs):
        # store parameters exactly (required for sklearn.clone)
        self.base_estimator = base_estimator
        self.n_cv_folds = n_cv_folds
        self.n_jobs = n_jobs
        self.inner_n_jobs = inner_n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.kwargs = kwargs

        # attributes set in fit
        self.models_ = []
        self.oob_predictions_ = None
        self.oob_r2_per_target_ = None
        self.oob_r2_mean_ = None
        self.oob_scores_ = None
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

        n_samples = X.shape[0]
        n_targets = Y.shape[1] if Y.ndim == 2 else 1

        # === Called inside RFECV folds or manual simple fit ===
        if groups is None or (not bool(do_oob_cv)):
            # IMPORTANT: use inner_n_jobs for fold-level fittings to avoid nested parallelism
            final_model = self.base_estimator(random_state=self.random_state,
                                              n_jobs=self.inner_n_jobs,
                                              **self.kwargs)
            final_model.fit(X, Y)
            self.models_ = [final_model]

            # export importance / coef for RFECV importance_getter='auto'
            if hasattr(final_model, 'feature_importances_'):
                self.feature_importances_ = getattr(final_model, 'feature_importances_')
                self.final_importances_ = pd.Series(self.feature_importances_, index=self.X_column_names_).sort_values(ascending=False)
            elif hasattr(final_model, 'coef_'):
                self.coef_ = getattr(final_model, 'coef_')
                self.final_importances_ = None
            else:
                self.final_importances_ = None

            # mark OOB not computed
            self.oob_predictions_ = np.full((n_samples, n_targets), np.nan)
            self.oob_r2_per_target_ = np.array([np.nan] * n_targets)
            self.oob_r2_mean_ = np.nan
            self.oob_scores_ = np.array([np.nan] * n_targets)
            return self

        # === groups provided and do_oob_cv True: compute group-aware OOB via GroupKFold ===
        if self._groups is None or self._groups.size == 0:
            raise ValueError('groups must be provided for group-aware OOB CV')

        gkf = GroupKFold(n_splits=min(self.n_cv_folds, len(np.unique(self._groups))))
        oob_preds = np.full((n_samples, n_targets), np.nan)

        rng = np.random.RandomState(self.random_state)
        seeds = rng.randint(0, 100000, size=gkf.get_n_splits())

        def _fit_fold(train_idx, test_idx, seed):
            est = self.base_estimator(random_state=int(seed),
                                      n_jobs=self.inner_n_jobs,
                                      **self.kwargs)
            est.fit(X[train_idx], Y[train_idx])
            preds = est.predict(X[test_idx])
            return test_idx, preds

        results = Parallel(n_jobs=self.n_jobs)(
            delayed(_fit_fold)(trn, tst, seeds[i])
            for i, (trn, tst) in enumerate(gkf.split(X, y=Y, groups=self._groups))
        )

        for test_idx, preds in results:
            oob_preds[test_idx] = preds

        self.oob_predictions_ = oob_preds

        r2_list = []
        score_list = []
        for i in range(n_targets):
            y_true = Y[:, i]
            y_pred = oob_preds[:, i]
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
                score_list.append(mean_squared_error(y_true[valid], y_pred[valid], squared=False))
            else:
                score_list.append(r2)

        self.oob_r2_per_target_ = np.array(r2_list)
        self.oob_r2_mean_ = np.nanmean(r2_list)
        self.oob_scores_ = np.array(score_list)

        # final model trained on all data: here we can use n_jobs to speed final fit
        final_model = self.base_estimator(random_state=self.random_state,
                                          n_jobs=self.n_jobs,
                                          **self.kwargs)
        final_model.fit(X, Y)
        self.models_ = [final_model]

        if hasattr(final_model, 'feature_importances_'):
            self.feature_importances_ = getattr(final_model, 'feature_importances_')
            self.final_importances_ = pd.Series(self.feature_importances_, index=self.X_column_names_).sort_values(ascending=False)
        elif hasattr(final_model, 'coef_'):
            self.coef_ = getattr(final_model, 'coef_')
            self.final_importances_ = None
        else:
            self.final_importances_ = None

        gc.collect()
        return self

    def predict(self, X):
        if len(self.models_) == 0:
            raise ValueError('Model not fitted.')
        return self.models_[0].predict(X)

    def get_importances(self):
        return self.final_importances_


class GroupAwareRFECV(RFECV):
    
    def __init__(self, estimator, *, step=1, min_features_to_select=1, cv=None,
                 scoring=None, verbose=0, n_jobs=None, importance_getter='auto'):
        cv = cv or GroupKFold(n_splits=5)
        super().__init__(estimator=estimator, step=step, min_features_to_select=min_features_to_select,
                         cv=cv, scoring=scoring, verbose=verbose, n_jobs=n_jobs,
                         importance_getter=importance_getter)

    def fit(self, X, y, groups=None, X_column_names=None):
        if X_column_names is None:
            self.X_column_names_ = [f'feat_{i}' for i in range(np.asarray(X).shape[1])]
        else:
            self.X_column_names_ = list(X_column_names)
        return super().fit(X, y, groups=groups)


# Define base estimator factory for selection (ExtraTrees)
def make_et(**kw):
    return ExtraTreesRegressor(
        n_estimators=N_EST_I,
        max_depth=depth_i,
        min_samples_leaf=obs_leaf_i,
        min_samples_split=obs_split_i,
        max_features=sample_f,
        **kw)

# The estimator used by RFECV
selector_estimator = GroupAwareMultiOutput(
    base_estimator=make_et,
    n_cv_folds=5,
    n_jobs=1,         # keep this 1 to avoid nested parallelism
    inner_n_jobs=1,   # fold-level estimators single-threaded
    random_state=24,
    oob_metric='r2'
)

# RFECV will parallelize across folds; set n_jobs here to number of cores you want for RFECV
# ✅ FIXED: Set to appropriate number of cores (half to leave headroom)
N_JOBS_RFECV = max(1, os.cpu_count() // 2)
print(f'RFECV will use {N_JOBS_RFECV} cores for parallel fold processing')

selector = GroupAwareRFECV(
    estimator=selector_estimator,
    step=0.20,
    min_features_to_select=10,
    scoring='r2',
    n_jobs=N_JOBS_RFECV   # ✅ FIXED: Use appropriate number
)

### Fit RFECV with GroupKFold by passing groups

# ────────────────────────────────────────────────────────────────
# Decorrelation helper function (Spearman based)  ## rho < meno variabili selezionate 
# ────────────────────────────────────────────────────────────────
def decorrelate_group(df, group_name, threshold=0.60, verbose=True):
    if df.empty or len(df.columns) <= 1:
        if verbose and not df.empty:
            print(f' {group_name:20} : {len(df.columns)} vars (no decorrelation needed)')
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
        print(f' {group_name:20} : {len(df.columns):3d} → {len(kept):3d} (ρ > {threshold:.2f})')
    return df[kept]


# Define the static and dynamic variable lists you want to treat specially
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

dinamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# ensure column names array is string dtype
all_cols = X_train_column_names.astype(str)

# compute which static/dynamic vars are actually available
static_present = [c for c in static_var if c in all_cols]
dynamic_present = [c for c in dinamic_var if c in all_cols]

print(f'Found {len(static_present)} static vars present, {len(dynamic_present)} dynamic vars present.')

if len(static_present) == 0:
    # nothing to select from static vars - combine dynamic only
    print('Warning: no static variables found in X_train_column_names. Using dynamic vars only.')
    combined_names = dynamic_present
    final_mask = np.isin(all_cols, combined_names)
    X_train_selected = X_train_np[:, final_mask]
    X_test_selected  = X_test_np[:, final_mask]
    selected_names = all_cols[final_mask]
else:
    # Create station-level representative DataFrame for decorrelation (one row per IDr)
    station_df = pd.DataFrame(X_train_np, columns=all_cols)
    station_df['IDr'] = groups_train
    # keep first row per station as representative (like earlier in your pipeline)
    station_repr = station_df.groupby('IDr', as_index=False)[static_present].first()

    print(f'Performing decorrelation on static variables (station-level aggregation) ...')
    static_dec_df = decorrelate_group(station_repr[static_present], 'Static', threshold=0.60, verbose=True)
    static_decorr = static_dec_df.columns.tolist()
    print(f'Kept {len(static_decorr)} / {len(static_present)} static variables after decorrelation.')
    if len(static_decorr) == 0:
        print('Warning: no static vars left after decorrelation; using dynamic vars only.')
        combined_names = dynamic_present
        final_mask = np.isin(all_cols, combined_names)
        X_train_selected = X_train_np[:, final_mask]
        X_test_selected  = X_test_np[:, final_mask]
        selected_names = all_cols[final_mask]
    else:
        # indices of decorrelated static vars in the full X matrix
        static_idx = np.where(np.isin(all_cols, static_decorr))[0]
        X_static_train = X_train_np[:, static_idx]
        # Run GroupAwareRFECV only on the decorrelated static features
        print(f'Running GroupAwareRFECV on {len(static_decorr)} decorrelated static features...')
        
        # ✅ FIXED: Use parallel_backend with correct n_jobs for RFECV
        with parallel_backend('threading', n_jobs=N_JOBS_RFECV):
            selector.fit(X_static_train, Y_train_np, groups=groups_train, X_column_names=static_decorr)
            # support mask relative to the static (decorrelated) feature set
            support_mask_static = selector.support_
            selected_static_names = np.array(static_decorr)[support_mask_static].tolist()
            print(f'Selected {len(selected_static_names)} static features by RFECV:')
            if len(selected_static_names) <= 60:
                print(', '.join(selected_static_names))
            else:
                print(', '.join(selected_static_names[:60]) + ', ...')

            # Combine selected static variables with all dynamic variables (present in training)
            combined_names = list(selected_static_names) + list(dynamic_present)

            # Build final mask across all columns, preserving original column order
            final_mask = np.isin(all_cols, combined_names)

            # Extract final selected arrays
            X_train_selected = X_train_np[:, final_mask]
            X_test_selected  = X_test_np[:, final_mask]

            # Compose selected_names in the same order as final_mask (so later code sees consistent ordering)
            selected_names = all_cols[final_mask]

# Overwrite the working feature arrays so the rest of the script (which uses X_train_np/X_test_np)
# will automatically operate on the selected feature set without requiring further edits.
X_train_np = X_train_selected
X_test_np  = X_test_selected
X_train_column_names = selected_names  # update column names array used elsewhere

# Print summary
print(f'Final feature set length: {X_train_np.shape[1]}')
print('Final features (first 50):', list(X_train_column_names[:50]))

# ========================================================================
# FINAL MODEL TRAINING WITH FULL PARALLELIZATION
# ========================================================================
# Determine optimal n_jobs for final model
# Use 16 cores if available, otherwise use available cores
N_JOBS_FINAL = os.cpu_count() if os.cpu_count() is not None else 16
print(f'\\nFinal model training will use {N_JOBS_FINAL} cores for OOB CV parallelization')
print(f'Each base estimator (ExtraTreesRegressor) will use {1} thread (inner_n_jobs=1)')
print('='*70)

# Final wrapper: allow parallel folds for OOB (n_jobs) but ensure inner_n_jobs=1 to avoid nested jobs
RFreg = GroupAwareMultiOutput(
    base_estimator=make_et,
    n_cv_folds=5,
    n_jobs=N_JOBS_FINAL,   # ✅ FIXED: Use full cores for OOB fold parallelization
    inner_n_jobs=1,        # ✅ FIXED: Ensure base estimators don't parallelize internally
    random_state=24,
    oob_metric='r2'
)

# ✅ FIXED: REMOVED the conflicting parallel_backend context
# The n_jobs parameter in RFreg will now work correctly
print(f'Starting final model training with GroupKFold OOB validation...')
print(f'Start time: {datetime.now().isoformat()}')

RFreg.fit(X_train_selected, Y_train_np, groups=groups_train,  
          X_column_names=selected_names.tolist(), do_oob_cv=True)

print(f'Finished model training at: {datetime.now().isoformat()}')
print('='*70)

## RFreg.print_oob_summary()

# final feature importances
print('\\nTop 15 features by importance:')
print(RFreg.get_importances().head(15))

# For compatibility with later code:
RFreg.feature_importances_ = RFreg.final_importances_
RFreg.kept_cols_ = selected_names.tolist()
print(f'\\nStarting predictions on test and training sets...')
Y_test_pred_nosort   = RFreg.predict(X_test_np)
Y_train_pred_nosort  = RFreg.predict(X_train_np)

def post_pred_check(Y_true_np, Y_pred_np, name='test'):
    print(f'{name} shapes: true {Y_true_np.shape}, pred {Y_pred_np.shape}')
    if Y_true_np.shape != Y_pred_np.shape:
        raise AssertionError('Shape mismatch between Y_true and Y_pred')
    for i in range(Y_true_np.shape[1]):
        tstd = np.nanstd(Y_true_np[:,i])
        pstd = np.nanstd(Y_pred_np[:,i])
        print(f'{name} col{i} std: true {tstd:.6f}, pred {pstd:.6f}, true NaNs {np.isnan(Y_true_np[:,i]).sum()}, pred NaNs {np.isnan(Y_pred_np[:,i]).sum()}')
        if tstd == 0:
            print('  -> WARNING: true column is constant; Pearson will be NaN.')

post_pred_check(Y_test_np, Y_test_pred_nosort, 'Y_test')
post_pred_check(Y_train_np, Y_train_pred_nosort, 'Y_train')

print(f'\\nCalculating error metrics...')

# Compute Kling-Gupta Efficiency (KGE).
def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]     # Correlation coefficient
    beta = np.mean(y_pred) / np.mean(y_true)  # Bias ratio
    gamma = np.std(y_pred) / np.std(y_true)   # Variability ratio
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

# Calculate Pearson correlation coefficients
train_r_coll = [pearsonr(Y_train_pred_nosort[:, i], Y_train_np[:, i ])[0] for i in range(0, 11)]
test_r_coll  = [pearsonr(Y_test_pred_nosort[:, i], Y_test_np[:, i ])[0] for i in range(0, 11)]

print(train_r_coll)
print(test_r_coll)

train_r_all = np.mean(train_r_coll)
test_r_all = np.mean(test_r_coll)

# Calculate Spearman correlation coefficients
train_rho_coll = [spearmanr(Y_train_pred_nosort[:, i], Y_train_np[:, i ])[0] for i in range(0, 11)]
test_rho_coll = [spearmanr(Y_test_pred_nosort[:, i], Y_test_np[:, i ])[0] for i in range(0, 11)]

train_rho_all = np.mean(train_rho_coll)
test_rho_all = np.mean(test_rho_coll)

# Calculate Mean Absolute Error (MAE)
train_mae_coll = [mean_absolute_error(Y_train_np[:, i ], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_mae_coll = [mean_absolute_error(Y_test_np[:, i ], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_mae_all = np.mean(train_mae_coll)
test_mae_all = np.mean(test_mae_coll)

# Calculate Kling-Gupta Efficiency (KGE)
train_kge_coll = [kge(Y_train_np[:, i ], Y_train_pred_nosort[:, i]) for i in range(0, 11)]
test_kge_coll = [kge(Y_test_np[:, i ], Y_test_pred_nosort[:, i]) for i in range(0, 11)]

train_kge_all = np.mean(train_kge_coll)
test_kge_all = np.mean(test_kge_coll)

# Convert lists to numpy arrays
train_r_coll = np.array(train_r_coll).reshape(1, -1)
test_r_coll = np.array(test_r_coll).reshape(1, -1)

train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)

train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)

train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)

# Reshape the r_all, rho_all, mae_all, and kge_all arrays
train_r_all = np.array(train_r_all).reshape(1, -1)
test_r_all = np.array(test_r_all).reshape(1, -1)

train_rho_all = np.array(train_rho_all).reshape(1, -1)
test_rho_all = np.array(test_rho_all).reshape(1, -1)

train_mae_all = np.array(train_mae_all).reshape(1, -1)
test_mae_all = np.array(test_mae_all).reshape(1, -1)

train_kge_all = np.array(train_kge_all).reshape(1, -1)
test_kge_all = np.array(test_kge_all).reshape(1, -1)

# Prepare metadata for output
obs_leaf_a = np.array(obs_leaf_i).reshape(1, -1)
obs_split_a = np.array(obs_split_i).reshape(1, -1)
sample_a = np.array(sample_f).reshape(1, -1)
N_EST_a = np.array(N_EST_I).reshape(1, -1)

# Create the initial array with metadata
initial_array = np.array([[N_EST_a[0, 0], sample_a[0, 0], obs_split_a[0, 0], obs_leaf_a[0, 0]]])

# Concatenate train and test metrics for r, rho, mae, and kge
merge_r   = np.concatenate((initial_array, train_r_all  , test_r_all  , train_r_coll  , test_r_coll  ), axis=1)
merge_rho = np.concatenate((initial_array, train_rho_all, test_rho_all, train_rho_coll, test_rho_coll), axis=1)
merge_mae = np.concatenate((initial_array, train_mae_all, test_mae_all, train_mae_coll, test_mae_coll), axis=1)
merge_kge = np.concatenate((initial_array, train_kge_all, test_kge_all, train_kge_coll, test_kge_coll), axis=1)

# Define the format strings
fmt = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r.shape[1] - 4))

# Save the results to separate files
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge, delimiter=' ', fmt=fmt)

## Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_train_column_names)
importance.sort_values(ascending=False, inplace=True)
print('\\nFeature importances (all):')
print(importance)

importance.to_csv(rf'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', index=True, sep=' ', header=False)

# Create Pandas DataFrames with the appropriate indices
Y_train_pred_indexed = pd.DataFrame(Y_train_pred_nosort, index=X_train_index[:Y_train_pred_nosort.shape[0]])
Y_test_pred_indexed = pd.DataFrame(Y_test_pred_nosort, index=X_test_index[:Y_test_pred_nosort.shape[0]])

# Sort the DataFrames by index
Y_train_pred_sort = Y_train_pred_indexed.sort_index()
Y_test_pred_sort = Y_test_pred_indexed.sort_index()

# Extract the values as NumPy arrays
Y_train_pred_sort = Y_train_pred_sort.values
Y_test_pred_sort = Y_test_pred_sort.values

del Y_train_pred_indexed, Y_test_pred_indexed
gc.collect()

#### save prediction
print('\\nFinal prediction shapes:')
print(Y_train_pred_sort.shape)            
print(Y_train_pred_sort[:4])        
print(Y_test_pred_sort.shape)  
print(Y_test_pred_sort[:4]) 

fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print(f'\\n{"="*70}')
print(f'SCRIPT COMPLETED SUCCESSFULLY')
print(f'End time: {datetime.now().isoformat()}')
print(f'{"="*70}')

EOF
" ## close the sif
exit