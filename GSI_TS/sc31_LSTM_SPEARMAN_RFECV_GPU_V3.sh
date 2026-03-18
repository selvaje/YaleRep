#!/bin/bash
#SBATCH -p day
####SBATCH --gpus=rtx_5000_ada:1
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /nfs/roberts/scratch/pi_ga254/ga254/stdout/sc31_LSTM_SPEARMAN_RFECV_GPU_V2.%J.out
#SBATCH -e /nfs/roberts/scratch/pi_ga254/ga254/stderr/sc31_LSTM_SPEARMAN_RFECV_GPU_V2.%J.err
#SBATCH --job-name=sc31_LSTM_SPEARMAN_RFECV_GPU_V2
#SBATCH --mem=40G

EXTRACT=/nfs/roberts/pi/pi_ga254/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv

source /nfs/roberts/project/pi_ga254/ga254/py_env/venv_GSI_TS/bin/activate

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1
export CUDA_VISIBLE_DEVICES=0
export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

python3 <<'EOFPYTHON'
import os
import sys
import numpy as np
import pandas as pd
from datetime import datetime, timedelta
from scipy.stats import spearmanr, pearsonr
from sklearn.preprocessing import QuantileTransformer
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.feature_selection import RFECV
from sklearn.ensemble import ExtraTreesRegressor
from sklearn.model_selection import KFold
import torch
import torch.nn as nn
from torch.utils.data import Dataset, DataLoader
from torch.cuda.amp import autocast, GradScaler
from joblib import Parallel, delayed, parallel_backend
import gc
import warnings
warnings.filterwarnings('ignore')

os.environ['OMP_NUM_THREADS'] = '1'
os.environ['MKL_NUM_THREADS'] = '1'
os.environ['OPENBLAS_NUM_THREADS'] = '1'

pd.set_option('display.max_columns', None)
pd.set_option('display.max_rows', None)

print("\n" + "="*100)
print("SC31: LSTM WITH GPU ACCELERATION - YALE BOUCHET CLUSTER")
print("="*100)
print(f"Start time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print(f"Job ID: {os.environ.get('SLURM_JOB_ID', 'N/A')}")
print("="*100)

# =========================================================================
# GPU CONFIGURATION
# =========================================================================
print(f"\n{'='*100}")
print("GPU CONFIGURATION")
print(f"{'='*100}")

DEVICE = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"cuDNN version: {torch.backends.cudnn.version()}")
    print(f"Number of GPUs: {torch.cuda.device_count()}")
    print(f"GPU device: {torch.cuda.get_device_name(0)}")
    print(f"GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1e9:.2f} GB")
    
    torch.backends.cudnn.benchmark = True
    torch.backends.cudnn.enabled = True
    
    print(f"GPU memory allocated: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB")
    print(f"GPU memory reserved: {torch.cuda.memory_reserved(0) / 1e9:.2f} GB")
else:
    print("WARNING: CUDA not available! Running on CPU.")

# =========================================================================
# CONFIGURATION
# =========================================================================
NCPU = int(os.environ.get('SLURM_CPUS_PER_TASK', 32))
print(f"\nCPU cores available: {NCPU}")

# Temporal Split
TRAIN_YEARS = 11
TEST_YEARS = 11

# Feature Selection Configuration
SPEARMAN_STATION_THRESHOLD = 0.90
USE_RFECV = False  # <<<--- SET TO True/False TO ENABLE/DISABLE RFECV

print(f"\n{'='*100}")
print("FEATURE SELECTION CONFIGURATION")
print(f"{'='*100}")
print(f"  Spearman threshold: {SPEARMAN_STATION_THRESHOLD}")
print(f"  Use RFECV: {USE_RFECV}")
if USE_RFECV:
    print(f"    RFECV method: Station-level (mean(Q) + CV)")
    print(f"    RFECV estimator: ExtraTreesRegressor")
    print(f"    WARNING: RFECV uses cross-sectional approach (not temporal)")
else:
    print(f"    Using Spearman decorrelation only (LSTM-appropriate)")
print(f"{'='*100}")

# LSTM Parameters
SEQ_LEN = 12
BATCH_SIZE = 1024
EPOCHS = 50
LR = 1e-3
RANDOM_STATE = 24
NUM_WORKERS_DATALOADER = 4
USE_MIXED_PRECISION = True

