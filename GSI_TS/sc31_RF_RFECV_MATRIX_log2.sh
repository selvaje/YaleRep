#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_RF_RFECV_MATRIX_log2.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_RF_RFECV_MATRIX_log2.sh.%A_%a.err
#SBATCH --job-name=sc31_RF_RFECV_MATRIX_log2.sh
#SBATCH --array=500
#SBATCH --mem=500G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv
export obs_leaf=$obs_leaf ; export obs_split=$obs_split ; export sample=$sample ; export depth=$depth ; export N_EST=$SLURM_ARRAY_TASK_ID
echo "obs_leaf  $obs_leaf obs_split  $obs_split sample $sample n_estimators $N_EST"
~/bin/echoerr "n_estimators ${N_EST} obs_leaf ${obs_leaf} obs_split ${obs_split} sample $sample depth $depth "
echo "start python modeling"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
  --env OMP_NUM_THREADS=1 --env MKL_NUM_THREADS=1 --env OPENBLAS_NUM_THREADS=1 --env NUMEXPR_NUM_THREADS=1 \
  --env obs_leaf=$obs_leaf --env obs_split=$obs_split --env depth=$depth --env sample=$sample --env N_EST=$N_EST \
  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif bash -c "
python3 <<'EOF'
import os
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split, KFold
from sklearn.feature_selection import RFECV
from sklearn.ensemble import ExtraTreesRegressor
from sklearn.cluster import KMeans
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr, spearmanr

pd.set_option('display.max_columns', None)

NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 16))

obs_leaf_s = os.environ['obs_leaf']
obs_leaf_i = int(os.environ['obs_leaf'])

obs_split_s = os.environ['obs_split']
obs_split_i = int(os.environ['obs_split'])

depth_s = os.environ['depth']
depth_i = int(os.environ['depth'])

sample_f = float(os.environ['sample'])
sample_s = str(int(sample_f * 100))

N_EST_I = int(os.environ['N_EST'])
N_EST_S = os.environ['N_EST']

DATA_X = 'stationID_x_y_valueALL_predictors_0X_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_0Y_floredSFD.txt'

dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'int32' for col in [
        'ppt0', 'ppt1', 'ppt2', 'ppt3',
        'tmin0', 'tmin1', 'tmin2', 'tmin3',
        'tmax0', 'tmax1', 'tmax2', 'tmax3',
        'swe0', 'swe1', 'swe2', 'swe3',
        'soil0', 'soil1', 'soil2', 'soil3',
        'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
        'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
        'GSWs', 'GSWr', 'GSWo', 'GSWe',
        'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo'
    ]},
    **{col: 'float32' for col in [
        'cti', 'spi', 'sti',
        'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
        'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
        'stream_dist_dw_near', 'stream_dist_proximity',
        'stream_dist_up_farth', 'stream_dist_up_near',
        'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
        'slope_elv_dw_cel', 'slope_grad_dw_cel',
        'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
        'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg',
        'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
        'dx', 'dxx', 'dxy', 'dy', 'dyy',
        'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
        'dev-magnitude', 'dev-scale',
        'eastness', 'elev-stdev', 'northness', 'pcurv',
        'rough-magnitude', 'roughness', 'rough-scale',
        'slope', 'tcurv', 'tpi', 'tri', 'vrm', 'accumulation'
    ]}
}

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
    **{col: 'float32' for col in [
        'QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50',
        'Q60', 'Q70', 'Q80', 'Q90', 'QMAX'
    ]}
}

