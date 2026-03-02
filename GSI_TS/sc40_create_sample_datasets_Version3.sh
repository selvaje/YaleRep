#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 01:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/create_sample_datasets.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/create_sample_datasets.err
#SBATCH --job-name=sample_datasets
#SBATCH --mem=100G

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv

# ============================================================================
# PARAMETERIZED SAMPLING
# ============================================================================

SAMPLE_FRACTIONS="0.002"

# Loop through each sample fraction
for SAMPLE_PCT in $SAMPLE_FRACTIONS; do
    echo ""
    echo "========================================"
    echo "Creating ${SAMPLE_PCT}% sample dataset"
    echo "========================================"
    
    # ✓ EXPORT the variable so it's available in the subshell
    export SAMPLE_PCT
    
    apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:\$PATH" \
     --env=SAMPLE_PCT="$SAMPLE_PCT" \
     /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif bash -c "

python3 <<EOF
import os
import gc
import warnings
import numpy as np
import pandas as pd
import time

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

# ============================================================================
# CONFIGURATION - Read from environment variable
# ============================================================================

SAMPLE_PCT_STR = os.environ['SAMPLE_PCT']
SAMPLE_FRACTION = float(SAMPLE_PCT_STR) / 100.0
SAMPLE_PCT = float(SAMPLE_PCT_STR)
RANDOM_STATE = 30
CHUNK_SIZE = 200000

print('='*130)
print(f'STRATIFIED SAMPLING (SINGLE-PASS): Creating {SAMPLE_PCT}% sample')
print(f'Sample fraction: {SAMPLE_FRACTION:.6f}')
print(f'Environment SAMPLE_PCT: {SAMPLE_PCT_STR}')
print('='*130)

start_time = time.time()

# Data types
dtypes_X = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int16', 'MM': 'int8',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
}

climate_soil_cols = [
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
]

dtypes_X.update({col: 'int16' for col in climate_soil_cols})

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

dtypes_X.update({col: 'float32' for col in feature_cols})