print(f"\nLSTM Configuration:")
print(f"  Sequence length: {SEQ_LEN}")
print(f"  Batch size: {BATCH_SIZE}")
print(f"  Epochs: {EPOCHS}")
print(f"  Learning rate: {LR}")
print(f"  Device: {DEVICE}")
print(f"  DataLoader workers: {NUM_WORKERS_DATALOADER}")
print(f"  Mixed precision: {USE_MIXED_PRECISION}")

# Data Files
DATA_X = 'stationID_x_y_valueALL_predictors_X11_floredSFD.txt'
DATA_Y = 'stationID_x_y_valueALL_predictors_Y11_floredSFD.txt'

# =========================================================================
# VARIABLE DEFINITIONS
# =========================================================================
static_var = [
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel', 'slope_elv_dw_cel',
    'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg',
    'dx', 'dxx', 'dxy', 'dy', 'dyy',
    'elev', 'aspect-cosine', 'aspect-sine', 'convergence',
    'dev-magnitude', 'dev-scale',
    'eastness', 'elev-stdev', 'northness', 'pcurv',
    'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm',
    'order_strahler', 'order_shreve', 'order_horton', 'order_hack', 'order_topo',
    'AWCtS', 'BLDFIE', 'CECSOL', 'CLYPPT', 'CRFVOL', 'ORCDRC',
    'PHIHOX', 'SLTPPT', 'SNDPPT', 'WWP',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc'
]

dinamic_var = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3'
]

# =========================================================================
# PHASE 1: LOAD DATA
# =========================================================================
print("\n" + "="*100)
print("PHASE 1: DATA LOADING")
print("="*100)

X = pd.read_csv(DATA_X, header=0, sep=r'\s+', engine='c', low_memory=False)
Y = pd.read_csv(DATA_Y, header=0, sep=r'\s+', engine='c', low_memory=False)

print(f"✓ X: {X.shape}, Y: {Y.shape}")

static_present = [v for v in static_var if v in X.columns]
dynamic_present = [v for v in dinamic_var if v in X.columns]

q_cols = [col for col in Y.columns if col.startswith('Q') or col in ['QMIN', 'QMAX']]
print(f"✓ Static: {len(static_present)}, Dynamic: {len(dynamic_present)}, Quantiles: {len(q_cols)}")

X = X.reset_index(drop=True)
Y = Y.reset_index(drop=True)

# =========================================================================
# CREATE DERIVED FEATURES (VECTORIZED - FAST)
# =========================================================================
print("\n" + "="*100)
print("CREATING DERIVED FEATURES (VECTORIZED)")
print("="*100)

derive_start = datetime.now()

acc = X['accumulation'].astype('float32').values
acc_safe = np.where(acc == 0, 1e-10, acc)

vars_to_derive = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 
                  'tmin0', 'tmin1', 'tmin2', 'tmin3', 'tmax0',
                  'soil0', 'soil1', 'soil2', 'soil3', 'GRWLw']

derived_features = []
for var in vars_to_derive:
    if var in X.columns:
        X[f'{var}_area'] = (X[var].astype('float32').values / acc_safe).astype('float32')
        derived_features.append(f'{var}_area')

derive_time = (datetime.now() - derive_start).total_seconds()
print(f"✓ Created {len(derived_features)} derived features in {derive_time:.2f} seconds")

dynamic_final = derived_features.copy()

del acc, acc_safe
gc.collect()

# =========================================================================
# PHASE 3: STATIC FEATURE SELECTION
# =========================================================================
print("\n" + "="*100)
print("PHASE 3: STATIC VARIABLE SELECTION")
print("="*100)

def compute_pairwise_correlation_chunk(col_pairs, df_g):
    results = []
    for i, j in col_pairs:
        try:
            r, _ = spearmanr(df_g.iloc[:, i].values, df_g.iloc[:, j].values, nan_policy='omit')
            if not np.isnan(r):
                results.append((df_g.columns[i], df_g.columns[j], abs(r)))
        except:
            pass
    return results

