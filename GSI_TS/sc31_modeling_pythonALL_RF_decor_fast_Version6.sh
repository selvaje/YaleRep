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
import numpy as np
import pandas as pd
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
        'order_hack','order_horton','order_shreve','order_strahler','order_topo']} ,

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

## for var in $(head -1 stationID_x_y_valueALL_predictors_X11_floredSFD.txt) ; do echo -e $var ; done | tail  -78  > varX_list.txt
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
X_train_np = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()

X_test_np = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'YYYY', 'MM','IDr']).to_numpy()
groups_train = X_train['IDr'].to_numpy()
X_train_column_names = np.array(X_train.drop(columns=['YYYY', 'MM', 'IDr', 'IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']).columns)

del X, Y, X_train, Y_train, X_test, Y_test
gc.collect()

print(Y_train_np.shape)
print(Y_train_np[:4])
print(X_train_np.shape)
print(X_train_np[:4])

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

all_cols = X_train_column_names.astype(str)
static_present = [c for c in static_var if c in all_cols]
dynamic_present = [c for c in dinamic_var if c in all_cols]
print(f'Found {len(static_present)} static vars present, {len(dynamic_present)} dynamic vars present.')


## Decorrelation (Spearman based) for the static variables grouping at station level threshlod 0.85
## Decorrelation (Spearman based) for the respopons variables vs static variables  at observation level threshlod 0.85
## ExtraTreesRegressor_SD  selected-static variables + dinamic variables, oob r2 grouping at station level
## ExtraTreesRegressor_D  only  dinamic variables, oob r2 grouping at station level
## oob r2 for ExtraTreesRegressor_SD & ExtraTreesRegressor_D
## perform all the above error matrix use ExtraTreesRegressor_SD

def _safe_spearman(a, b):
    try:
        r, _ = spearmanr(a, b, nan_policy='omit')
        if np.isnan(r):
            return 0.0
        return float(r)
    except Exception:
        return 0.0

def decorrelate_by_spearman_station_level(X_np, groups, col_names, threshold=0.85):
    df = pd.DataFrame(X_np, columns=col_names)
    df['__g__'] = groups
    df_g = df.groupby('__g__', observed=True).mean(numeric_only=True).reset_index(drop=True)
    df_g = df_g.replace([np.inf, -np.inf], np.nan).fillna(df_g.median(numeric_only=True))

    corr = df_g.corr(method='spearman').abs()
    cols = list(df_g.columns)
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))

    drop = set()
    keep = []
    for c in cols:
        if c in drop:
            continue
        keep.append(c)
        high = upper.index[upper[c] > threshold].tolist()
        for h in high:
            drop.add(h)

    print(f'1) Static station-level decorrelation kept: {len(keep)} of {len(cols)}')
    return keep

def filter_static_by_response_spearman_obs_level(X_np, Y_np, col_names, threshold=0.85):
    Xdf = pd.DataFrame(X_np, columns=col_names).replace([np.inf, -np.inf], np.nan)
    Xdf = Xdf.fillna(Xdf.median(numeric_only=True))

    keep = []
    for j, cname in enumerate(col_names):
        x = Xdf.iloc[:, j].to_numpy()
        max_abs = 0.0
        for k in range(Y_np.shape[1]):
            y = Y_np[:, k]
            r = abs(_safe_spearman(x, y))
            if r > max_abs:
                max_abs = r
        if max_abs < threshold:
            keep.append(cname)

    print(f'2) Response-vs-static decorrelation kept: {len(keep)} of {len(col_names)}')
    return keep

def group_oob_r2(et_model, Y_np, groups):
    oob = getattr(et_model, 'oob_prediction_', None)
    if oob is None:
        raise RuntimeError('Model has no oob_prediction_. Ensure oob_score=True and bootstrap=True.')

    y_true = np.asarray(Y_np)
    y_oob = np.asarray(oob)

    df_t = pd.DataFrame(y_true)
    df_p = pd.DataFrame(y_oob)
    df_t['__g__'] = groups
    df_p['__g__'] = groups

    t_g = df_t.groupby('__g__', observed=True).mean(numeric_only=True)
    p_g = df_p.groupby('__g__', observed=True).mean(numeric_only=True)

    t_g = t_g.loc[p_g.index]
    r2s = []
    for i in range(t_g.shape[1]):
        r2s.append(r2_score(t_g.iloc[:, i].to_numpy(), p_g.iloc[:, i].to_numpy()))
    return float(np.mean(r2s))

static_thr = 0.85
resp_thr = 0.85

static_cols = np.array(static_present, dtype=str)
dynamic_cols = np.array(dynamic_present, dtype=str)

col_to_idx = {c: i for i, c in enumerate(all_cols.tolist())}
static_idx = np.array([col_to_idx[c] for c in static_cols], dtype=int) if static_cols.size > 0 else np.array([], dtype=int)
dynamic_idx = np.array([col_to_idx[c] for c in dynamic_cols], dtype=int) if dynamic_cols.size > 0 else np.array([], dtype=int)

