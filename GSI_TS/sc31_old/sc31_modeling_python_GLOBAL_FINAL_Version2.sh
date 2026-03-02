#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling_python_GLOBAL_FINAL.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_python_GLOBAL_FINAL.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorGlobalFinal.sh
#SBATCH --array=500
#SBATCH --mem=500G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd "$EXTRACT"

module load StdEnv

export obs_leaf="$obs_leaf" ; export obs_split="$obs_split" ;  export sample="$sample" ; export depth="$depth" ; export N_EST="$SLURM_ARRAY_TASK_ID"

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH" \
 --env=obs_leaf="$obs_leaf",obs_split="$obs_split",depth="$depth",sample="$sample",N_EST="$N_EST" /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'PYTHON_EOF'
import os
import gc
import warnings
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import ExtraTreesRegressor
from sklearn.metrics import mean_absolute_error
from scipy.stats import pearsonr, spearmanr
from joblib import Parallel, delayed
import time

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

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

print('='*80)
print('GLOBAL SPATIO-TEMPORAL MODEL (NO MM PREDICTOR)')
print('='*80)
print(f'Config: N_EST={N_EST_I}, leaf={obs_leaf_i}, depth={depth_i}')

print('\nMODEL DESIGN:')
print('  ✓ 1 GLOBAL ExtraTreesRegressor')
print('  ✓ Use built-in lag structure (ppt0-3, tmin0-3, tmax0-3, swe0-3, soil0-3)')
print('  ✓ NO MM (month) as predictor')
print('  ✓ Decorrelate static features (Spearman ρ > 0.85)')
print('  ✓ Add spatial features (Xcoord, Ycoord)')
print('  ✓ Simple direct inference (no clustering)')

static_var = ['cti', 'spi', 'sti', 'accumulation', 'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch', 'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near', 'stream_dist_dw_near', 'stream_dist_proximity', 'stream_dist_up_farth', 'stream_dist_up_near', 'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel', 'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg', 'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel', 'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel', 'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP', 'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc', 'GSWs', 'GSWr', 'GSWo', 'GSWe', 'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo', 'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine', 'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev', 'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale', 'slope', 'tcurv', 'tpi', 'tri', 'vrm']

dynamic_vars_with_built_in_lags = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3', 'soil0', 'soil1', 'soil2', 'soil3']

dtypes_X = {'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32', 'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32'}
dtypes_X.update({col: 'int32' for col in dynamic_vars_with_built_in_lags})
dtypes_X.update({col: 'float32' for col in static_var})

dtypes_Y = {'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int32', 'MM': 'int32', 'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32'}
dtypes_Y.update({col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']})

def load_with_dtypes(filepath, usecols=None, dtype_dict=None, chunksize=50000):
    chunks = []
    for chunk in pd.read_csv(filepath, header=0, sep='\s+', usecols=usecols, dtype=dtype_dict, engine='c', chunksize=chunksize):
        chunks.append(chunk)
        if len(chunks) % 10 == 0:
            gc.collect()
    return pd.concat(chunks, ignore_index=True) if chunks else pd.DataFrame()

def decorrelate_group_improved(df, group_name, threshold=0.85, max_features_remove=0.35, verbose=True):
    if df.empty or len(df.columns) <= 1:
        return df
    
    if verbose:
        print(f'   {group_name:20s}: corr={threshold:.2f}, max_remove={max_features_remove:.0%}...', end='', flush=True)
    
    corr = df.corr(method='spearman').abs()
    variances = df.var().values
    var_ranked = np.argsort(-variances)
    
    to_remove = set()
    for feat_idx in var_ranked:
        if feat_idx in to_remove:
            continue
        corr_with = np.where(corr.iloc[feat_idx].values > threshold)[0]
        for other_idx in corr_with:
            if other_idx != feat_idx and other_idx not in to_remove:
                if variances[other_idx] < variances[feat_idx]:
                    to_remove.add(other_idx)
    
    max_remove = int(len(df.columns) * max_features_remove)
    if len(to_remove) > max_remove:
        to_remove = set(sorted(list(to_remove))[:max_remove])
    
    kept_cols = [c for i, c in enumerate(df.columns) if i not in to_remove]
    
    if verbose:
        print(f' {len(df.columns):3d}→{len(kept_cols):3d}')
    
    del corr
    gc.collect()
    return df[kept_cols]

print('\n' + '='*80)
print('DATA LOADING')
print('='*80)

t0 = time.time()
importance = pd.read_csv('varX_list.txt', header=None, sep='\s+', engine='c', low_memory=False)
include_variables = importance.iloc[:78, 0].tolist()
include_variables.extend(['IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'] + dynamic_vars_with_built_in_lags)

Y = load_with_dtypes('stationID_x_y_valueALL_predictors_Y_floredSFD.txt', dtype_dict=dtypes_Y)
X = load_with_dtypes('stationID_x_y_valueALL_predictors_X_floredSFD.txt', usecols=lambda col: col in include_variables, dtype_dict=dtypes_X)

print(f'X shape: {X.shape}, Y shape: {Y.shape}')
print(f'Data loading: {time.time() - t0:.2f}s')

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

print('Filtering stations (>10 observations)...')
counts = X['IDr'].value_counts()
valid_idr = counts[counts > 10].index.values
X = X[X['IDr'].isin(valid_idr)].reset_index(drop=True)
Y = Y[Y['IDr'].isin(valid_idr)].reset_index(drop=True)

print(f'Filtered to {len(valid_idr)} stations, {len(X)} observations')

print('Creating train/test split (80/20)...')
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2, random_state=24)

print(f'Train: {X_train.shape}, Test: {X_test.shape}')

X_train_orig_idx = X_train.index.values
X_test_orig_idx = X_test.index.values

print('\n' + '='*80)
print('FEATURE ENGINEERING')
print('='*80)

X_train_full = X_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'MM', 'YYYY']).copy()
X_test_full = X_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'MM', 'YYYY']).copy()