def decorrelate_by_spearman_parallel(X_np, groups, col_names, threshold, n_jobs):
    print(f"  Spearman decorrelation (threshold={threshold})")
    
    df = pd.DataFrame(X_np, columns=col_names)
    df['__g__'] = groups
    df_g = df.groupby('__g__').mean(numeric_only=True).reset_index(drop=True)
    df_g = df_g.replace([np.inf, -np.inf], np.nan).fillna(df_g.median(numeric_only=True))
    
    del df
    gc.collect()
    
    n_features = len(df_g.columns)
    pairs = [(i, j) for i in range(n_features) for j in range(i+1, n_features)]
    chunk_size = max(1, len(pairs) // (n_jobs * 4))
    chunks = [pairs[i:i+chunk_size] for i in range(0, len(pairs), chunk_size)]
    
    with parallel_backend('loky', n_jobs=n_jobs):
        chunk_results = Parallel()(
            delayed(compute_pairwise_correlation_chunk)(chunk, df_g)
            for chunk in chunks
        )
    
    all_correlations = [item for sublist in chunk_results for item in sublist]
    
    high_corr_pairs = {}
    for col1, col2, corr in all_correlations:
        if corr > threshold:
            if col1 not in high_corr_pairs:
                high_corr_pairs[col1] = []
            high_corr_pairs[col1].append(col2)
    
    cols = list(df_g.columns)
    drop = set()
    keep = []
    
    for c in cols:
        if c in drop:
            continue
        keep.append(c)
        if c in high_corr_pairs:
            for h in high_corr_pairs[c]:
                drop.add(h)
    
    print(f'  Output: {len(keep)} KEPT, {len(drop)} DISCARDED')
    
    del df_g, all_correlations
    gc.collect()
    
    return keep

# -------------------------------------------------------------------------
# STEP 1: Spearman Decorrelation (ALWAYS PERFORMED)
# -------------------------------------------------------------------------
print("\n" + "-"*100)
print("STEP 1: Spearman Decorrelation at Station Level")
print("-"*100)

spearman_start = datetime.now()

X_static_np = X[[c for c in static_present if c in X.columns]].to_numpy(dtype=np.float32)
groups = X['IDr'].to_numpy()

static_decorrelated = decorrelate_by_spearman_parallel(
    X_static_np, groups, [c for c in static_present if c in X.columns],
    SPEARMAN_STATION_THRESHOLD, NCPU
)

spearman_time = (datetime.now() - spearman_start).total_seconds()
print(f"\n✓ STEP 1 Complete: {len(static_present)} → {len(static_decorrelated)} features ({spearman_time:.1f}s)")

del X_static_np, groups
gc.collect()

# -------------------------------------------------------------------------
# STEP 2: RFECV (OPTIONAL - CONTROLLED BY USE_RFECV FLAG)
# -------------------------------------------------------------------------
if USE_RFECV:
    print("\n" + "-"*100)
    print("STEP 2: RFECV at Station Level (CROSS-SECTIONAL APPROACH)")
    print("-"*100)
    print("WARNING: Using station-level mean(Q) + CV target (not temporal)")
    print("         This may not be optimal for LSTM temporal prediction")
    print("-"*100)
    
    rfecv_start = datetime.now()
    
    if len(static_decorrelated) > 0:
        # Prepare station-level predictors
        Xstatic = X[static_decorrelated].replace([np.inf, -np.inf], np.nan)
        Xstatic = Xstatic.fillna(Xstatic.median(numeric_only=True)).astype('float32')
        X_station = Xstatic.copy()
        X_station['IDr'] = X['IDr'].to_numpy()
        X_station = X_station.groupby('IDr').mean(numeric_only=True)
        
        del Xstatic
        gc.collect()
        
        # Prepare station-level targets (mean(Q) + CV)
        YQ = Y[['IDr'] + q_cols].copy()
        gQ = YQ.groupby('IDr')[q_cols]
        Q_mean = gQ.mean().astype('float32')
        Q_std = gQ.std(ddof=0).astype('float32')
        
        A_station = X[['IDr', 'accumulation']].groupby('IDr')['accumulation'].mean().astype('float32')
        A_station_safe = A_station.replace(0, np.nan)
        
        mean_cols = ['qMINm', 'q10m', 'q20m', 'q30m', 'q40m', 'q50m', 'q60m', 'q70m', 'q80m', 'q90m', 'qMAXm']
        cv_cols = ['QMINcv', 'Q10cv', 'Q20cv', 'Q30cv', 'Q40cv', 'Q50cv', 'Q60cv', 'Q70cv', 'Q80cv', 'Q90cv', 'QMAXcv']
        
        q_mean_station = Q_mean.div(A_station_safe, axis=0).fillna(0).astype('float32')
        q_mean_station.columns = mean_cols
        
        Q_cv = (Q_std / Q_mean.replace(0, np.nan)).fillna(0).astype('float32')
        Q_cv.columns = cv_cols
        
        Y_station = pd.concat([q_mean_station, Q_cv], axis=1)
        Y_station = Y_station.replace([np.inf, -np.inf], np.nan).fillna(0).astype('float32')
        
        print(f"  Station-level data shapes:")
        print(f"    X_station: {X_station.shape} (one row per station)")
        print(f"    Y_station: {Y_station.shape} (mean(Q)/area + CV per station)")
        
        del Q_mean, Q_std, YQ, gQ, A_station, q_mean_station, Q_cv
        gc.collect()
        
        # RFECV with ExtraTreesRegressor
        cv = KFold(n_splits=5, shuffle=True, random_state=RANDOM_STATE)
        et = ExtraTreesRegressor(
            n_estimators=500, 
            random_state=RANDOM_STATE, 
            n_jobs=1,  # Single-threaded per estimator
            bootstrap=True,
            max_depth=None
        )
        rfecv = RFECV(
            et, 
            step=1, 
            cv=cv, 
            scoring='r2', 
            min_features_to_select=5, 
            n_jobs=NCPU  # Parallelize across CV folds
        )
        
        print(f"\n  Running RFECV with {NCPU} parallel jobs...")
        print(f"    Estimator: ExtraTreesRegressor(n_estimators=500)")
        print(f"    CV: 5-fold KFold")
        print(f"    Scoring: R²")
        
        rfecv.fit(X_station, Y_station)
        
        static_final = X_station.columns[rfecv.support_].tolist()
        
        rfecv_time = (datetime.now() - rfecv_start).total_seconds()
        
        print(f"\n  RFECV Results:")
        print(f"    Input features: {len(static_decorrelated)}")
        print(f"    Selected features: {len(static_final)}")
        print(f"    Discarded features: {len(static_decorrelated) - len(static_final)}")
        print(f"    Best CV R²: {rfecv.cv_results_['mean_test_score'].max():.6f}")
        print(f"    Optimal n_features: {rfecv.n_features_}")
        print(f"    Time: {rfecv_time:.1f}s")
        
        # Save RFECV results
        rank_df = pd.DataFrame({
            'feature': X_station.columns,
            'rank': rfecv.ranking_,
            'selected': rfecv.support_
        }).sort_values('rank')
        rank_df.to_csv('../predict_score_red/RFECV_ranking_gpu_v2.txt', sep=' ', index=False)
        print(f"    ✓ Saved ranking to: ../predict_score_red/RFECV_ranking_gpu_v2.txt")
        
        # Save CV curve
        cvres = rfecv.cv_results_
        if 'n_features' in cvres:
            nfeat = np.array(cvres['n_features']).astype(int)
        else:
            nfeat = np.arange(len(cvres['mean_test_score']), 0, -1).astype(int)
        
        curve_df = pd.DataFrame({
            'num_features': nfeat,
            'mean_test_score': cvres['mean_test_score'],
            'std_test_score': cvres['std_test_score']
        }).sort_values('num_features')
        curve_df.to_csv('../predict_score_red/RFECV_curve_gpu_v2.txt', sep=' ', index=False)
        print(f"    ✓ Saved CV curve to: ../predict_score_red/RFECV_curve_gpu_v2.txt")
        
        print(f"\n✓ STEP 2 Complete: {len(static_decorrelated)} → {len(static_final)} features")
        
        del X_station, Y_station, rfecv, rank_df, curve_df
        gc.collect()
    else:
        static_final = []
        print("  No features available for RFECV")
        
else:
    print("\n" + "-"*100)
    print("STEP 2: RFECV SKIPPED (USE_RFECV=False)")
    print("-"*100)
    print("  Using all Spearman-decorrelated features")
    print("  This is more appropriate for LSTM temporal prediction")
    print("-"*100)
    
    static_final = static_decorrelated
    print(f"\n✓ STEP 2 Complete: Using all {len(static_final)} decorrelated features")

# -------------------------------------------------------------------------
# FEATURE SELECTION SUMMARY
# -------------------------------------------------------------------------
print(f"\n{'='*100}")
print("FEATURE SELECTION SUMMARY")
print(f"{'='*100}")
print(f"Method: Spearman decorrelation (ρ={SPEARMAN_STATION_THRESHOLD}) " + 
      (f"+ RFECV (station-level)" if USE_RFECV else "+ No RFECV"))
print(f"Dynamic features: {len(dynamic_final)} (all area-normalized)")
print(f"Static features:  {len(static_final)} (after {'Spearman + RFECV' if USE_RFECV else 'Spearman only'})")
print(f"Total features:   {len(dynamic_final) + len(static_final)}")
print(f"{'='*100}")

# =========================================================================
# PHASE 2: TEMPORAL SPLIT
# =========================================================================
print("\n" + "="*100)
print("PHASE 2: TEMPORAL SPLIT")
print("="*100)

min_year = Y['YYYY'].min()
max_year = Y['YYYY'].max()

if max_year - min_year + 1 < TRAIN_YEARS + TEST_YEARS:
    TRAIN_YEARS = int((max_year - min_year + 1) * 0.5)
    TEST_YEARS = (max_year - min_year + 1) - TRAIN_YEARS

TRAIN_START = min_year
TRAIN_END = TRAIN_START + TRAIN_YEARS - 1
TEST_START = TRAIN_END + 1
TEST_END = TEST_START + TEST_YEARS - 1

print(f"Train: {TRAIN_START}-{TRAIN_END} ({TRAIN_YEARS} years)")
print(f"Test:  {TEST_START}-{TEST_END} ({TEST_YEARS} years)")

train_mask = (X['YYYY'] >= TRAIN_START) & (X['YYYY'] <= TRAIN_END)
test_mask = (X['YYYY'] >= TEST_START) & (X['YYYY'] <= TEST_END)

X_train = X[train_mask].copy().reset_index(drop=True)
Y_train = Y[train_mask].copy().reset_index(drop=True)
X_test = X[test_mask].copy().reset_index(drop=True)
Y_test = Y[test_mask].copy().reset_index(drop=True)

print(f"Train: {X_train.shape}, Stations: {X_train['IDr'].nunique()}")
print(f"Test:  {X_test.shape}, Stations: {X_test['IDr'].nunique()}")

del X, Y, train_mask, test_mask
gc.collect()

# =========================================================================
# PHASE 4: DATA PREPARATION
# =========================================================================
print("\n" + "="*100)
print("PHASE 4: DATA PREPARATION")
print("="*100)

def clean_data(df):
    return df.replace([np.inf, -np.inf], np.nan).fillna(df.median(numeric_only=True))

X_train_dyn = clean_data(X_train[dynamic_final]).astype('float32')
X_test_dyn = clean_data(X_test[dynamic_final]).astype('float32')

if len(static_final) > 0:
    X_train_sta = clean_data(X_train[static_final]).astype('float32')
    X_test_sta = clean_data(X_test[static_final]).astype('float32')
else:
    X_train_sta = pd.DataFrame(np.zeros((len(X_train), 0), dtype=np.float32))
    X_test_sta = pd.DataFrame(np.zeros((len(X_test), 0), dtype=np.float32))

Y_train_qdf = clean_data(Y_train[q_cols]).astype('float32')
Y_test_qdf = clean_data(Y_test[q_cols]).astype('float32')

print("Scaling...")

qt_dyn = QuantileTransformer(n_quantiles=min(2000, len(X_train_dyn)), 
                             output_distribution='normal', random_state=RANDOM_STATE)
qt_y = QuantileTransformer(n_quantiles=min(2000, len(Y_train_qdf)), 
                           output_distribution='normal', random_state=RANDOM_STATE)

X_train_dyn_s = qt_dyn.fit_transform(X_train_dyn.to_numpy()).astype('float32')
X_test_dyn_s = qt_dyn.transform(X_test_dyn.to_numpy()).astype('float32')

if len(static_final) > 0:
    qt_sta = QuantileTransformer(n_quantiles=min(2000, len(X_train_sta)), 
                                 output_distribution='normal', random_state=RANDOM_STATE)
    X_train_sta_s = qt_sta.fit_transform(X_train_sta.to_numpy()).astype('float32')
    X_test_sta_s = qt_sta.transform(X_test_sta.to_numpy()).astype('float32')
else:
    X_train_sta_s = np.zeros((len(X_train_dyn_s), 0), dtype=np.float32)
    X_test_sta_s = np.zeros((len(X_test_dyn_s), 0), dtype=np.float32)

Y_train_s = qt_y.fit_transform(Y_train_qdf.to_numpy()).astype('float32')
Y_test_s = qt_y.transform(Y_test_qdf.to_numpy()).astype('float32')

del X_train_dyn, X_test_dyn, X_train_sta, X_test_sta
gc.collect()

print("✓ Scaling complete")

# Build sequences
print("\nBuilding sequences...")

def build_sequences(df_meta, X_dyn, X_sta, Y):
    df = df_meta.copy().sort_values(['IDr', 'YYYY', 'MM']).reset_index(drop=True)
    
    X_seq_dyn, X_seq_sta, Y_last, idx_last = [], [], [], []
    
    for idr, group in df.groupby('IDr'):
        indices = group.index.tolist()
        n = len(indices)
        
        if n < SEQ_LEN:
            continue
        
        for j in range(SEQ_LEN - 1, n):
            w0 = j - (SEQ_LEN - 1)
            seq_idx = indices[w0:j+1]
            
            X_seq_dyn.append(X_dyn[seq_idx])
            X_seq_sta.append(X_sta[indices[j]])
            Y_last.append(Y[indices[j]])
            idx_last.append(indices[j])
    
    return (
        np.array(X_seq_dyn, dtype=np.float32),
        np.array(X_seq_sta, dtype=np.float32),
        np.array(Y_last, dtype=np.float32),
        np.array(idx_last, dtype=np.int64)
    )

Xtr_meta = X_train[['IDr', 'YYYY', 'MM']]
Xte_meta = X_test[['IDr', 'YYYY', 'MM']]

Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq, tr_idx = build_sequences(Xtr_meta, X_train_dyn_s, X_train_sta_s, Y_train_s)
Xte_seq_dyn, Xte_seq_sta, Yte_seq, te_idx = build_sequences(Xte_meta, X_test_dyn_s, X_test_sta_s, Y_test_s)

print(f"Train sequences: {Xtr_seq_dyn.shape[0]:,}")
print(f"Test sequences: {Xte_seq_dyn.shape[0]:,}")

Ytr_true = Y_train_qdf.to_numpy()[tr_idx]
Yte_true = Y_test_qdf.to_numpy()[te_idx]

del X_train_dyn_s, X_train_sta_s, Y_train_s, X_test_dyn_s, X_test_sta_s, Y_test_s
gc.collect()

# =========================================================================
# PRINT VARIABLES
# =========================================================================
print("\n" + "="*100)
print("LSTM INPUT VARIABLES")
print("="*100)

print(f"\nDYNAMIC ({len(dynamic_final)}):")
for i, v in enumerate(dynamic_final, 1):
    print(f"  {i:2d}. {v}")

print(f"\nSTATIC ({len(static_final)}):")
if len(static_final) > 0:
    for i, v in enumerate(sorted(static_final), 1):
        print(f"  {i:2d}. {v}")
else:
    print("  (None)")

print(f"\nTARGETS ({len(q_cols)}): {', '.join(q_cols)}")
print(f"\nShapes: Train {Xtr_seq_dyn.shape}, Test {Xte_seq_dyn.shape}")

# =========================================================================
# LSTM MODEL WITH GPU OPTIMIZATION
# =========================================================================
print("\n" + "="*100)
print("LSTM TRAINING (GPU-ACCELERATED)")
print("="*100)

class LSTMWithContext(nn.Module):
    def __init__(self, n_dyn, n_sta, hidden=128, num_layers=2, dropout=0.2, out_dim=11):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=n_dyn,
            hidden_size=hidden,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0.0,
            bidirectional=False
        )
        self.static_encoder = nn.Sequential(
            nn.Linear(n_sta, 64),
            nn.ReLU(),
            nn.Dropout(0.1)
        ) if n_sta > 0 else None
        
        fusion_dim = hidden + (64 if n_sta > 0 else 0)
        self.head = nn.Sequential(
            nn.Linear(fusion_dim, 256),
            nn.ReLU(),
            nn.Dropout(0.2),
            nn.Linear(256, out_dim)
        )

    def forward(self, x_dyn, x_sta):
        out, _ = self.lstm(x_dyn)
        h_last = out[:, -1, :]
        if self.static_encoder is not None and x_sta.shape[1] > 0:
            sta_encoded = self.static_encoder(x_sta)
            z = torch.cat([h_last, sta_encoded], dim=1)
        else:
            z = h_last
        return self.head(z)