importance = pd.read_csv('varX_list.txt', header=None, sep=r'\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
additional_columns = ['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord']
include_variables.extend(additional_columns)

Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', dtype=dtypes_Y, engine='c', low_memory=False)
X = pd.read_csv(DATA_X, header=0, sep=r'\s+', usecols=lambda col: col in include_variables, dtype=dtypes_X, engine='c', low_memory=False)

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# (2) Strong sort key: create a row id before splitting and carry it through
X['ROWID'] = np.arange(X.shape[0], dtype=np.int64)
Y['ROWID'] = np.arange(Y.shape[0], dtype=np.int64)

# derived dynamic vars (no 0->nan for accumulation anymore; accumulation always > 0)
X['ppt_sum'] = (X['ppt0'].astype('float32') + X['ppt1'].astype('float32') + X['ppt2'].astype('float32') + X['ppt3'].astype('float32'))
X['ppt_avg'] = ((X['ppt0'].astype('float32') + X['ppt1'].astype('float32')) / X['accumulation'].astype('float32')).astype('float32')

stations = pd.read_csv(
    '/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_txt_red/IDstation_lon_lat_IDraster_Xcoord_Ycoord_2sH.txt',
    sep=r'\s+', usecols=['IDr', 'Xcoord', 'Ycoord']
).drop_duplicates()

counts = X['IDr'].value_counts()
valid_idr_train = counts[counts > 10].index

unique_stations = stations[['IDr', 'Xcoord', 'Ycoord']].drop_duplicates()
kmeans = KMeans(n_clusters=20, random_state=24).fit(unique_stations[['Xcoord', 'Ycoord']])
unique_stations['cluster'] = kmeans.labels_

train_stations = unique_stations[unique_stations['IDr'].isin(valid_idr_train)][['IDr', 'cluster']]
train_rasters, test_rasters = train_test_split(
    train_stations,
    test_size=0.2,
    random_state=24,
    stratify=train_stations['cluster']
)

X_train = X[X['IDr'].isin(train_rasters['IDr'])].copy()
Y_train = Y[Y['IDr'].isin(train_rasters['IDr'])].copy()
X_test = X[X['IDr'].isin(test_rasters['IDr'])].copy()
Y_test = Y[Y['IDr'].isin(test_rasters['IDr'])].copy()

# strict alignment ordering using ROWID (strong unique key)
X_train = X_train.sort_values(by=['ROWID']).reset_index(drop=True)
Y_train = Y_train.sort_values(by=['ROWID']).reset_index(drop=True)
X_test = X_test.sort_values(by=['ROWID']).reset_index(drop=True)
Y_test = Y_test.sort_values(by=['ROWID']).reset_index(drop=True)

assert (X_train['ROWID'].to_numpy() == Y_train['ROWID'].to_numpy()).all()
assert (X_test['ROWID'].to_numpy() == Y_test['ROWID'].to_numpy()).all()

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
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg',
    'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm'
]

dinamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3', 'ppt_sum', 'ppt_avg',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

all_cols = X_train.columns.astype(str).tolist()
static_present = [c for c in static_var if c in all_cols]
dynamic_present = [c for c in dinamic_var if c in all_cols]

# dynamic predictors / area (no replace(0, nan); accumulation always > 0)
acc_tr = X_train['accumulation'].astype('float32')
acc_te = X_test['accumulation'].astype('float32')

Xdyn_tr = X_train[dynamic_present].astype('float32')
Xdyn_te = X_test[dynamic_present].astype('float32')

dyn_area_tr = (Xdyn_tr.div(acc_tr, axis=0)).astype('float32')
dyn_area_te = (Xdyn_te.div(acc_te, axis=0)).astype('float32')

dyn_area_names = [f'{c}_area' for c in dynamic_present]
dyn_area_tr.columns = dyn_area_names
dyn_area_te.columns = dyn_area_names

# targets: log1p(Q/area)
q_cols = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
qlog_cols = ['qLMIN', 'qL10', 'qL20', 'qL30', 'qL40', 'qL50', 'qL60', 'qL70', 'qL80', 'qL90', 'qLMAX']

Qtr = Y_train[q_cols].astype('float32')
Qte = Y_test[q_cols].astype('float32')

qtr = (Qtr.div(acc_tr, axis=0)).astype('float32')
qte = (Qte.div(acc_te, axis=0)).astype('float32')

Ylog_train = np.log1p(qtr).astype('float32')
Ylog_test = np.log1p(qte).astype('float32')

Y_train_np = Ylog_train.to_numpy()
Y_test_np = Ylog_test.to_numpy()

# RFECV station-level targets: log1p(mean(Q)/area) + CV(std(Q)/mean(Q))
mean_log_cols = ['qLMINm', 'qL10m', 'qL20m', 'qL30m', 'qL40m', 'qL50m', 'qL60m', 'qL70m', 'qL80m', 'qL90m', 'qLMAXm']
cv_cols = ['QMINcv', 'Q10cv', 'Q20cv', 'Q30cv', 'Q40cv', 'Q50cv', 'Q60cv', 'Q70cv', 'Q80cv', 'Q90cv', 'QMAXcv']

Xstatic_obs = X_train[static_present].replace([np.inf, -np.inf], np.nan)
Xstatic_obs = Xstatic_obs.fillna(Xstatic_obs.median(numeric_only=True)).astype('float32')
X_station = Xstatic_obs.copy()
X_station['IDr'] = X_train['IDr'].to_numpy()
X_station = X_station.groupby('IDr', observed=True).mean(numeric_only=True)

YQ_station_raw = Y_train[['IDr'] + q_cols].copy()
gQ = YQ_station_raw.groupby('IDr', observed=True)[q_cols]
Q_mean = gQ.mean().astype('float32')
Q_std = gQ.std(ddof=0).astype('float32')

A_station = X_train[['IDr', 'accumulation']].copy()
A_station = A_station.groupby('IDr', observed=True)['accumulation'].mean().astype('float32')

