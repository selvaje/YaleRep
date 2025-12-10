#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500
#SBATCH --mem=1200G

##### #SBATCH --array=300,400,500,600     200,400 250G  500,600 380G
#### for obs_leaf in 100  ; do for obs_split in 100 ; do for sample in 0.9  ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFunID_flowred_GaRFG2oob_5bos_chatPar3_imp_oob_batch.sh  ; done; done ; done 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ;  export sample=$sample ; export N_EST=$SLURM_ARRAY_TASK_ID 
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"

~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "


python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.ensemble import BaseEnsemble
from sklearn.tree import DecisionTreeRegressor
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn import metrics
from sklearn.utils import check_random_state
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score
from scipy import stats
from scipy.stats import pearsonr, spearmanr, trim_mean
from joblib import Parallel, delayed, parallel_backend, dump, load

pd.set_option('display.max_columns', None)  # Show all columns

obs_leaf_s=(os.environ['obs_leaf'])
obs_leaf_i=int(os.environ['obs_leaf'])

obs_split_s=(os.environ['obs_split'])
obs_split_i=int(os.environ['obs_split'])

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

importance = pd.read_csv('../extract4py_sample_red/predict_importance_red/importance_sampleAll2.txt', header=None, sep='\s+', engine='c', low_memory=False)
# Extract the second column (index 1) for the first 30 rows

include_variables = importance.iloc[:49, 1].tolist()
# Additional columns to add
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']

# Combine the lists
include_variables.extend(additional_columns)

# Read CSV with correct data types 
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_Y11.txt', header=0,sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_X11.txt', header=0,sep='\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

# Ensure X and Y have the same index
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)



# ============================================================
# STEP 1 — Define temporal and static predictors
# ============================================================
temporal_vars = [
    'ppt0','ppt1','ppt2','ppt3',
    'tmin0','tmin1','tmin2','tmin3',
    'tmax0','tmax1','tmax2','tmax3',
    'swe0','swe1','swe2','swe3',
    'soil0','soil1','soil2','soil3'
]

static_vars = [
    'SNDPPT','SLTPPT','CLYPPT','AWCtS','WWP',
    'sand','silt','clay',
    'GRWLw','GRWLr','GRWLl','GRWLd','GRWLc',
    'channel_curv_cel','channel_dist_dw_seg','channel_dist_up_cel','channel_dist_up_seg',
    'channel_elv_dw_cel','channel_elv_dw_seg','channel_elv_up_cel','channel_elv_up_seg',
    'channel_grad_dw_seg','channel_grad_up_cel','channel_grad_up_seg',
    'outlet_diff_dw_scatch','outlet_dist_dw_scatch',
    'stream_diff_up_farth','stream_diff_up_near','stream_dist_up_farth','stream_dist_up_near',
    'order_hack','order_horton','order_shreve','order_strahler','order_topo',
    'slope_curv_max_dw_cel','slope_curv_min_dw_cel','slope_elv_dw_cel','slope_grad_dw_cel',
    'elev','aspect-cosine','aspect-sine','convergence','dev-magnitude','dev-scale',
    'dx','dxx','dxy','dy','dyy','eastness','elev-stdev','northness','pcurv',
    'rough-magnitude','roughness','rough-scale','slope','tcurv','tpi','tri','vrm',
    'accumulation','cti','spi','sti'
]

additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']

# ============================================================
# STEP 2 — Read input X and Y using dtype maps
# ============================================================
print('Loading full X and Y datasets...')
Y = pd.read_csv(
    'stationID_x_y_valueALL_predictors_Y.txt',
    header=0, sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False
)
X = pd.read_csv(
    'stationID_x_y_valueALL_predictors_X.txt',
    header=0, sep='\s+', dtype=dtypes_X, engine='c', low_memory=False
)
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

print(f'Loaded X: {X.shape}, Y: {Y.shape}')

# ============================================================
# STEP 3 — Aggregate at IDr level for static variable selection
# ============================================================
# Y mean per IDr (streamflow averaged over time)
print('Computing group-level Y means for variable selection...')
Y_mean_by_IDr = Y.groupby('IDr')[[c for c in Y.columns if c.startswith('Q')]].mean()