class LSTMDataset(Dataset):
    def __init__(self, X_dyn, X_sta, Y):
        self.X_dyn = torch.from_numpy(X_dyn)
        self.X_sta = torch.from_numpy(X_sta)
        self.Y = torch.from_numpy(Y)

    def __len__(self):
        return len(self.X_dyn)

    def __getitem__(self, idx):
        return self.X_dyn[idx], self.X_sta[idx], self.Y[idx]

train_ds = LSTMDataset(Xtr_seq_dyn, Xtr_seq_sta, Ytr_seq)
test_ds = LSTMDataset(Xte_seq_dyn, Xte_seq_sta, Yte_seq)

train_loader = DataLoader(
    train_ds, 
    batch_size=BATCH_SIZE, 
    shuffle=True, 
    num_workers=NUM_WORKERS_DATALOADER,
    pin_memory=True,
    persistent_workers=True if NUM_WORKERS_DATALOADER > 0 else False
)
test_loader = DataLoader(
    test_ds, 
    batch_size=BATCH_SIZE, 
    shuffle=False, 
    num_workers=NUM_WORKERS_DATALOADER,
    pin_memory=True,
    persistent_workers=True if NUM_WORKERS_DATALOADER > 0 else False
)

n_dyn = Xtr_seq_dyn.shape[2]
n_sta = Xtr_seq_sta.shape[1]