X_train_full = X_train_full.fillna(X_train_full.mean())
X_test_full = X_test_full.fillna(X_test_full.mean())

print('Decorrelating static features (Spearman ρ > 0.85)...')
t_decor = time.time()

static_cols_in_X = [c for c in static_var if c in X_train_full.columns]
X_static_train = X_train_full[static_cols_in_X]
X_static_train = decorrelate_group_improved(X_static_train, 'Static_Features', threshold=0.85, max_features_remove=0.35, verbose=True)

kept_static = list(X_static_train.columns)
print(f'✓ Decorrelation: {time.time() - t_decor:.2f}s')
print(f'✓ Static features: {len(static_cols_in_X)} → {len(kept_static)} (reduced {100*(1-len(kept_static)/len(static_cols_in_X)):.1f}%)')

print('\nFeature composition:')
print(f'  Static (decorrelated): {len(kept_static)} features')
print(f'  Dynamic (built-in lags): {len(dynamic_vars_with_built_in_lags)} features')
print(f'    - ppt0-3: precipitation (current + 3 months lag)')
print(f'    - tmin0-3: temperature min (current + 3 months lag)')
print(f'    - tmax0-3: temperature max (current + 3 months lag)')
print(f'    - swe0-3: snow water equiv (current + 3 months lag)')
print(f'    - soil0-3: soil moisture (current + 3 months lag)')
print(f'  Spatial: 2 features (Xcoord, Ycoord)')

final_features = kept_static + dynamic_vars_with_built_in_lags + ['Xcoord', 'Ycoord']

X_train_full = X_train_full[final_features + ['IDr']].copy()
X_test_full = X_test_full[final_features + ['IDr']].copy()