q_mean_station = Q_mean.div(A_station, axis=0).astype('float32')
qlog_mean_station = np.log1p(q_mean_station).astype('float32')
qlog_mean_station.columns = mean_log_cols

den = Q_mean.replace(0, np.nan)
Q_cv = (Q_std / den).fillna(0).astype('float32')
Q_cv.columns = cv_cols

Y_station = pd.concat([qlog_mean_station, Q_cv], axis=1)
Y_station = Y_station.replace([np.inf, -np.inf], np.nan).fillna(0).astype('float32')

cv = KFold(n_splits=5, shuffle=True, random_state=24)

et_for_rfecv = ExtraTreesRegressor(
    n_estimators=500,
    random_state=24,
    n_jobs=1,
    bootstrap=True,
    max_depth=None
)

rfecv = RFECV(
    estimator=et_for_rfecv,
    step=1,
    cv=cv,
    scoring='r2',
    min_features_to_select=5,
    n_jobs=NCPU
)

rfecv.fit(X_station, Y_station)

static_keep = X_station.columns[rfecv.support_].tolist()

print('')
print('RFECV selected static variables:')
for i, v in enumerate(static_keep, start=1):
    print(f'  {i:3d}. {v}')
print('')

rank_df = pd.DataFrame({
    'feature': X_station.columns.astype(str),
    'rank': rfecv.ranking_.astype(int),
    'selected': rfecv.support_.astype(bool)
}).sort_values(by=['rank', 'feature']).reset_index(drop=True)

rank_out = f'../predict_score_red/RFECV_static_ranking_N{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_log.txt'
rank_df.to_csv(rank_out, sep=' ', index=False)

cvres = rfecv.cv_results_
if 'n_features' in cvres:
    nfeat = np.array(cvres['n_features']).astype(int)
elif 'n_features_to_select' in cvres:
    nfeat = np.array(cvres['n_features_to_select']).astype(int)
else:
    nfeat = np.arange(len(cvres['mean_test_score']), 0, -1).astype(int)

mean_score = np.array(cvres['mean_test_score'], dtype=float)
std_score = np.array(cvres['std_test_score'], dtype=float)

curve_df = pd.DataFrame({
    'num_features': nfeat,
    'mean_test_score': mean_score,
    'std_test_score': std_score
}).sort_values(by='num_features', ascending=True).reset_index(drop=True)

curve_out = f'../predict_score_red/RFECV_static_curve_N{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_log.txt'
curve_df.to_csv(curve_out, sep=' ', index=False)

# Train ET_SD on log targets
X_train_S = X_train[static_keep].replace([np.inf, -np.inf], np.nan)
X_train_S = X_train_S.fillna(X_train_S.median(numeric_only=True)).astype('float32').to_numpy()

X_test_S = X_test[static_keep].replace([np.inf, -np.inf], np.nan)
X_test_S = X_test_S.fillna(X_test_S.median(numeric_only=True)).astype('float32').to_numpy()

X_train_D = dyn_area_tr.to_numpy()
X_test_D = dyn_area_te.to_numpy()

X_train_SD = np.hstack([X_train_S, X_train_D])
X_test_SD = np.hstack([X_test_S, X_test_D])
SD_names = static_keep + dyn_area_names

ET_SD = ExtraTreesRegressor(
    n_estimators=N_EST_I,
    random_state=24,
    n_jobs=NCPU,
    bootstrap=True,
    oob_score=True,
    max_depth=depth_i if depth_i > 0 else None,
    min_samples_leaf=max(1, int(obs_leaf_i)),
    min_samples_split=max(2, int(obs_split_i)),
    max_samples=sample_f
)

ET_SD.fit(X_train_SD, Y_train_np)
print(f'OOB r2 ExtraTreesRegressor_SD : {ET_SD.oob_score_}')

importance_s = pd.Series(ET_SD.feature_importances_, index=SD_names).sort_values(ascending=False)
print('')
print('Top 30 ET_SD feature importances:')
print(importance_s.head(30).to_string())
print('')

# predictions in log space
Y_test_pred = ET_SD.predict(X_test_SD)
Y_train_pred = ET_SD.predict(X_train_SD)

def kge_1d(y_true, y_pred):
    y_true = np.asarray(y_true)
    y_pred = np.asarray(y_pred)
    if np.all(y_true == y_true[0]):
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    return 1 - np.sqrt((r - 1) ** 2 + (beta - 1) ** 2 + (gamma - 1) ** 2)