model = LSTMWithContext(n_dyn, n_sta, 128, 2, 0.2, len(q_cols)).to(DEVICE)
opt = torch.optim.Adam(model.parameters(), lr=LR)
loss_fn = nn.SmoothL1Loss()

scaler = GradScaler() if USE_MIXED_PRECISION and torch.cuda.is_available() else None

total_params = sum(p.numel() for p in model.parameters())
print(f"Model parameters: {total_params:,}")
print(f"Device: {DEVICE}")

if torch.cuda.is_available():
    print(f"GPU memory after model load: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB")

def run_epoch(loader, train=True):
    model.train() if train else model.eval()
    losses, preds = [], []

    for x_dyn, x_sta, y in loader:
        x_dyn = x_dyn.to(DEVICE, non_blocking=True)
        x_sta = x_sta.to(DEVICE, non_blocking=True)
        y = y.to(DEVICE, non_blocking=True)

        if train:
            opt.zero_grad(set_to_none=True)

        if USE_MIXED_PRECISION and scaler is not None:
            with autocast():
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
            
            if train:
                scaler.scale(loss).backward()
                scaler.unscale_(opt)
                nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler.step(opt)
                scaler.update()
        else:
            with torch.set_grad_enabled(train):
                pred = model(x_dyn, x_sta)
                loss = loss_fn(pred, y)
                if train:
                    loss.backward()
                    nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                    opt.step()

        losses.append(loss.item())
        preds.append(pred.detach().cpu().numpy())

    p_all = np.concatenate(preds) if preds else np.zeros((0, len(q_cols)), dtype=np.float32)
    return np.mean(losses) if losses else np.nan, p_all