Y_train_np = Y_train.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'IDr', 'YYYY', 'MM']).to_numpy(dtype='float32')
Y_test_np = Y_test.drop(columns=['IDs', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord', 'IDr', 'YYYY', 'MM']).to_numpy(dtype='float32')

X_train_np = X_train_full.drop(columns=['IDr']).to_numpy(dtype='float32')
X_test_np = X_test_full.drop(columns=['IDr']).to_numpy(dtype='float32')
sel_names = np.array(final_features)

print(f'\nTOTAL FEATURES: {len(final_features)}')
print(f'  Breakdown: {len(kept_static)} static + {len(dynamic_vars_with_built_in_lags)} dynamic + 2 spatial')
print(f'  NO temporal predictor (MM removed)')

print('\n' + '='*80)
print('TRAINING GLOBAL ExtraTreesRegressor')
print('='*80)

print(f'Training on {X_train_np.shape[0]} observations, {X_train_np.shape[1]} features')
t_train = time.time()

et_global = ExtraTreesRegressor(
    n_estimators=500,
    max_depth=32,
    min_samples_leaf=2,
    min_samples_split=5,
    bootstrap=True,
    random_state=42,
    n_jobs=16,
    verbose=1
)

et_global.fit(X_train_np, Y_train_np)
train_time = time.time() - t_train
train_score = et_global.score(X_train_np, Y_train_np)

print(f'✓ Training time: {train_time:.1f}s')
print(f'✓ Train R²: {train_score:.4f}')

print('\nGenerating predictions...')
Y_train_pred = et_global.predict(X_train_np)
Y_test_pred = et_global.predict(X_test_np)

print('\n' + '='*80)
print('EVALUATION')
print('='*80)

def kge(obs, sim):
    m_o, m_s = np.mean(obs), np.mean(sim)
    s_o, s_s = np.std(obs), np.std(sim)
    r = np.corrcoef(obs, sim)[0, 1]
    return 1 - np.sqrt((r - 1)**2 + (s_s / s_o - 1)**2 + (m_s / m_o - 1)**2)

def comp_quant(i, Y_p, Y_t):
    y_p, y_t = Y_p[:, i], Y_t[:, i]
    r = pearsonr(y_p, y_t)[0]
    rho = spearmanr(y_p, y_t)[0]
    mae = mean_absolute_error(y_t, y_p)
    k = kge(y_t, y_p)
    return r, rho, mae, k

print('Computing metrics (8 parallel jobs)...')
t_eval = time.time()

tr_met = Parallel(n_jobs=8)(delayed(comp_quant)(i, Y_train_pred, Y_train_np) for i in range(11))
ts_met = Parallel(n_jobs=8)(delayed(comp_quant)(i, Y_test_pred, Y_test_np) for i in range(11))

tr_r, tr_rho, tr_mae, tr_kge = zip(*tr_met)
ts_r, ts_rho, ts_mae, ts_kge = zip(*ts_met)

print(f'Evaluation: {time.time() - t_eval:.2f}s')

print(f'\n✓ GLOBAL MODEL PERFORMANCE:')
print(f'  Train R² (avg 11 quantiles): {np.mean(tr_r):.4f}')
print(f'  Test R² (avg 11 quantiles):  {np.mean(ts_r):.4f}')
print(f'  Train KGE (avg): {np.mean(tr_kge):.4f}')
print(f'  Test KGE (avg):  {np.mean(ts_kge):.4f}')

qtl_names = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
print(f'\n✓ PER-QUANTILE TEST PERFORMANCE:')
for i, qn in enumerate(qtl_names):
    print(f'  {qn}: R²={ts_r[i]:.4f}, KGE={ts_kge[i]:.4f}, MAE={ts_mae[i]:.2f}')

imp_ser = pd.Series(et_global.feature_importances_, index=sel_names)
imp_ser.sort_values(ascending=False, inplace=True)

print(f'\n✓ TOP 20 MOST IMPORTANT FEATURES:')
for i, (feat, imp) in enumerate(imp_ser.head(20).items(), 1):
    print(f'  {i:2d}. {feat:20s} importance={imp:.4f}')

print(f'\n✓ LAG IMPORTANCE ANALYSIS:')
lag0_feats = [f for f in imp_ser.index if f.endswith('0')]
lag1_feats = [f for f in imp_ser.index if f.endswith('1')]
lag2_feats = [f for f in imp_ser.index if f.endswith('2')]
lag3_feats = [f for f in imp_ser.index if f.endswith('3')]

print(f'  Lag-0 (current): avg importance={imp_ser[lag0_feats].mean():.4f}')
print(f'  Lag-1 (1mo ago): avg importance={imp_ser[lag1_feats].mean():.4f}')
print(f'  Lag-2 (2mo ago): avg importance={imp_ser[lag2_feats].mean():.4f}')
print(f'  Lag-3 (3mo ago): avg importance={imp_ser[lag3_feats].mean():.4f}')

imp_ser.to_csv(f'../predict_importance_red/stationID_x_y_valueALL_predictors_XimportanceN{N_EST_S}_GLOBAL_FINAL.txt', index=True, sep=' ', header=False)

Y_tr_idx = pd.DataFrame(Y_train_pred, index=X_train_orig_idx[:Y_train_pred.shape[0]])
Y_ts_idx = pd.DataFrame(Y_test_pred, index=X_test_orig_idx[:Y_test_pred.shape[0]])

Y_tr_sort = Y_tr_idx.sort_index().values
Y_ts_sort = Y_ts_idx.sort_index().values

fmt_p = '%.2f ' * 11
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTrainN{N_EST_S}_GLOBAL_FINAL.txt', Y_tr_sort, delimiter=' ', fmt=fmt_p.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')
np.savetxt(f'../predict_prediction_red/stationID_x_y_valueALL_predictors_YpredictTestN{N_EST_S}_GLOBAL_FINAL.txt', Y_ts_sort, delimiter=' ', fmt=fmt_p.strip(), header='QMIN Q10 Q20 Q30 Q40 Q50 Q60 Q70 Q80 Q90 QMAX', comments='')

print(f'\n✓ ✓ ✓ TRAINING COMPLETE ✓ ✓ ✓')
print(f'✓ Model: 1 Global ExtraTreesRegressor')
print(f'✓ Features: {len(kept_static)} static (decorrelated) + {len(dynamic_vars_with_built_in_lags)} dynamic (lags) + 2 spatial')
print(f'✓ Total features: {len(final_features)}')
print(f'✓ Observations: {X_train_np.shape[0]} train, {X_test_np.shape[0]} test')
print(f'✓ Output: 11 quantiles (QMIN-QMAX) per location')
print(f'✓ Training time: {train_time:.1f}s')
print(f'✓ Inference: Direct prediction (no region assignment)')
print(f'✓ Production: Simple, fast, easy to maintain')

gc.collect()

PYTHON_EOF
"
# close the sif
exit
