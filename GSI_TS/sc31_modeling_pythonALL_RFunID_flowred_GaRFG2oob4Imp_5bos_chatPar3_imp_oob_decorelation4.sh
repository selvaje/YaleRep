#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --array=500
#SBATCH --mem=500G
##### SBATCH --array=300,400,500,600 200,400 250G 500,600 380G
#### for obs_leaf in 25 50 75 100 ; do for obs_split in 25 50 75 10 ; do for depth in 20 25 30 ; do for sample in 0.9 ; do sbatch --export=obs_leaf=$obs_leaf,obs_split=$obs_split,sample=$sample,depth=$depth /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc31_modeling_pythonALL_RFunID_flowred_GaRFG2oob4Imp_5bos_chatPar3_imp_oob_decorelation.sh ; done; done ; done ; done
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT
module load StdEnv
# export obs=50
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ; export sample=$sample ; export depth=$depth ; export N_EST=$SLURM_ARRAY_TASK_ID
echo "obs_leaf $obs_leaf obs_split $obs_split depth $depth sample $sample n_estimators $N_EST"
~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth "
echo "start python modeling"
apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf=$obs_leaf,obs_split=$obs_split,depth=$depth,sample=$sample,N_EST=$N_EST /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif bash -c "
python3 <<'EOF'
import os
import gc
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, GroupKFold
from sklearn.ensemble import RandomForestRegressor, ExtraTreesRegressor, BaseEnsemble
from sklearn.base import RegressorMixin, BaseEstimator, clone
from sklearn.preprocessing import QuantileTransformer
from sklearn.feature_selection import RFECV
from sklearn.tree import DecisionTreeRegressor
from sklearn.pipeline import Pipeline
from sklearn.cluster import KMeans
from sklearn import metrics
from sklearn.utils import check_random_state
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score, make_scorer 
from sklearn.utils.validation import check_X_y, check_array
from scipy import stats
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed, parallel_backend, dump, load
pd.set_option('display.max_columns', None) # Show all columns
obs_leaf_s = (os.environ['obs_leaf'])
obs_leaf_i = int(os.environ['obs_leaf'])
obs_split_s = (os.environ['obs_split'])
obs_split_i = int(os.environ['obs_split'])
depth_s = (os.environ['depth'])
depth_i = int(os.environ['depth'])
sample_f = float(os.environ['sample'])
sample_s = str(int(sample_f * 100))
N_EST_I = int(os.environ['N_EST'])
N_EST_S = (os.environ['N_EST'])
# ────────────────────────────────────────────────────────────────
# Define thematic variable groups for decorrelation
# ────────────────────────────────────────────────────────────────
accumulation_vars = ['cti', 'spi', 'sti', 'accumulation']
hydrography_vars = [
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel',
    'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg',
    'channel_elv_up_cel', 'channel_elv_up_seg',
    'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
]
geomorpho_vars = [
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]
# ────────────────────────────────────────────────────────────────
# Decorrelation helper function (Spearman based)
# ────────────────────────────────────────────────────────────────
def decorrelate_group(df, group_name, threshold=0.70, verbose=True):
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
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo']},
    # Float - Continuous measurements, spatial metrics
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
        'channel_elv_dw_cel', 'channel_elv_dw_seg',
        'channel_elv_up_cel', 'channel_elv_up_seg', 'channel_grad_dw_seg',
        'channel_grad_up_cel', 'channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation']}
}
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
importance = pd.read_csv('../extract4py_sample_red/predict_importance_red/importance_sampleAll.txt',
                         header=None, sep='\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:86, 1].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)
Y = pd.read_csv(rf'stationID_x_y_valueALL_predictors_Y.txt',
                header=0, sep='\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(rf'stationID_x_y_valueALL_predictors_X.txt',
                header=0, sep='\s+', usecols=lambda col: col in include_variables,
                dtype=dtypes_X, engine='c', low_memory=False)
X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)
target_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
id_cols = ['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']
Y_targets = Y[target_cols] + 1
Y_ids = Y[id_cols].reset_index(drop=True)
Y = pd.concat([Y_ids, Y_targets], axis=1)
# =============================================================================
# DECORRELATION BASED ON STATION-LEVEL AGGREGATION (one row per IDr)
# =============================================================================
always_keep = [
    'IDs', 'Xsnap', 'Ysnap', 'IDr', 'Xcoord', 'Ycoord',
    'YYYY', 'MM',
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
    'SNDPPT', 'SLTPPT', 'CLYPPT', 'AWCtS', 'WWP',
    'sand', 'silt', 'clay',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc'
]
always_keep = [col for col in always_keep if col in X.columns]
print(f'→ Number of forced keep columns: {len(always_keep)}')
predictor_cols = list(X.columns)
print('\nCreating station-level representative table...')
station_df = X.groupby('IDr', as_index=False)[predictor_cols].first()
print(f'→ Number of unique stations (IDr): {len(station_df)}')
print(f'→ Station-level shape: {station_df.shape}\n')
station_X = station_df[predictor_cols].copy()
print('Performing intra-group decorrelation (Spearman ρ > 0.70):')
accu_dec = decorrelate_group(
    station_X[[c for c in accumulation_vars if c in station_X.columns]],
    'Accumulation', threshold=0.70
)
hydro_dec = decorrelate_group(
    station_X[[c for c in hydrography_vars if c in station_X.columns]],
    'Hydrography', threshold=0.70
)
geomo_dec = decorrelate_group(
    station_X[[c for c in geomorpho_vars if c in station_X.columns]],
    'Geomorphology', threshold=0.70
)
kept_features = (
    accu_dec.columns.to_list() +
    hydro_dec.columns.to_list() +
    geomo_dec.columns.to_list()
)
kept_features = list(dict.fromkeys(kept_features))
print(f'\nFinal number of selected decorrelated features: {len(kept_features)}')
print('\nSelected variables by group:')
for name, orig_list, dec_df in [
    ('Accumulation', accumulation_vars, accu_dec),
    ('Hydrography', hydrography_vars, hydro_dec),
    ('Geomorphology', geomorpho_vars, geomo_dec),
]:
    selected = [v for v in orig_list if v in kept_features]
    selected_str = ' '.join(selected) or '(none)'
    print(f' {name:14} : {len(selected):2d}/{len(orig_list):2d} → {selected_str}')