print("\nTraining:")
best_val = np.inf
best_state = None

for ep in range(1, EPOCHS + 1):
    tr_loss, _ = run_epoch(train_loader, True)
    te_loss, _ = run_epoch(test_loader, False)

    if te_loss < best_val:
        best_val = te_loss
        best_state = {k: v.cpu().clone() for k, v in model.state_dict().items()}

    if ep == 1 or ep % 10 == 0 or ep == EPOCHS:
        print(f'Epoch {ep:3d} | train={tr_loss:.5f} | test={te_loss:.5f} | best={best_val:.5f}')
        if torch.cuda.is_available():
            print(f'  GPU mem: {torch.cuda.memory_allocated(0) / 1e9:.2f} GB')

if best_state:
    model.load_state_dict(best_state)

print(f"\n✓ Complete. Best loss: {best_val:.5f}")

# Predictions
_, Ptr = run_epoch(train_loader, False)
_, Pte = run_epoch(test_loader, False)

Q_train_pred = qt_y.inverse_transform(Ptr).astype('float32')
Q_test_pred = qt_y.inverse_transform(Pte).astype('float32')

# =========================================================================
# METRICS
# =========================================================================
print("\n" + "="*100)
print("PERFORMANCE")
print("="*100)

def kge_1d(y_true, y_pred):
    if np.all(y_true == y_true[0]) or len(y_true) < 2:
        return np.nan
    r = np.corrcoef(y_true, y_pred)[0, 1] if np.std(y_true) > 0 and np.std(y_pred) > 0 else np.nan
    beta = np.mean(y_pred) / np.mean(y_true) if np.mean(y_true) != 0 else np.nan
    gamma = np.std(y_pred) / np.std(y_true) if np.std(y_true) != 0 else np.nan
    if np.isnan(r) or np.isnan(beta) or np.isnan(gamma):
        return np.nan
    return 1 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)