# Extract X constant vars per IDr (since constant by design)
X_static_by_IDr = X.groupby('IDr')[static_vars].first()  # use first row per IDr

# Align IDs between X and Y summaries
common_idr = X_static_by_IDr.index.intersection(Y_mean_by_IDr.index)
X_static_by_IDr = X_static_by_IDr.loc[common_idr]
Y_mean_by_IDr = Y_mean_by_IDr.loc[common_idr]

print(f'Number of groups used for static feature selection: {len(common_idr)}')

# ============================================================
# STEP 4 — Rank static variables by Spearman correlation with Y (Parallel)
# ============================================================
from joblib import Parallel, delayed

print('Ranking static predictors by Spearman correlation with Y (parallelized)...')

Y_cols = list(Y_mean_by_IDr.columns)
X_cols = list(X_static_by_IDr.columns)

def spearman_for_col(col_name):
    ### Compute mean absolute Spearman correlation between one X variable and all Y quantiles
    x = X_static_by_IDr[col_name].values
    corrs = []
    for qcol in Y_cols:
        y = Y_mean_by_IDr[qcol].values
        rho, _ = spearmanr(x, y)
        if not np.isnan(rho):
            corrs.append(abs(rho))
    return col_name, np.mean(corrs) if corrs else 0.0

# Parallel execution across static predictors
n_jobs_corr = min(16, len(X_cols))  # use ≤16 cores
results = Parallel(n_jobs=n_jobs_corr, backend='loky', verbose=5)(
    delayed(spearman_for_col)(col) for col in X_cols
)

corr_scores = dict(results)
corr_series = pd.Series(corr_scores).sort_values(ascending=False)

print('Top 30 static predictors by |Spearman| correlation:')
print(corr_series.head(30))


# ============================================================
# STEP 5 — Remove redundant highly correlated static variables
# ============================================================
print('Removing redundant static predictors (|r| > 0.9)...')
corr_matrix = X_static_by_IDr[corr_series.index].corr(method='spearman').abs()
upper_tri = corr_matrix.where(np.triu(np.ones(corr_matrix.shape), k=1).astype(bool))
to_drop = [column for column in upper_tri.columns if any(upper_tri[column] > 0.9)]
selected_static_vars = [v for v in corr_series.index if v not in to_drop]
print(f'Selected {len(selected_static_vars)} independent static variables from {len(static_vars)}')

# Keep top-N informative static variables (tunable)
N_STATIC_KEEP = 30
selected_static_vars = selected_static_vars[:N_STATIC_KEEP]
print(f'Keeping top {N_STATIC_KEEP} static variables for training.')

# ============================================================
# STEP 6 — Combine temporal + selected static + meta columns
# ============================================================
include_variables = temporal_vars + selected_static_vars + additional_columns
print(f'Total predictors retained: {len(include_variables) - len(additional_columns)} + meta columns')

# Filter X to these columns
X = X.loc[:, [c for c in include_variables if c in X.columns]]

print(f'Final X shape after variable selection: {X.shape}')

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
X_test = X[X['IDr'].isin(test_rasters['IDr'])]
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'])]

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
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X_train , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', X_test , delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')

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
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt' , Y_test ,  delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')

### contain only IDr + variables and _np are not sorted
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()        ### only this with IDr
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
groups_train = X_train['IDr'].to_numpy()  # only for grouping

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])

# -------------------------------
# Group-Aware Decision Tree
# -------------------------------

class GroupAwareDecisionTree(DecisionTreeRegressor):
    # DecisionTreeRegressor wrapper: accept groups in fit signature, store groups,
    #   and clip negative predictions to zero
    def fit(self, X, y, groups=None, sample_weight=None, check_input=True):
        # store groups (for debugging/inspection)
        self.groups_ = groups
        return super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

    def predict(self, X):
        y_pred = super().predict(X)
        # ensure non-negative outputs
        if np.ndim(y_pred) == 1:
            y_pred = np.clip(y_pred, 0, None)
        else:
            y_pred = np.clip(y_pred, 0, None)
        return y_pred