X_static_train = X_train_np[:, static_idx] if static_idx.size > 0 else np.empty((X_train_np.shape[0], 0), dtype=float)
X_dynamic_train = X_train_np[:, dynamic_idx] if dynamic_idx.size > 0 else np.empty((X_train_np.shape[0], 0), dtype=float)

X_static_test = X_test_np[:, static_idx] if static_idx.size > 0 else np.empty((X_test_np.shape[0], 0), dtype=float)
X_dynamic_test = X_test_np[:, dynamic_idx] if dynamic_idx.size > 0 else np.empty((X_test_np.shape[0], 0), dtype=float)

static_keep1 = decorrelate_by_spearman_station_level(
    X_static_train,
    groups_train,
    static_cols.tolist(),
    threshold=static_thr
)

X_static_keep1_train = pd.DataFrame(X_static_train, columns=static_cols).loc[:, static_keep1].to_numpy() if len(static_keep1) > 0 else np.empty((X_train_np.shape[0], 0), dtype=float)
static_keep2 = filter_static_by_response_spearman_obs_level(
    X_static_keep1_train,
    Y_train_np,
    static_keep1,
    threshold=resp_thr
)

selected_static = np.array(static_keep2, dtype=str)
static_keep_final_idx = np.array([col_to_idx[c] for c in selected_static], dtype=int) if selected_static.size > 0 else np.array([], dtype=int)

X_train_static_sel = X_train_np[:, static_keep_final_idx] if static_keep_final_idx.size > 0 else np.empty((X_train_np.shape[0], 0), dtype=float)
X_test_static_sel = X_test_np[:, static_keep_final_idx] if static_keep_final_idx.size > 0 else np.empty((X_test_np.shape[0], 0), dtype=float)

X_train_dyn = X_dynamic_train
X_test_dyn = X_dynamic_test

X_train_SD = np.hstack([X_train_static_sel, X_train_dyn])
X_test_SD = np.hstack([X_test_static_sel, X_test_dyn])
SD_names = np.concatenate([selected_static, dynamic_cols]).astype(str)

if X_train_SD.shape[1] == 0:
    raise RuntimeError('No predictors selected for SD model (static+dynamic).')

ET_SD = ExtraTreesRegressor(
    n_estimators=N_EST_I,
    random_state=24,
    n_jobs=1,
    bootstrap=True,
    oob_score=True,
    max_depth=depth_i if depth_i > 0 else None,
    min_samples_leaf=max(1, int(obs_leaf_i)),
    min_samples_split=max(2, int(obs_split_i)),
    max_samples=sample_f
)
ET_SD.fit(X_train_SD, Y_train_np)
oob_r2_sd = group_oob_r2(ET_SD, Y_train_np, groups_train)
print(f'ExtraTreesRegressor_SD grouped OOB R2 mean: {oob_r2_sd}')

if X_train_dyn.shape[1] == 0:
    raise RuntimeError('No dynamic predictors found for D model.')

ET_D = ExtraTreesRegressor(
    n_estimators=N_EST_I,
    random_state=24,
    n_jobs=1,
    bootstrap=True,
    oob_score=True,
    max_depth=depth_i if depth_i > 0 else None,
    min_samples_leaf=max(1, int(obs_leaf_i)),
    min_samples_split=max(2, int(obs_split_i)),
    max_samples=sample_f
)
ET_D.fit(X_train_dyn, Y_train_np)
oob_r2_d = group_oob_r2(ET_D, Y_train_np, groups_train)
print(f'ExtraTreesRegressor_D grouped OOB R2 mean: {oob_r2_d}')

class _WrappedModel:
    def __init__(self, model, feature_names):
        self.model = model
        self.final_importances_ = getattr(model, 'feature_importances_', None)
        self.feature_importances_ = getattr(model, 'feature_importances_', None)
        self.kept_cols_ = list(feature_names)

    def fit(self, *args, **kwargs):
        return self

    def predict(self, X):
        return self.model.predict(X)

    def get_importances(self):
        if self.final_importances_ is None:
            return pd.Series(dtype=float)
        return pd.Series(self.final_importances_, index=self.kept_cols_)

RFreg = _WrappedModel(ET_SD, SD_names.tolist())
selected_names = SD_names
X_train_selected = X_train_SD
X_test_selected = X_test_SD
X_train_column_names = SD_names


with parallel_backend('threading', n_jobs=1):
    RFreg.fit(X_train_selected, Y_train_np, groups=groups_train,  X_column_names=selected_names.tolist(), do_oob_cv=True )

# final feature importances
print(RFreg.get_importances().head(15))

# For compatibility with later code:
RFreg.feature_importances_ = RFreg.final_importances_
RFreg.kept_cols_ = selected_names.tolist()
print(f'Start the prediction')
Y_test_pred_nosort   = RFreg.predict(X_test_selected)
Y_train_pred_nosort  = RFreg.predict(X_train_selected)

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

print(f'Calculate error matrix')

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

importance = pd.Series(RFreg.feature_importances_, index=X_train_column_names)
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

print(f'End of the script!!!!!!!!!!!!')

EOF
" ## close the sif
exit