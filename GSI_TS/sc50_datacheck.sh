#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc31_modeling-pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc31_modeling_pythonALL_RFrunMainRespRenkOptimSnapCor.sh.%A_%a.err
#SBATCH --job-name=sc31_SnapCorRFas30_flowred_OOB.sh
#SBATCH --mem=1200G

####   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc50_datacheck.sh 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract4py_red
cd $EXTRACT

module load StdEnv

apptainer exec --env=PATH="/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo-stuff/pyjeovenv/bin:$PATH"  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/pyjeo2.sif  bash -c "

python3 <<'EOF'
import os
import re
import numpy as np
import pandas as pd
from collections import Counter

# === EDIT THESE PATHS to your files ===
X_path = 'stationID_x_y_valueALL_predictors_X.txt'
Y_path = 'stationID_x_y_valueALL_predictors_Y.txt'
RAW_path = '/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract_red/stationID_x_y_valueALL_predictors.txt'
# ======================================

def head_lines(path, n=5):
    with open(path, 'rt') as f:
        lines = [next(f) for _ in range(n)]
    return lines

def token_count_distribution(path, n_sample_lines=200000):
    ## Count number of tokens per line (sample up to n_sample_lines).
    cnt = Counter()
    with open(path, 'rt') as f:
        # skip header if it looks like a header (non-numeric first field)
        first = next(f)
        if re.search(r'[A-Za-z]', first.split()[0]):
            # header present; include it in header count but sample from next lines
            pass
        else:
            # first line is data: count it
            cnt[len(re.split(r'\s+', first.strip()))] += 1
        for i, line in enumerate(f):
            if i >= n_sample_lines:
                break
            if not line.strip():
                cnt[0] += 1
            else:
                tok = re.split(r'\s+', line.strip())
                cnt[len(tok)] += 1
    return cnt

def stream_compare_first_tokens(xpath, ypath, n_check_mismatches=20):
    
    # Compare the first 8 tokens of each line in X & Y (streaming).
    # Prints the first n_check_mismatches mismatches and returns total mismatches.
    
    mismatches = 0
    with open(xpath, 'rt') as fx, open(ypath, 'rt') as fy:
        # read headers (assume first line is header)
        header_x = fx.readline().rstrip('\n')
        header_y = fy.readline().rstrip('\n')
        print('Header X tokens (first 10):', re.split(r'\s+', header_x.strip())[:10])
        print('Header Y tokens (first 10):', re.split(r'\s+', header_y.strip())[:10])

        for lineno, (lx, ly) in enumerate(zip(fx, fy), start=2):
            tx = re.split(r'\s+', lx.strip())
            ty = re.split(r'\s+', ly.strip())
            # compare first 8 tokens (IDs, IDr, YYYY, MM, coords etc)
            if tx[:8] != ty[:8]:
                mismatches += 1
                if mismatches <= n_check_mismatches:
                    print(f'Line {lineno} mismatch (first 8 tokens):')
                    print('  X:', tx[:8])
                    print('  Y:', ty[:8])
            if lineno % 1000000 == 0:
                print(f'... checked {lineno} lines, mismatches so far: {mismatches}')
    # Check if one file longer
    len_x = sum(1 for _ in open(xpath)) + 1  # +1 because we already consumed header earlier
    len_y = sum(1 for _ in open(ypath)) + 1
    print('Note: fast check of leftover lines (may not be precise if headers):', len_x, len_y)
    return mismatches

def pandas_quick_checks(xpath, ypath, nrows=1000000):
    # Read first nrows with pandas (fast) and check ID columns alignment and dtypes.
    usecols = None  # read all columns in check
    print(f'\nReading first {nrows} rows from each file with pandas (this is fast and partial)...')
    X = pd.read_csv(xpath, sep=r'\s+', header=0, nrows=nrows, engine='c', low_memory=False)
    Y = pd.read_csv(ypath, sep=r'\s+', header=0, nrows=nrows, engine='c', low_memory=False)
    print('Shapes (sample):', X.shape, Y.shape)
    idcols = []
    for c in ['IDs','IDr','YYYY','MM']:
        if c in X.columns and c in Y.columns:
            idcols.append(c)
    if not idcols:
        print('No ID columns found by pandas in these files (check headers).')
        return X, Y
    print('Comparing id columns:', idcols)
    for c in idcols:
        seq_eq = (X[c].values == Y[c].values).all()
        print(f'  {c}: equal in sample? {seq_eq} (dtype X:{X[c].dtype} Y:{Y[c].dtype})')
        if not seq_eq:
            # show first few mismatches
            mismatch_idx = np.where(X[c].values != Y[c].values)[0][:10]
            print('    first mismatched indices:', mismatch_idx)
            for idx in mismatch_idx:
                print('     i', idx, 'X', X.loc[idx, idcols].to_dict(), 'Y', Y.loc[idx, idcols].to_dict())
    return X, Y