# -------------------------------
# Group-Aware Random Forest v2 (improved)
# -------------------------------
class GroupAwareRandomForest2:
    def __init__(self,
                 n_estimators=100,
                 max_depth=None,
                 min_samples_split=2,
                 min_samples_leaf=1,
                 max_features='sqrt',
                 bootstrap_frac=0.7,   # sample fraction of each group's rows
                 n_jobs=-1,
                 random_state=None,
                 oob_metric='r2',
                 gc_interval=50,
                 require_sharedmem=True):
        self.n_estimators = int(n_estimators)
        self.max_depth = max_depth
        self.min_samples_split = min_samples_split
        self.min_samples_leaf = min_samples_leaf
        self.max_features = max_features
        self.bootstrap_frac = float(bootstrap_frac)
        self.n_jobs = n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.gc_interval = gc_interval
        self.require_sharedmem = require_sharedmem

        self.estimators_ = []
        self.oob_scores_ = None
        self.feature_importances_ = None
        self.oob_permutation_importances_ = None
        # per-tree metadata for debugging
        self._trees_oob_idx = None

    # ---- single-tree fit function ----
    def _fit_single_tree(self, X, y, groups, seed, tree_idx):
        rng = np.random.default_rng(seed)
        n_samples = X.shape[0]

        # group-aware bootstrap: sample groups with replacement, then sample fraction of rows inside each group
        if groups is not None:
            unique_groups = np.unique(groups)
            # sample same number of groups as unique groups to mimic bootstrap at group-level
            sampled_groups = rng.choice(unique_groups, size=len(unique_groups), replace=True)
            train_idx_parts = []
            for g in sampled_groups:
                g_idx = np.where(groups == g)[0]
                # sample a fraction of rows inside the group (with replacement)
                n_group_samples = max(1, int(np.ceil(len(g_idx) * self.bootstrap_frac)))
                sampled_idx = rng.choice(g_idx, size=n_group_samples, replace=True)
                train_idx_parts.append(sampled_idx)
            train_idx = np.hstack(train_idx_parts).astype(int)
        else:
            train_idx = rng.choice(n_samples, n_samples, replace=True).astype(int)

        # OOB are indices not in train_idx
        oob_idx = np.setdiff1d(np.arange(n_samples, dtype=int), np.unique(train_idx), assume_unique=False)

        X_boot = X[train_idx]
        y_boot = y[train_idx]

        # create tree with reproducible seed
        tree_seed = int(rng.integers(0, 2**31 - 1))
        tree = GroupAwareDecisionTree(
            max_depth=self.max_depth,
            min_samples_split=self.min_samples_split,
            min_samples_leaf=self.min_samples_leaf,
            max_features=self.max_features,
            random_state=tree_seed
        )
        # Fit the tree (no groups passed to sklearn's DecisionTree internals)
        tree.fit(X_boot, y_boot)

        # cleanup
        del X_boot, y_boot, train_idx_parts, train_idx
        if tree_idx % max(1, self.gc_interval) == 0:
            gc.collect()

        return tree, oob_idx

    # ---- fit forest in parallel ----
    def fit(self, X, y, groups=None):
        X = np.asarray(X)
        y = np.asarray(y)
        n_samples = X.shape[0]

        rng_master = np.random.default_rng(self.random_state)
        seeds = rng_master.integers(0, 2**31 - 1, size=self.n_estimators)

        # parallel tree building
        parallel = Parallel(n_jobs=self.n_jobs, require='sharedmem' if self.require_sharedmem else None)
        results = parallel(
            delayed(self._fit_single_tree)(X, y, groups, int(seeds[i]), i)
            for i in range(self.n_estimators)
        )

        # Unpack
        self.estimators_, all_oob_idx = zip(*results)
        # store OOB indices per tree for later permutation importance
        self._trees_oob_idx = list(all_oob_idx)

        # ---- compute OOB predictions (group-aware) ----
        if self.oob_metric is not None:
            if y.ndim == 1:
                y = y[:, None]

            preds_sum = np.zeros_like(y, dtype=float)
            preds_count = np.zeros((y.shape[0],), dtype=int)

            # For memory, process each tree: compute predictions on its OOB indices and accumulate.
            for tree, oob_idx in zip(self.estimators_, self._trees_oob_idx):
                if oob_idx is None or len(oob_idx) == 0:
                    continue
                preds = tree.predict(X[oob_idx])
                if preds.ndim == 1:
                    preds = preds[:, None]
                preds_sum[oob_idx] += preds
                preds_count[oob_idx] += 1

            mask = preds_count > 0
            if np.any(mask):
                # build oob_preds array for rows that had at least one OOB prediction
                oob_preds = np.zeros_like(y, dtype=float)
                oob_preds[mask] = preds_sum[mask] / preds_count[mask][:, None]

                # compute global and per-output R2 using only rows that have OOB preds
                idx_mask = np.where(mask)[0]
                if len(idx_mask) > 0:
                    # global R2 (multioutput average)
                    try:
                        global_r2 = r2_score(y[idx_mask], oob_preds[idx_mask], multioutput='uniform_average')
                        per_output_r2 = [r2_score(y[idx_mask, j], oob_preds[idx_mask, j]) for j in range(y.shape[1])]
                        self.oob_scores_ = [global_r2] + per_output_r2
                    except Exception:
                        self.oob_scores_ = None
                else:
                    self.oob_scores_ = None
            else:
                self.oob_scores_ = None
        else:
            self.oob_scores_ = None

        # ---- tree-based feature importance ----
        # average over trees (trees are sklearn DecisionTreeRegressor with .feature_importances_)
        importances = np.zeros(X.shape[1], dtype=float)
        for tree in self.estimators_:
            importances += getattr(tree, 'feature_importances_', np.zeros(X.shape[1], dtype=float))
        self.feature_importances_ = importances / float(self.n_estimators)

        # ---- OOB permutation importance (optional and more informative for temporal vars) ----
        # We'll compute perm importance using only OOB predictions (this is slower but robust).
        try:
            # build base OOB predictions once (for rows with any OOB preds)
            if self.oob_scores_ is not None:
                # create base oob_preds as above (mask and oob_preds)
                preds_sum = np.zeros_like(y, dtype=float)
                preds_count = np.zeros((y.shape[0],), dtype=int)
                for tree, oob_idx in zip(self.estimators_, self._trees_oob_idx):
                    if oob_idx is None or len(oob_idx) == 0:
                        continue
                    preds = tree.predict(X[oob_idx])
                    if preds.ndim == 1:
                        preds = preds[:, None]
                    preds_sum[oob_idx] += preds
                    preds_count[oob_idx] += 1
                mask = preds_count > 0
                if np.any(mask):
                    oob_preds_base = np.zeros_like(y, dtype=float)
                    oob_preds_base[mask] = preds_sum[mask] / preds_count[mask][:, None]
                    # baseline metric
                    idx_mask = np.where(mask)[0]
                    baseline_global = None
                    try:
                        baseline_global = r2_score(y[idx_mask], oob_preds_base[idx_mask], multioutput='uniform_average')
                    except Exception:
                        baseline_global = np.nan

                    # permute each feature and compute drop in metric (use small sample of rows if large)
                    n_features = X.shape[1]
                    perm_importances = np.zeros(n_features, dtype=float)
                    # choose OOB rows indices to use (all mask rows)
                    use_idx = idx_mask
                    for feat in range(n_features):
                        X_perm = X.copy()
                        X_perm[use_idx, feat] = rng_master.permutation(X_perm[use_idx, feat])
                        # recompute OOB preds for permuted feature using trees as before
                        preds_sum_perm = np.zeros_like(y, dtype=float)
                        preds_count_perm = np.zeros((y.shape[0],), dtype=int)
                        for tree, oob_idx in zip(self.estimators_, self._trees_oob_idx):
                            if oob_idx is None or len(oob_idx) == 0:
                                continue
                            preds = tree.predict(X_perm[oob_idx])
                            if preds.ndim == 1:
                                preds = preds[:, None]
                            preds_sum_perm[oob_idx] += preds
                            preds_count_perm[oob_idx] += 1
                        mask_perm = preds_count_perm > 0
                        if np.any(mask_perm):
                            oob_preds_perm = np.zeros_like(y, dtype=float)
                            oob_preds_perm[mask_perm] = preds_sum_perm[mask_perm] / preds_count_perm[mask_perm][:, None]
                            idx_mask_perm = np.where(mask_perm)[0]
                            try:
                                perm_global = r2_score(y[idx_mask_perm], oob_preds_perm[idx_mask_perm], multioutput='uniform_average')
                            except Exception:
                                perm_global = np.nan
                            # importance = baseline - permuted score (bigger => more important)
                            perm_importances[feat] = (baseline_global - perm_global) if (not np.isnan(baseline_global) and not np.isnan(perm_global)) else 0.0
                        else:
                            perm_importances[feat] = 0.0
                        # free memory
                        del X_perm, preds_sum_perm, preds_count_perm, oob_preds_perm
                        if feat % max(1, self.gc_interval) == 0:
                            gc.collect()
                    self.oob_permutation_importances_ = perm_importances
                else:
                    self.oob_permutation_importances_ = None
            else:
                self.oob_permutation_importances_ = None
        except Exception:
            # if permutation importance fails due to memory/time, set None
            self.oob_permutation_importances_ = None

        # final cleanup
        gc.collect()
        return self

    # ---- parallel predict ----
    def predict(self, X, agg='mean'):
        X = np.asarray(X)
        # compute predictions from each tree in parallel
        parallel = Parallel(n_jobs=self.n_jobs, require='sharedmem' if self.require_sharedmem else None)
        preds_per_tree = parallel(delayed(tree.predict)(X) for tree in self.estimators_)
        preds_per_tree = np.array(preds_per_tree)  # shape (n_trees, n_samples, n_outputs?) or (n_trees, n_samples)
        # if output is 2D per tree
        if preds_per_tree.ndim == 3:
            if agg == 'mean':
                y_pred = np.mean(preds_per_tree, axis=0)
            elif agg == 'median':
                y_pred = np.median(preds_per_tree, axis=0)
            else:
                y_pred = np.mean(preds_per_tree, axis=0)
        else:
            # preds_per_tree shape (n_trees, n_samples)
            if agg == 'mean':
                y_pred = np.mean(preds_per_tree, axis=0)
            elif agg == 'median':
                y_pred = np.median(preds_per_tree, axis=0)
            else:
                y_pred = np.mean(preds_per_tree, axis=0)
        y_pred = np.clip(y_pred, 0, None)
        gc.collect()
        return y_pred