def compute_metrics(Y_true, Y_pred):
    metrics = {}
    for i in range(len(q_cols)):
        try:
            metrics.setdefault('r', []).append(pearsonr(Y_pred[:, i], Y_true[:, i])[0])
            metrics.setdefault('nse', []).append(1 - np.sum((Y_true[:, i] - Y_pred[:, i])**2) / np.sum((Y_true[:, i] - np.mean(Y_true[:, i]))**2))
            metrics.setdefault('kge', []).append(kge_1d(Y_true[:, i], Y_pred[:, i]))
        except:
            metrics.setdefault('r', []).append(np.nan)
            metrics.setdefault('nse', []).append(np.nan)
            metrics.setdefault('kge', []).append(np.nan)
    
    return {k: (np.nanmean(v), v) for k, v in metrics.items()}

train_metrics = compute_metrics(Ytr_true, Q_train_pred)
test_metrics = compute_metrics(Yte_true, Q_test_pred)

print(f"\nTRAIN: r={train_metrics['r'][0]:.4f}, NSE={train_metrics['nse'][0]:.4f}, KGE={train_metrics['kge'][0]:.4f}")
print(f"TEST:  r={test_metrics['r'][0]:.4f}, NSE={test_metrics['nse'][0]:.4f}, KGE={test_metrics['kge'][0]:.4f}")