def check_pandas_train_test_alignment(Xfull, Yfull, train_ids):
    
    # Given full pandas X and Y and list/Series train_ids (IDr assigned to train),
    # check that after filtering rows for same IDr, the group-by order (IDs,YYYY,MM)
    # for each IDr are identical between X_train and Y_train.
    
    Xtrain = Xfull[Xfull['IDr'].isin(train_ids)].copy()
    Ytrain = Yfull[Yfull['IDr'].isin(train_ids)].copy()

    # sort both by same keys
    sort_keys = ['IDr','YYYY','MM','IDs']
    for k in sort_keys:
        if k not in Xtrain.columns or k not in Ytrain.columns:
            raise RuntimeError(f'Missing key {k} in one DataFrame.')
    Xtrain = Xtrain.sort_values(by=sort_keys).reset_index(drop=True)
    Ytrain = Ytrain.sort_values(by=sort_keys).reset_index(drop=True)

    # now compare the id columns for equality
    idcols = ['IDs','IDr','YYYY','MM']
    eq_all = (Xtrain[idcols].values == Ytrain[idcols].values).all()
    if eq_all:
        print('PASS: X_train and Y_train id columns EXACTLY match after sorting by', sort_keys)
    else:
        print('FAIL: mismatch between X_train and Y_train after sorting.')
        # find first few mismatches
        idx = np.where(~(Xtrain[idcols].values == Ytrain[idcols].values).all(axis=1))[0][:10]
        print('First mismatched rows (indices):', idx)
        for i in idx:
            print(' X:', Xtrain.loc[i, idcols].to_dict(), 'Y:', Ytrain.loc[i, idcols].to_dict())

    return eq_all

def check_feature_cols_order_and_shapes(X_train_df, X_test_df, drop_cols):
    # Return ordered feature_cols and shapes for np arrays and compare.
    feature_cols = [c for c in X_train_df.columns if c not in drop_cols]
    # ensure same order in X_test:
    feature_cols_test = [c for c in X_test_df.columns if c not in drop_cols]
    equal_order = feature_cols == feature_cols_test
    print('feature_cols_count:', len(feature_cols), 'match X_test columns order?', equal_order)
    # shapes if we convert
    Xtr_np = X_train_df[feature_cols].to_numpy()
    Xte_np = X_test_df[feature_cols].to_numpy()
    print('X_train_np.shape:', Xtr_np.shape, 'X_test_np.shape:', Xte_np.shape)
    return feature_cols, equal_order

def post_prediction_checks(Y_true_np, Y_pred_np):
    print('Shapes: Y_true', Y_true_np.shape, 'Y_pred', Y_pred_np.shape)
    if Y_true_np.shape != Y_pred_np.shape:
        print('WARNING: shape mismatch between true & pred!')
    # check NaNs and variance per column
    for i in range(Y_true_np.shape[1]):
        tnan = np.isnan(Y_true_np[:,i]).sum()
        pnan = np.isnan(Y_pred_np[:,i]).sum()
        tstd = np.nanstd(Y_true_np[:,i])
        pstd = np.nanstd(Y_pred_np[:,i])
        print(f'col {i}: true NaN {tnan}, pred NaN {pnan}, true std {tstd:.6f}, pred std {pstd:.6f}')
    # check if any column is constant in y_true (pearson will be NaN)
    const_cols = [i for i in range(Y_true_np.shape[1]) if np.nanstd(Y_true_np[:,i])==0.0]
    if const_cols:
        print('Warning: these columns are constant in Y_true (pearson undefined):', const_cols)
    return

if __name__ == '__main__':
    print('>>> Token count distribution (sample) for X')
    print(token_count_distribution(X_path, n_sample_lines=200000))
    print('>>> Token count distribution (sample) for Y')
    print(token_count_distribution(Y_path, n_sample_lines=200000))
    print('\n>>> Streaming compare first tokens of X and Y (first 20 mismatches shown)')
    mism = stream_compare_first_tokens(X_path, Y_path, n_check_mismatches=20)
    print('Total streaming mismatches (first-8 tokens):', mism)

    # partial pandas read checks (first 1e6 rows)
    Xp, Yp = pandas_quick_checks(X_path, Y_path, nrows=500000)

    # If you have the full pd DataFrames loaded already (X_train, Y_train etc),
    # run `check_feature_cols_order_and_shapes` and `post_prediction_checks` after predictions.

    print('\nAll checks done. If you see mismatches above, re-create X/Y with a robust splitter (see recommendations).')


EOF
" ## close the sif
exit