def compute_error_pack(Y_true_np, Y_pred_np):
    r_coll = [pearsonr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(0, 11)]
    r_all = float(np.nanmean(r_coll))
    rho_coll = [spearmanr(Y_pred_np[:, i], Y_true_np[:, i])[0] for i in range(0, 11)]
    rho_all = float(np.nanmean(rho_coll))
    mae_coll = [mean_absolute_error(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(0, 11)]
    mae_all = float(np.mean(mae_coll))
    kge_coll = [kge_1d(Y_true_np[:, i], Y_pred_np[:, i]) for i in range(0, 11)]
    kge_all = float(np.nanmean(kge_coll))
    return {
        'r_coll': np.array(r_coll).reshape(1, -1),
        'rho_coll': np.array(rho_coll).reshape(1, -1),
        'mae_coll': np.array(mae_coll).reshape(1, -1),
        'kge_coll': np.array(kge_coll).reshape(1, -1),
        'r_all': np.array(r_all).reshape(1, -1),
        'rho_all': np.array(rho_all).reshape(1, -1),
        'mae_all': np.array(mae_all).reshape(1, -1),
        'kge_all': np.array(kge_all).reshape(1, -1),
    }

initial_array = np.array([[N_EST_I, sample_f, obs_split_i, obs_leaf_i]])

# Existing accuracy matrix in log(q) space: YLscore*
train_L = compute_error_pack(Y_train_np, Y_train_pred)
test_L = compute_error_pack(Y_test_np, Y_test_pred)

merge_r_L = np.concatenate((initial_array, train_L['r_all'], test_L['r_all'], train_L['r_coll'], test_L['r_coll']), axis=1)
merge_rho_L = np.concatenate((initial_array, train_L['rho_all'], test_L['rho_all'], train_L['rho_coll'], test_L['rho_coll']), axis=1)
merge_mae_L = np.concatenate((initial_array, train_L['mae_all'], test_L['mae_all'], train_L['mae_coll'], test_L['mae_coll']), axis=1)
merge_kge_L = np.concatenate((initial_array, train_L['kge_all'], test_L['kge_all'], train_L['kge_coll'], test_L['kge_coll']), axis=1)

fmt_score = ' '.join(['%i'] + ['%.2f'] + ['%i'] + ['%i'] + ['%.2f'] * (merge_r_L.shape[1] - 4))

np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YLscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r_L, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YLscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho_L, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YLscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae_L, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_YLscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge_L, delimiter=' ', fmt=fmt_score)

# NEW additional accuracy matrix in original Q space: QYLscore*
Q_train_true = Qtr.astype('float64').to_numpy()
Q_test_true = Qte.astype('float64').to_numpy()

acc_tr_np = X_train['accumulation'].astype('float64').to_numpy().reshape(-1, 1)
acc_te_np = X_test['accumulation'].astype('float64').to_numpy().reshape(-1, 1)

# back-transform: q_pred = expm1(log(q+1)_pred), then Q_pred = q_pred * area
q_train_pred = np.expm1(Y_train_pred.astype('float64'))
q_test_pred = np.expm1(Y_test_pred.astype('float64'))

Q_train_pred = q_train_pred * acc_tr_np
Q_test_pred = q_test_pred * acc_te_np

train_Q = compute_error_pack(Q_train_true, Q_train_pred)
test_Q = compute_error_pack(Q_test_true, Q_test_pred)

merge_r_Q = np.concatenate((initial_array, train_Q['r_all'], test_Q['r_all'], train_Q['r_coll'], test_Q['r_coll']), axis=1)
merge_rho_Q = np.concatenate((initial_array, train_Q['rho_all'], test_Q['rho_all'], train_Q['rho_coll'], test_Q['rho_coll']), axis=1)
merge_mae_Q = np.concatenate((initial_array, train_Q['mae_all'], test_Q['mae_all'], train_Q['mae_coll'], test_Q['mae_coll']), axis=1)
merge_kge_Q = np.concatenate((initial_array, train_Q['kge_all'], test_Q['kge_all'], train_Q['kge_coll'], test_Q['kge_coll']), axis=1)

np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QYLscorerN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_r_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QYLscorerhoN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_rho_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QYLscoremaeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_mae_Q, delimiter=' ', fmt=fmt_score)
np.savetxt(f'../predict_score_red/stationID_x_y_valueALL_predictors_QYLscorekgeN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_GaRFG.txt', merge_kge_Q, delimiter=' ', fmt=fmt_score)

# importance + predictions saved (unchanged)
importance_s.to_csv(
    f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
    index=True, sep=' ', header=False
)

fmt_pred = '%.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f %.6f'
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
    Y_train_pred, delimiter=' ', fmt=fmt_pred, header=' '.join(qlog_cols), comments=''
)
np.savetxt(
    f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_{obs_leaf_s}leaf_{obs_split_s}split_{depth_s}depth_{sample_s}sample_2RF.txt',
    Y_test_pred, delimiter=' ', fmt=fmt_pred, header=' '.join(qlog_cols), comments=''
)

print('End of the script!!!!!!!!!!!!')
EOF
"
exit