RFreg = GroupAwareRandomForest2(
    n_estimators = N_EST_I,       # your SLURM array id, or fixed int like 200
    max_depth = 15,
    min_samples_split = obs_split_i,
    min_samples_leaf = obs_leaf_i,
    max_features = 'sqrt',
    bootstrap_frac = 0.7,          # sample 70% of rows inside each sampled group
    n_jobs = -1,
    random_state = 42,
    oob_metric = 'r2',
    gc_interval = 50,
    require_sharedmem = True
)


print('Fit RF on the training') 
RFreg.fit(X_train_np, Y_train_np , groups=groups_train )

print('General OOB r2:',   RFreg.oob_scores_[0] )
print('OOB per quantile:', RFreg.oob_scores_[1:])  # [QMIN, Q10, ..., QMAX]

# Make predictions on the training data
Y_train_pred_nosort = RFreg.predict(X_train_np, agg='mean')
Y_test_pred_nosort  = RFreg.predict(X_test_np, agg='mean')

#  Calculate error matrix 

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
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_GaRFG.txt', merge_r, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_GaRFG.txt', merge_rho, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_GaRFG.txt', merge_mae, delimiter=' ', fmt=fmt)
np.savetxt(rf'../predict_score_red/stationID_x_y_valueALL_predictors_YscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_GaRFG.txt', merge_kge, delimiter=' ', fmt=fmt)

## Get feature importances and sort them in descending order     

importance = pd.Series(RFreg.feature_importances_, index=X_column_names[8:])
importance.sort_values(ascending=False, inplace=True)
print(importance)

importance.to_csv(rf'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', index=True, sep=' ', header=False)

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
print(Y_train_pred_sort.shape)            
print(Y_train_pred_sort[:4])        
print(Y_test_pred_sort.shape)  
print(Y_test_pred_sort[:4]) 

fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{sample_s}sample_2RF.txt', Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

EOF
" ## close the sif
exit