print('\n' + '='*90 + '\n')
print('Creating X_dec with selected features + identifier/time/climate/soil columns...')
final_columns = list(dict.fromkeys(kept_features + always_keep))
missing = [col for col in always_keep if col not in X.columns]
if missing:
    print(f'Warning: the following columns were not found in X and will be skipped: {missing}')
X_dec = X[final_columns].copy()
print(f'→ Original X shape: {X.shape}')
print(f'→ Decorrelated X_dec shape: {X_dec.shape}')
print(f'→ Total columns in X_dec: {len(final_columns)} '
      f'({len(kept_features)} selected + {len(always_keep) - len(missing)} forced keep)')
print('\n→ First few columns in X_dec:', X_dec.columns[:8].to_list(), '...')
print('\n→ X_dec is ready to use for train/test splitting\n')
print('#### Y ###################')
print(Y.head(4))
gc.collect()
stations = pd.read_csv('/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
                       sep='\s+', usecols=['IDr', 'Xcoord', 'Ycoord']).drop_duplicates()
counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index
print(f'Filtered training to {len(valid_idr_train)} stations with >5 observations')
unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=24).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_
train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
test_stations = unique_stations[['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=24,
    stratify=train_stations['cluster']
)
X_train = X_dec[X_dec['IDr'].isin(train_rasters['IDr'])]
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])]
X_test = X_dec[X_dec['IDr'].isin(test_rasters['IDr'])]
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
X_column_names = list(X_train.columns)
X_column_names_str = ' '.join(X_column_names)
fmt = ' '.join(['%f'] * len(X_column_names))
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',X_train, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_XTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', X_test, delimiter=' ', fmt=fmt, header=X_column_names_str, comments='')
X_test = X_test.sort_values(by=['IDs', 'IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_test_index = X_test.index.to_numpy()
Y_test = Y_test.sort_values(by=['IDs', 'IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_test_index = Y_test.index.to_numpy()
X_train = X_train.sort_values(by=['IDs', 'IDr', 'YYYY', 'MM']).reset_index(drop=True)
X_train_index = X_train.index.to_numpy()
Y_train = Y_train.sort_values(by=['IDs', 'IDr', 'YYYY', 'MM']).reset_index(drop=True)
Y_train_index = Y_train.index.to_numpy()
print(Y_train.describe())
print(X_train.describe())
print(Y_test.describe())
print(X_test.describe())
fmt = '%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names = list(Y.columns) # fixed
Y_column_names_str = ' '.join(Y_column_names)
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
           Y_train, delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
np.savetxt(rf'../predict_splitting_red/stationID_x_y_valueALL_predictors_YTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
           Y_test, delimiter=' ', fmt=fmt, header=Y_column_names_str, comments='')
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()
X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']).to_numpy()
groups_train = X_train['IDr'].to_numpy()
X_train_column_names = X_train.drop(
    columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM', 'IDr']
).columns.to_list() # fixed
del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()
print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])
##########################

class GroupAwareMultiOutput(BaseEstimator, RegressorMixin):
    def __init__(
        self,
        base_estimator=None,
        n_cv_folds=5,
        n_jobs=-1,
        random_state=24,
        oob_metric='r2',
        **kwargs
    ):
        self.base_estimator = base_estimator
        self.n_cv_folds = n_cv_folds
        self.n_jobs = n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.kwargs = kwargs

    def _fit_fold(self, X, Y, train_idx, test_idx, seed, X_column_names):
        model = self.base_estimator(random_state=seed, n_jobs=self.n_jobs, **self.kwargs)
        model.fit(X[train_idx], Y[train_idx])
        preds = model.predict(X[test_idx])
        imp = pd.Series(model.feature_importances_, index=X_column_names)
        return test_idx, preds, imp

    def fit(self, X, Y, groups=None, X_column_names=None):
        X, Y = check_X_y(X, Y, multi_output=True)
        if groups is None:
            raise ValueError('groups must be provided for GroupKFold (e.g., from \'IDr\').')
        if X_column_names is None:
            X_column_names = [f'feat_{i}' for i in range(X.shape[1])]

        n_targets = Y.shape[1] if Y.ndim > 1 else 1

        oob_metric_lower = self.oob_metric.lower()

        gkf = GroupKFold(n_splits=min(self.n_cv_folds, len(np.unique(groups))))
        oob_preds = np.full_like(Y, np.nan, dtype=float)
        importances = []

        seeds = np.random.RandomState(self.random_state).randint(0, 10000, size=gkf.get_n_splits())

        results = Parallel(n_jobs=self.n_jobs)(
            delayed(self._fit_fold)(X, Y, train_idx, test_idx, seeds[i], X_column_names)
            for i, (train_idx, test_idx) in enumerate(gkf.split(X, groups=groups))
        )

        for test_idx, preds, imp in results:
            oob_preds[test_idx] = preds
            importances.append(imp)

        self.oob_predictions_ = oob_preds

        if importances:
            self.feature_importances_ = pd.concat(importances, axis=1).mean(axis=1)

        oob_scores = []
        oob_r2 = []
        for i in range(n_targets):
            valid = ~np.isnan(oob_preds[:, i])
            if valid.sum() < 10:
                oob_scores.append(np.nan)
                oob_r2.append(np.nan)
                continue
            y_true = Y[valid, i]
            y_pred = oob_preds[valid, i]
            r2 = r2_score(y_true, y_pred)
            oob_r2.append(r2)
            if oob_metric_lower == 'r2':
                oob_scores.append(r2)
            else:
                oob_scores.append(mean_squared_error(y_true, y_pred, squared=False))
        self.oob_scores_ = np.array(oob_scores)
        self.oob_r2_per_target_ = np.array(oob_r2)

        gc.collect()

        self.final_model_ = self.base_estimator(
            random_state=self.random_state, n_jobs=self.n_jobs, **self.kwargs
        )
        self.final_model_.fit(X, Y)

        self.final_importances_ = pd.Series(
            self.final_model_.feature_importances_, index=X_column_names
        ).sort_values(ascending=False)

        final_preds = self.final_model_.predict(X)
        final_r2 = [r2_score(Y[:, i], final_preds[:, i]) for i in range(n_targets)]
        self.final_r2_per_target_ = np.array(final_r2)

        return self

    def predict(self, X):
        X = check_array(X)
        if not hasattr(self, 'final_model_'):
            raise ValueError('Model not fitted yet.')
        return self.final_model_.predict(X)

class GroupAwareRFECV(RFECV):
    def __init__(
        self,
        estimator,
        *,
        step=1,
        min_features_to_select=1,
        cv=None,
        scoring=None,
        verbose=0,
        n_jobs=None,
        importance_getter='auto'
    ):
        super().__init__(
            estimator=estimator,
            step=step,
            min_features_to_select=min_features_to_select,
            cv=cv or GroupKFold(n_splits=5),
            scoring=scoring,
            verbose=verbose,
            n_jobs=n_jobs,
            importance_getter=importance_getter
        )

    def fit(self, X, y, groups=None, X_column_names=None):
        self.groups_ = groups
        self.X_column_names_ = X_column_names or [f'feat_{i}' for i in range(X.shape[1])]
        return super().fit(X, y, groups=groups)

    def _fit(self, X, y, column_mask=None, n_features=None, train_idx=None, test_idx=None):
        if train_idx is None and test_idx is None:
            self.estimator.fit(X, y, groups=self.groups_, X_column_names=self.X_column_names_)
        else:
            groups_train = self.groups_[train_idx] if self.groups_ is not None else None
            current_columns = np.array(self.X_column_names_)[column_mask] if column_mask is not None else self.X_column_names_
            self.estimator.fit(X[train_idx], y[train_idx], groups=groups_train, X_column_names=current_columns)
        return self.estimator

##########################

# Feature selection with ExtraTrees (stable importances)
base_et = lambda **kw: ExtraTreesRegressor(n_estimators=100, **kw)
estimator = GroupAwareMultiOutput(base_estimator=base_et, n_cv_folds=5, random_state=24)

multi_r2 = make_scorer(r2_score, multioutput='uniform_average')
selector = GroupAwareRFECV(estimator=estimator, step=0.1, min_features_to_select=10,
                           cv=GroupKFold(n_splits=5), scoring=multi_r2, n_jobs=-1)

selector.fit(X_train_np, Y_train_np, groups=groups_train, X_column_names=X_train_column_names)

selected_mask = selector.support_
selected_columns = np.array(X_train_column_names)[selected_mask]
X_selected_train = X_train_np[:, selected_mask]
X_selected_test = X_test_np[:, selected_mask]  # Apply to test too

# Final model with RandomForest
base_rf = lambda **kw: RandomForestRegressor(n_estimators=N_EST_I, **kw)
RFreg = GroupAwareMultiOutput(
    base_estimator=base_rf,
    n_cv_folds=5,
    random_state=42,
    oob_metric='r2',
    max_features=0.2,
    max_depth=depth_i,
    min_samples_leaf=obs_leaf_i,
    min_samples_split=obs_split_i,
    n_jobs=-1
)

RFreg.fit(X_selected_train, Y_train_np, groups=groups_train, X_column_names=selected_columns)

# Access results
print('OOB R² per quantile (CV-honest):', RFreg.oob_r2_per_target_)
print('Final R² per quantile (on train):', RFreg.final_r2_per_target_)
print('Final importances:\n', RFreg.final_importances_)

#########

# Make predictions on the training data
Y_train_pred_nosort = RFreg.predict(X_train_selected)
Y_test_pred_nosort = RFreg.predict(X_test_selected)
def post_pred_check(Y_true_np, Y_pred_np, name='test'):
    print(f'{name} shapes: true {Y_true_np.shape}, pred {Y_pred_np.shape}')
    if Y_true_np.shape != Y_pred_np.shape:
        raise AssertionError('Shape mismatch between Y_true and Y_pred')
    for i in range(Y_true_np.shape[1]):
        tstd = np.nanstd(Y_true_np[:,i])
        pstd = np.nanstd(Y_pred_np[:,i])
        print(f'{name} col{i} std: true {tstd:.6f}, pred {pstd:.6f}, true NaNs {np.isnan(Y_true_np[:,i]).sum()}, pred NaNs {np.isnan(Y_pred_np[:,i]).sum()}')
        if tstd == 0:
            print(' -> WARNING: true column is constant; Pearson will be NaN.')
post_pred_check(Y_test_np, Y_test_pred_nosort, 'Y_test')
post_pred_check(Y_train_np, Y_train_pred_nosort, 'Y_train')
# Calculate error matrix
# Compute Kling-Gupta Efficiency (KGE).
def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1] # Correlation coefficient
    beta = np.mean(y_pred) / np.mean(y_true) # Bias ratio
    gamma = np.std(y_pred) / np.std(y_true) # Variability ratio
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)
# Calculate Pearson correlation coefficients
train_r2_coll = [r2_score(Y_train_np[:, i], Y_train_pred_nosort[:, i]) for i in range(11)]
test_r2_coll = [r2_score(Y_test_np[:, i], Y_test_pred_nosort[:, i]) for i in range(11)]
print(train_r2_coll)
print(test_r2_coll)
train_r2_all = np.mean(train_r2_coll)
test_r2_all = np.mean(test_r2_coll)
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
train_r2_coll = np.array(train_r2_coll).reshape(1, -1)
test_r2_coll = np.array(test_r2_coll).reshape(1, -1)
train_rho_coll = np.array(train_rho_coll).reshape(1, -1)
test_rho_coll = np.array(test_rho_coll).reshape(1, -1)
train_mae_coll = np.array(train_mae_coll).reshape(1, -1)
test_mae_coll = np.array(test_mae_coll).reshape(1, -1)
train_kge_coll = np.array(train_kge_coll).reshape(1, -1)
test_kge_coll = np.array(test_kge_coll).reshape(1, -1)
# Reshape the r_all, rho_all, mae_all, and kge_all arrays
train_r2_all = np.array(train_r2_all).reshape(1, -1)
test_r2_all = np.array(test_r2_all).reshape(1, -1)
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
merge_r = np.concatenate((initial_array, train_r2_all , test_r2_all , train_r2_coll , test_r2_coll ), axis=1)
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
importance = pd.Series(RFreg.feature_importances_ , index=RFreg.kept_cols_)
importance.sort_values(ascending=False, inplace=True)
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
print(Y_train_pred_sort.shape)
print(Y_train_pred_sort[:4])
print(Y_test_pred_sort.shape)
print(Y_test_pred_sort[:4])
fmt = '%.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f %.2f'
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_train_pred_sort, delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(rf'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt', Y_test_pred_sort , delimiter=' ', fmt=fmt, header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
EOF
" ## close the sif
exit