dtypes_Y = {
    'IDs': 'int32', 'IDr': 'int32', 'YYYY': 'int16', 'MM': 'int8',
    'Xsnap': 'float32', 'Ysnap': 'float32', 'Xcoord': 'float32', 'Ycoord': 'float32',
}
dtypes_Y.update({col: 'float32' for col in ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']})

# ============================================================================
# SINGLE-PASS SAMPLING: Read once, sample on the fly
# ============================================================================

print(f'\n[STEP 1] Single-pass stratified sampling (SAMPLE_FRACTION={SAMPLE_FRACTION})...\n')

X_sample_list = []
Y_sample_list = []
total_rows_processed = 0
sampled_rows = 0
station_year_counts = {}
rng = np.random.RandomState(RANDOM_STATE)

# Read X and Y simultaneously in single pass
print('Opening files...')
X_file = pd.read_csv('stationID_x_y_valueALL_predictors_X_floredSFD.txt', 
                      header=0, sep='\s+', dtype=dtypes_X, 
                      chunksize=CHUNK_SIZE)
Y_file = pd.read_csv('stationID_x_y_valueALL_predictors_Y_floredSFD.txt', 
                      header=0, sep='\s+', dtype=dtypes_Y, 
                      chunksize=CHUNK_SIZE)

print('Starting sampling pass...\n')

for chunk_num, (X_chunk, Y_chunk) in enumerate(zip(X_file, Y_file)):
    # ✓ FIX: Sample within each chunk based on probability
    chunk_sample_mask = []
    
    for idx in range(len(X_chunk)):
        # Get row data
        row_X = X_chunk.iloc[idx]
        
        idr = int(row_X['IDr'])
        yyyy = int(row_X['YYYY'])
        key = (idr, yyyy)
        
        # Track counts per station-year
        if key not in station_year_counts:
            station_year_counts[key] = 0
        station_year_counts[key] += 1
        
        # Probability-based sampling
        if rng.rand() < SAMPLE_FRACTION:
            chunk_sample_mask.append(True)
            sampled_rows += 1
        else:
            chunk_sample_mask.append(False)
        
        total_rows_processed += 1
    
    # Extract sampled rows
    chunk_sample_mask = np.array(chunk_sample_mask)
    if chunk_sample_mask.sum() > 0:
        X_sample_list.append(X_chunk[chunk_sample_mask])
        Y_sample_list.append(Y_chunk[chunk_sample_mask])
    
    if (chunk_num + 1) % 5 == 0:
        elapsed = time.time() - start_time
        print(f'  Chunk {chunk_num + 1}: Processed {total_rows_processed:,} rows, sampled {sampled_rows:,} ({elapsed:.1f}s)')
    
    gc.collect()

# Concatenate sampled data
if X_sample_list:
    X_sample = pd.concat(X_sample_list, ignore_index=True)
    Y_sample = pd.concat(Y_sample_list, ignore_index=True)
else:
    raise RuntimeError('No samples extracted!')

print(f'\n✓ Sampling complete:')
print(f'  Total rows processed: {total_rows_processed:,}')
print(f'  Sample rows extracted: {len(X_sample):,}')
print(f'  Actual sample fraction: {len(X_sample) / total_rows_processed * 100:.4f}%')
print(f'  Unique station-years: {len(station_year_counts)}')

elapsed = time.time() - start_time
print(f'Time elapsed: {elapsed:.1f}s')

# ============================================================================
# VALIDATION
# ============================================================================

print('\n[STEP 2] Validating sample...\n')

y_quantiles = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']
x_dynamic = ['ppt0', 'ppt1', 'ppt2', 'ppt3', 'tmin0', 'tmin1', 'tmin2', 'tmin3']

print('Sample Y statistics:')
print(f'Quantile     Mean         Std')
print('-'*40)
for col in y_quantiles:
    col_mean = Y_sample[col].mean()
    col_std = Y_sample[col].std()
    print(f'{col:<12} {col_mean:>12.2f} {col_std:>12.2f}')

print(f'\nSample X statistics:')
print(f'Variable     Mean         Std')
print('-'*40)
for col in x_dynamic:
    col_mean = X_sample[col].mean()
    col_std = X_sample[col].std()
    print(f'{col:<12} {col_mean:>12.2f} {col_std:>12.2f}')

print(f'\nSpatial summary:')
xcoord_min = X_sample['Xcoord'].min()
xcoord_max = X_sample['Xcoord'].max()
ycoord_min = X_sample['Ycoord'].min()
ycoord_max = X_sample['Ycoord'].max()
n_stations = X_sample['IDr'].nunique()
n_years = X_sample['YYYY'].nunique()

print(f'  X range: {xcoord_min:.2f} - {xcoord_max:.2f}')
print(f'  Y range: {ycoord_min:.2f} - {ycoord_max:.2f}')
print(f'  Stations: {n_stations}')
print(f'  Years: {n_years}')

elapsed = time.time() - start_time
print(f'Time elapsed: {elapsed:.1f}s')

# ============================================================================
# SAVE SAMPLE FILES
# ============================================================================

print('\n[STEP 3] Saving sample datasets...\n')

filename_suffix = f'{SAMPLE_PCT}pct'
X_filename = f'Xsample_{filename_suffix}_b.txt'
Y_filename = f'Ysample_{filename_suffix}_b.txt'

fmt_x = ' '.join(['%.f' if X_sample[col].dtype in ['int32', 'int16', 'int8'] else '%.4f' for col in X_sample.columns])
X_column_names_str = ' '.join(X_sample.columns)

np.savetxt(X_filename,
           X_sample.values,
           delimiter=' ',
           fmt=fmt_x,
           header=X_column_names_str,
           comments='')

X_filesize = os.path.getsize(X_filename) / 1024**3
print(f'✓ Saved: {X_filename} ({X_sample.shape[0]:,} rows, {X_filesize:.2f} GB)')

fmt_y = '%i %f %f %i %f %f %i %i %f %f %f %f %f %f %f %f %f %f %f'
Y_column_names_str = ' '.join(Y_sample.columns)

np.savetxt(Y_filename,
           Y_sample.values,
           delimiter=' ',
           fmt=fmt_y,
           header=Y_column_names_str,
           comments='')

Y_filesize = os.path.getsize(Y_filename) / 1024**3
print(f'✓ Saved: {Y_filename} ({Y_sample.shape[0]:,} rows, {Y_filesize:.2f} GB)')

elapsed = time.time() - start_time
print(f'Time elapsed: {elapsed:.1f}s')

# ============================================================================
# SUMMARY
# ============================================================================

print('\n[FINAL SUMMARY]\n')

total_time = time.time() - start_time
total_minutes = total_time / 60

print(f'✓ SAMPLING COMPLETE in {total_time:.1f} seconds ({total_minutes:.1f} minutes)')
print(f'\nFiles created:')
print(f'  - {X_filename}: {X_filesize:.2f} GB ({X_sample.shape[0]:,} rows)')
print(f'  - {Y_filename}: {Y_filesize:.2f} GB ({Y_sample.shape[0]:,} rows)')

print(f'\nSample metadata:')
print(f'  - Requested fraction: {SAMPLE_PCT}%')
print(f'  - Actual fraction: {len(X_sample) / total_rows_processed * 100:.4f}%')
print(f'  - Stations: {n_stations}')
print(f'  - Years: {n_years}')
print(f'\n✓ Sample dataset ready for RF modeling!')

gc.collect()

EOF
    "
    
    echo ""
    echo "✓ Completed ${SAMPLE_PCT}% sample"
    echo ""

done

echo ""
echo "================================="
echo "✓ ALL SAMPLE DATASETS CREATED"
echo "================================="
echo ""
ls -lh extract4py_red/Xsample_*.txt extract4py_red/Ysample_*.txt 2>/dev/null
echo ""
wc -l extract4py_red/Xsample_*.txt extract4py_red/Ysample_*.txt 2>/dev/null