quantile_perf = pd.DataFrame({
    'Quantile': q_cols,
    'r': test_metrics['r'][1],
    'NSE': test_metrics['nse'][1],
    'KGE': test_metrics['kge'][1]
}).round(4)
print(f"\n{quantile_perf.to_string(index=False)}")

# Save
output_suffix = '_rfecv' if USE_RFECV else '_no_rfecv'
np.savetxt(f'../predict_prediction_red/LSTM_train_gpu_v2{output_suffix}.txt', Q_train_pred, fmt='%.6f', header=' '.join(q_cols), comments='')
np.savetxt(f'../predict_prediction_red/LSTM_test_gpu_v2{output_suffix}.txt', Q_test_pred, fmt='%.6f', header=' '.join(q_cols), comments='')

with open(f'../predict_importance_red/LSTM_features_gpu_v2{output_suffix}.txt', 'w') as f:
    f.write(f'GPU: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else "N/A"}\n')
    f.write(f'Batch size: {BATCH_SIZE}, Mixed precision: {USE_MIXED_PRECISION}\n')
    f.write(f'Feature selection: Spearman (ρ={SPEARMAN_STATION_THRESHOLD}) + {"RFECV (station-level)" if USE_RFECV else "No RFECV"}\n\n')
    f.write(f'DYNAMIC ({len(dynamic_final)})\n')
    for d in dynamic_final:
        f.write(f'{d}\n')
    f.write(f'\nSTATIC ({len(static_final)})\n')
    for s in sorted(static_final):
        f.write(f'{s}\n')
    f.write(f'\nTRAIN: r={train_metrics["r"][0]:.4f}, NSE={train_metrics["nse"][0]:.4f}, KGE={train_metrics["kge"][0]:.4f}\n')
    f.write(f'TEST:  r={test_metrics["r"][0]:.4f}, NSE={test_metrics["nse"][0]:.4f}, KGE={test_metrics["kge"][0]:.4f}\n')

print(f"\n✓ Outputs saved with suffix '{output_suffix}'")
print(f"✓ Complete: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

EOFPYTHON

echo ""
echo "=== GPU INFO AFTER TRAINING ==="
nvidia-smi
echo "================================"
