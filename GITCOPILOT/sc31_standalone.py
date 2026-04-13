#!/usr/bin/env python3
"""
Standalone sc31 modeling script.

Loads the 0.01% sample files from the GITCOPILOT directory and runs the
GroupAwareMultiOutput / RFECV variable-selection pipeline locally.
All results are written to the current working directory.

Usage:
    python3 sc31_standalone.py [--data-dir DIR]

    --data-dir  Directory containing Xsample_0.01pct.txt.asc and
                Ysample_0.01pct.txt.asc (default: directory of this script)
"""

import argparse
import gc
import os
import warnings

import numpy as np
import pandas as pd
from joblib import Parallel, delayed
from scipy.stats import pearsonr, spearmanr
from sklearn.base import BaseEstimator, RegressorMixin
from sklearn.cluster import KMeans
from sklearn.ensemble import ExtraTreesRegressor, RandomForestRegressor
from sklearn.feature_selection import RFECV
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import GroupKFold, train_test_split

warnings.filterwarnings('ignore')
pd.set_option('display.max_columns', None)

# ============================================================================
# CONFIGURATION (sensible defaults for local / small-data use)
# ============================================================================

N_EST_I    = 50       # number of trees
OBS_LEAF_I = 5        # min_samples_leaf
OBS_SPLIT_I = 10      # min_samples_split
DEPTH_I    = 15       # max_depth
SAMPLE_F   = 0.5      # max_features fraction
N_JOBS     = 4        # parallel workers (tune to local CPU count)

# ============================================================================
# STATIC / DYNAMIC VARIABLE LISTS
# (used only to classify columns found in the data – not to gate loading)
# ============================================================================

STATIC_VAR = {
    'cti', 'spi', 'sti', 'accumulation',
    'outlet_diff_dw_scatch', 'outlet_dist_dw_scatch',
    'stream_diff_dw_near', 'stream_diff_up_farth', 'stream_diff_up_near',
    'stream_dist_dw_near', 'stream_dist_proximity',
    'stream_dist_up_farth', 'stream_dist_up_near',
    'slope_curv_max_dw_cel', 'slope_curv_min_dw_cel',
    'slope_elv_dw_cel', 'slope_grad_dw_cel', 'channel_curv_cel',
    'channel_dist_dw_seg', 'channel_dist_up_cel', 'channel_dist_up_seg',
    'channel_elv_dw_cel', 'channel_elv_dw_seg', 'channel_elv_up_cel',
    'channel_elv_up_seg', 'channel_grad_dw_seg', 'channel_grad_up_cel',
    'channel_grad_up_seg', 'AWCtS', 'CLYPPT', 'SLTPPT', 'SNDPPT', 'WWP',
    'sand', 'silt', 'clay',
    'GRWLw', 'GRWLr', 'GRWLl', 'GRWLd', 'GRWLc',
    'GSWs', 'GSWr', 'GSWo', 'GSWe',
    'order_hack', 'order_horton', 'order_shreve', 'order_strahler', 'order_topo',
    'dx', 'dxx', 'dxy', 'dy', 'dyy', 'elev', 'aspect-cosine', 'aspect-sine',
    'convergence', 'dev-magnitude', 'dev-scale', 'eastness', 'elev-stdev',
    'northness', 'pcurv', 'rough-magnitude', 'roughness', 'rough-scale',
    'slope', 'tcurv', 'tpi', 'tri', 'vrm',
}

DYNAMIC_VAR = {
    'ppt0', 'ppt1', 'ppt2', 'ppt3',
    'tmin0', 'tmin1', 'tmin2', 'tmin3',
    'tmax0', 'tmax1', 'tmax2', 'tmax3',
    'swe0', 'swe1', 'swe2', 'swe3',
    'soil0', 'soil1', 'soil2', 'soil3',
}

META_COLS = {'IDs', 'IDr', 'YYYY', 'MM', 'Xsnap', 'Ysnap', 'Xcoord', 'Ycoord'}
TARGET_COLS = ['QMIN', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'QMAX']


# ============================================================================
# GROUPAWAREMULTIOUTPUT
# ============================================================================

class GroupAwareMultiOutput(BaseEstimator, RegressorMixin):
    """Multi-output regressor with group-aware OOB cross-validation."""

    def __init__(self, base_estimator, n_cv_folds=5, n_jobs=1, inner_n_jobs=1,
                 random_state=24, oob_metric='r2', verbose=0):
        self.base_estimator = base_estimator
        self.n_cv_folds = n_cv_folds
        self.n_jobs = n_jobs
        self.inner_n_jobs = inner_n_jobs
        self.random_state = random_state
        self.oob_metric = oob_metric
        self.verbose = verbose

        self.models_ = []
        self.oob_predictions_ = None
        self.oob_r2_per_target_ = None
        self.oob_r2_mean_ = None
        self.oob_scores_ = None
        self.final_importances_ = None
        self._groups = None
        self.X_column_names_ = None
        self._fitted = False

    def fit(self, X, Y, groups=None, X_column_names=None, do_oob_cv=True):
        X = np.asarray(X, dtype=np.float32)
        Y = np.asarray(Y, dtype=np.float32)

        if X_column_names is None:
            X_column_names = [f'feat_{i}' for i in range(X.shape[1])]
        self.X_column_names_ = list(X_column_names)

        if groups is not None:
            self._groups = np.asarray(groups, dtype=np.int32)

        n_samples = X.shape[0]
        n_targets = Y.shape[1] if Y.ndim == 2 else 1

        if groups is None or not bool(do_oob_cv):
            if self.verbose > 0:
                print('Fitting final model on all data (no OOB CV)')
            final_model = self.base_estimator(
                random_state=self.random_state, n_jobs=self.inner_n_jobs
            )
            final_model.fit(X, Y)
            self.models_ = [final_model]
            self._extract_importances(final_model)
            self.oob_predictions_ = np.full((n_samples, n_targets), np.nan, dtype=np.float32)
            self.oob_r2_per_target_ = np.array([np.nan] * n_targets)
            self.oob_r2_mean_ = np.nan
            self.oob_scores_ = np.array([np.nan] * n_targets)
            self._fitted = True
            return self

        if self._groups is None or self._groups.size == 0:
            raise ValueError('groups must be provided for group-aware OOB CV')

        n_unique_groups = len(np.unique(self._groups))
        n_splits = min(self.n_cv_folds, n_unique_groups)
        if n_splits < 2:
            print(f'WARNING: Only {n_unique_groups} unique groups; '
                  'falling back to no-OOB fit.')
            return self.fit(X, Y, groups=None, X_column_names=X_column_names,
                            do_oob_cv=False)

        gkf = GroupKFold(n_splits=n_splits)
        oob_preds = np.full((n_samples, n_targets), np.nan, dtype=np.float32)

        if self.verbose > 0:
            print(f'Running GroupKFold OOB CV with {n_splits} splits...')

        rng = np.random.RandomState(self.random_state)
        seeds = rng.randint(0, 100000, size=n_splits)

        def _fit_fold(fold_idx, train_idx, test_idx, seed):
            est = self.base_estimator(
                random_state=int(seed), n_jobs=self.inner_n_jobs
            )
            est.fit(X[train_idx], Y[train_idx])
            return test_idx, est.predict(X[test_idx])

        fold_results = Parallel(n_jobs=self.n_jobs, backend='threading',
                                verbose=max(0, self.verbose - 1))(
            delayed(_fit_fold)(i, trn, tst, seeds[i])
            for i, (trn, tst) in enumerate(
                gkf.split(X, y=Y, groups=self._groups))
        )

        for test_idx, preds in fold_results:
            oob_preds[test_idx] = preds

        self.oob_predictions_ = oob_preds
        self._compute_oob_scores(Y, oob_preds)

        if self.verbose > 0:
            print('Fitting final model on all data...')

        final_model = self.base_estimator(
            random_state=self.random_state, n_jobs=self.inner_n_jobs
        )
        final_model.fit(X, Y)
        self.models_ = [final_model]
        self._extract_importances(final_model)
        self._fitted = True

        if self.verbose > 0:
            print(f'OOB R² (mean): {self.oob_r2_mean_:.4f}')

        return self

    def _extract_importances(self, model):
        if hasattr(model, 'feature_importances_'):
            self.feature_importances_ = model.feature_importances_.astype(np.float32)
            self.final_importances_ = pd.Series(
                self.feature_importances_, index=self.X_column_names_
            ).sort_values(ascending=False)
        else:
            self.final_importances_ = None

    def _compute_oob_scores(self, Y_true, Y_pred_oob):
        n_targets = Y_true.shape[1]
        r2_list, score_list = [], []
        for i in range(n_targets):
            y_true = Y_true[:, i]
            y_pred = Y_pred_oob[:, i]
            valid = ~np.isnan(y_pred)
            if int(valid.sum()) < 2:
                r2_list.append(np.nan)
                score_list.append(np.nan)
                continue
            r2 = r2_score(y_true[valid], y_pred[valid])
            r2_list.append(r2)
            score_list.append(r2 if self.oob_metric == 'r2'
                              else np.sqrt(mean_squared_error(
                                  y_true[valid], y_pred[valid])))
        self.oob_r2_per_target_ = np.array(r2_list, dtype=np.float32)
        self.oob_r2_mean_ = float(np.nanmean(r2_list))
        self.oob_scores_ = np.array(score_list, dtype=np.float32)

    def predict(self, X):
        if not self._fitted or len(self.models_) == 0:
            raise ValueError('Model not fitted.')
        return self.models_[0].predict(X)

    def get_importances(self):
        return self.final_importances_

    def print_oob_summary(self):
        if self.oob_r2_per_target_ is None:
            print('Model not fitted yet or OOB not computed.')
            return
        print(f'Overall OOB R² (mean across targets): {self.oob_r2_mean_:.4f}')
        for lbl, val in zip(TARGET_COLS, self.oob_r2_per_target_):
            status = f'{val:.4f}' if not np.isnan(val) else 'nan'
            quality = ''
            if not np.isnan(val):
                if val >= 0.7:
                    quality = ' ✓ good'
                elif val >= 0.5:
                    quality = ' ~ acceptable'
                elif val >= 0.3:
                    quality = ' ↓ weak'
                else:
                    quality = ' ✗ poor'
            print(f'  {lbl:6s}: {status}{quality}')


# ============================================================================
# DECORRELATION HELPER
# ============================================================================

def decorrelate_group_fast(df, group_name, threshold=0.70, verbose=True):
    """Remove highly correlated features using Spearman correlation."""
    if df.empty or len(df.columns) <= 1:
        return df
    corr = df.corr(method='spearman').abs()
    upper = corr.where(np.triu(np.ones(corr.shape), k=1).astype(bool))
    to_drop = set()
    for col in upper.columns:
        for drop_col in upper.index[upper[col] > threshold].tolist():
            if drop_col not in to_drop and drop_col != col:
                to_drop.add(drop_col)
    kept = [c for c in df.columns if c not in to_drop]
    if verbose:
        print(f'  {group_name:20s}: {len(df.columns):3d} → {len(kept):3d} '
              f'(Spearman ρ > {threshold:.2f})')
    del corr, upper
    gc.collect()
    return df[kept]


# ============================================================================
# KGE METRIC
# ============================================================================

def kge(y_true, y_pred):
    r = np.corrcoef(y_true, y_pred)[0, 1]
    beta = np.mean(y_pred) / np.mean(y_true)
    gamma = np.std(y_pred) / np.std(y_true)
    return 1.0 - np.sqrt((r - 1)**2 + (beta - 1)**2 + (gamma - 1)**2)


# ============================================================================
# MAIN
# ============================================================================

def main(data_dir: str) -> None:
    print('=' * 70)
    print('sc31 standalone modeling script')
    print(f'Config: N_EST={N_EST_I}, leaf={OBS_LEAF_I}, split={OBS_SPLIT_I}, '
          f'depth={DEPTH_I}, sample={SAMPLE_F}')
    print('=' * 70)

    x_path = os.path.join(data_dir, 'Xsample_0.01pct.txt.asc')
    y_path = os.path.join(data_dir, 'Ysample_0.01pct.txt.asc')

    for p in (x_path, y_path):
        if not os.path.isfile(p):
            raise FileNotFoundError(f'Required sample file not found: {p}')

    # ------------------------------------------------------------------ #
    # DATA LOADING                                                        #
    # ------------------------------------------------------------------ #
    print('\nLoading X data...')
    X = pd.read_csv(x_path, sep=r'\s+', engine='python')
    print(f'  X shape: {X.shape}')

    print('Loading Y data...')
    Y = pd.read_csv(y_path, sep=r'\s+', engine='python')
    print(f'  Y shape: {Y.shape}')

    X = X.reset_index(drop=True)
    Y = Y.reset_index(drop=True)

    # ------------------------------------------------------------------ #
    # VARIABLE CLASSIFICATION (from actual columns)                       #
    # ------------------------------------------------------------------ #
    all_feature_cols = [c for c in X.columns if c not in META_COLS]
    static_present  = [c for c in all_feature_cols if c in STATIC_VAR]
    dynamic_present = [c for c in all_feature_cols if c in DYNAMIC_VAR]
    # Any remaining feature columns not in either set are treated as static
    extra_cols = [c for c in all_feature_cols
                  if c not in STATIC_VAR and c not in DYNAMIC_VAR]
    if extra_cols:
        print(f'  Extra feature columns treated as static: {extra_cols}')
        static_present = static_present + extra_cols

    print(f'\nFeature inventory:')
    print(f'  Static  variables present: {len(static_present)}')
    print(f'  Dynamic variables present: {len(dynamic_present)}')
    print(f'  Total feature columns    : {len(all_feature_cols)}')

    target_present = [c for c in TARGET_COLS if c in Y.columns]
    if not target_present:
        raise ValueError(f'No target columns found. Expected: {TARGET_COLS}')
    print(f'  Target  columns          : {len(target_present)}')

    # ------------------------------------------------------------------ #
    # STATION-LEVEL TRAIN / TEST SPLIT                                    #
    # Derive station coordinates directly from the data (IDr, Xcoord,    #
    # Ycoord).  Because the 0.01 % sample is very sparse (~1 obs/station) #
    # we simply split station IDs spatially via KMeans.                   #
    # ------------------------------------------------------------------ #
    print('\nDeriving station info from data...')
    stations = (X[['IDr', 'Xcoord', 'Ycoord']]
                .drop_duplicates(subset='IDr')
                .reset_index(drop=True))
    print(f'  Unique stations: {len(stations)}')

    n_clusters = min(10, max(2, len(stations) // 50))
    print(f'  KMeans n_clusters: {n_clusters}')
    kmeans = KMeans(n_clusters=n_clusters, random_state=24, n_init=10)
    stations = stations.copy()
    stations['cluster'] = kmeans.fit_predict(stations[['Xcoord', 'Ycoord']])

    cluster_counts = stations['cluster'].value_counts()
    sufficient = cluster_counts[cluster_counts > 1].index.values
    if len(sufficient) == 0:
        print('WARNING: No cluster has >1 station; using random 80/20 split.')
        train_idr, test_idr = train_test_split(
            stations['IDr'].values, test_size=0.2, random_state=24
        )
    else:
        stratify_stations = stations[stations['cluster'].isin(sufficient)].copy()
        train_stations, test_stations = train_test_split(
            stratify_stations,
            test_size=0.2,
            random_state=24,
            stratify=stratify_stations['cluster'],
        )
        singleton_idr = stations[~stations['cluster'].isin(sufficient)]['IDr'].values
        train_idr = np.concatenate([train_stations['IDr'].values, singleton_idr])
        test_idr  = test_stations['IDr'].values

    X_train = X[X['IDr'].isin(train_idr)].reset_index(drop=True)
    Y_train = Y[Y['IDr'].isin(train_idr)].reset_index(drop=True)
    X_test  = X[X['IDr'].isin(test_idr)].reset_index(drop=True)
    Y_test  = Y[Y['IDr'].isin(test_idr)].reset_index(drop=True)

    print(f'  Train: {X_train.shape[0]} rows, {X_train["IDr"].nunique()} stations')
    print(f'  Test : {X_test.shape[0]} rows, {X_test["IDr"].nunique()} stations')

    # ------------------------------------------------------------------ #
    # NUMPY ARRAYS FOR MODELING                                           #
    # ------------------------------------------------------------------ #
    drop_meta = [c for c in META_COLS if c in X_train.columns]

    X_train_np  = X_train.drop(columns=drop_meta).to_numpy(dtype='float32')
    Y_train_np  = Y_train[target_present].to_numpy(dtype='float32')
    X_test_np   = X_test.drop(columns=drop_meta).to_numpy(dtype='float32')
    Y_test_np   = Y_test[target_present].to_numpy(dtype='float32')
    groups_train = X_train['IDr'].to_numpy(dtype='int32')

    feat_names = np.array([c for c in X_train.columns if c not in META_COLS])
    print(f'\nFeature array shape : {X_train_np.shape}')
    print(f'Target  array shape : {Y_train_np.shape}')
    print(f'Unique train groups : {len(np.unique(groups_train))}')

    del X, Y, X_train, Y_train, X_test, Y_test
    gc.collect()

    # ------------------------------------------------------------------ #
    # FEATURE SELECTION                                                   #
    # ------------------------------------------------------------------ #
    print('\n' + '=' * 70)
    print('FEATURE SELECTION')
    print('=' * 70)

    static_idx  = [i for i, c in enumerate(feat_names) if c in static_present]
    dynamic_idx = [i for i, c in enumerate(feat_names) if c in dynamic_present]
    static_names_arr  = feat_names[static_idx]
    dynamic_names_arr = feat_names[dynamic_idx]

    # Sample for faster feature selection
    sample_size = min(50000, len(X_train_np))
    sample_idx = np.random.RandomState(24).choice(
        len(X_train_np), sample_size, replace=False)
    X_sample = X_train_np[sample_idx]
    Y_sample = Y_train_np[sample_idx]
    groups_sample = groups_train[sample_idx]

    print(f'Sampled {sample_size} rows for feature selection '
          f'(from {X_train_np.shape[0]} total)')

    # Decorrelate static features
    if len(static_idx) > 0:
        X_static_df = pd.DataFrame(
            X_sample[:, static_idx], columns=static_names_arr)
        static_dec_df = decorrelate_group_fast(
            X_static_df, 'Static', threshold=0.70, verbose=True)
        static_decorr = static_dec_df.columns.tolist()
    else:
        static_decorr = []

    if len(static_decorr) == 0:
        print('WARNING: No static vars after decorrelation. Using dynamic only.')
        selected_static = []
    else:
        static_dec_idx = [i for i, c in enumerate(feat_names)
                          if c in static_decorr]
        X_static_dec = X_sample[:, static_dec_idx]

        n_unique_gs = len(np.unique(groups_sample))
        rfecv_cv_folds = min(3, n_unique_gs)

        step_size   = max(1, int(len(static_decorr) * 0.40))
        min_feats   = max(2, int(len(static_decorr) * 0.20))

        print(f'\nRunning RFECV on {X_static_dec.shape[1]} decorrelated static '
              f'features, {rfecv_cv_folds}-fold GroupKFold...')

        selector = RFECV(
            estimator=ExtraTreesRegressor(
                n_estimators=30,
                max_depth=10,
                n_jobs=1,
                random_state=24,
                min_samples_leaf=3,
                min_samples_split=6,
            ),
            step=step_size,
            min_features_to_select=min_feats,
            cv=GroupKFold(n_splits=rfecv_cv_folds),
            scoring='r2',
            n_jobs=N_JOBS,
            verbose=0,
        )
        selector.fit(X_static_dec, Y_sample, groups=groups_sample)

        support      = selector.support_
        rankings     = selector.ranking_
        selected_static = np.array(static_decorr)[support].tolist()

        rfecv_df = pd.DataFrame({
            'Feature'        : static_decorr,
            'Selected'       : support,
            'Rank'           : rankings,
            'Survival_Score' : rankings.max() - rankings + 1,
        }).sort_values('Rank').reset_index(drop=True)

        max_rank = rfecv_df['Rank'].max()

        def _interpret(row):
            if row['Rank'] == 1:
                return 'Core predictor (selected)'
            elif row['Rank'] == 2:
                return 'Borderline – removed last'
            elif row['Rank'] <= max_rank / 2:
                return 'Moderately weak or redundant'
            return 'Very weak – removed early'

        rfecv_df['Interpretation'] = rfecv_df.apply(_interpret, axis=1)

        print('\n' + '=' * 110)
        print('RFECV FEATURE SELECTION RANKING (Static Features)')
        print('=' * 110)
        print(rfecv_df.to_string(index=False))
        print('=' * 110)
        print(f'\nRFECV Summary:')
        print(f'  Evaluated : {len(rfecv_df)}')
        print(f'  Selected  : {rfecv_df["Selected"].sum()}')
        print(f'  Eliminated: {(~rfecv_df["Selected"]).sum()}')
        print(f'  Rate      : {100*rfecv_df["Selected"].mean():.1f}%')

        rfecv_df.to_csv('rfecv_ranking_static.txt', index=False, sep=' ')
        print('✓ RFECV ranking saved → rfecv_ranking_static.txt')

        del rfecv_df
        gc.collect()

    # Combine selected static with all dynamic features
    combined = list(selected_static) + list(dynamic_names_arr)
    final_mask = np.isin(feat_names, combined)
    X_train_sel = X_train_np[:, final_mask]
    X_test_sel  = X_test_np[:, final_mask]
    sel_names   = feat_names[final_mask]

    print(f'\nFinal feature set: {X_train_sel.shape[1]} features')
    print(f'  Static  (selected): '
          f'{sum(1 for n in sel_names if n in STATIC_VAR or n in static_present)}')
    print(f'  Dynamic (all)     : {len(dynamic_names_arr)}')

    # ------------------------------------------------------------------ #
    # FINAL MODEL TRAINING WITH GROUP-AWARE OOB CV                        #
    # ------------------------------------------------------------------ #
    print('\n' + '=' * 70)
    print('FINAL MODEL TRAINING')
    print('=' * 70)

    def make_rf(**kw):
        kw.setdefault('n_jobs', 1)
        return RandomForestRegressor(
            n_estimators=N_EST_I,
            max_depth=DEPTH_I,
            min_samples_leaf=OBS_LEAF_I,
            min_samples_split=OBS_SPLIT_I,
            max_features=SAMPLE_F,
            **kw,
        )

    n_cv_folds = min(5, len(np.unique(groups_train)))
    print(f'GroupAwareMultiOutput: {N_EST_I} trees, {n_cv_folds}-fold GroupKFold OOB CV')

    model = GroupAwareMultiOutput(
        base_estimator=make_rf,
        n_cv_folds=n_cv_folds,
        n_jobs=N_JOBS,
        inner_n_jobs=1,
        random_state=24,
        oob_metric='r2',
        verbose=1,
    )

    model.fit(
        X_train_sel, Y_train_np,
        groups=groups_train,
        X_column_names=sel_names.tolist(),
        do_oob_cv=True,
    )

    print('\n--- OOB R² Summary ---')
    model.print_oob_summary()

    importances = model.get_importances()
    if importances is not None:
        print('\nTop 20 feature importances:')
        print(importances.head(20).to_string())
        importances.to_csv('feature_importances.txt', sep=' ', header=False)
        print('✓ Feature importances saved → feature_importances.txt')

    # ------------------------------------------------------------------ #
    # PREDICTIONS & EVALUATION METRICS                                    #
    # ------------------------------------------------------------------ #
    print('\n' + '=' * 70)
    print('EVALUATION')
    print('=' * 70)

    Y_train_pred = model.predict(X_train_sel)
    Y_test_pred  = model.predict(X_test_sel)

    def compute_metrics(i, Y_pred, Y_true):
        yp, yt = Y_pred[:, i], Y_true[:, i]
        r   = pearsonr(yp, yt)[0]
        rho = spearmanr(yp, yt)[0]
        mae = mean_absolute_error(yt, yp)
        kge_v = kge(yt, yp)
        return r, rho, mae, kge_v

    n_targets = Y_train_np.shape[1]
    train_m = [compute_metrics(i, Y_train_pred, Y_train_np) for i in range(n_targets)]
    test_m  = [compute_metrics(i, Y_test_pred,  Y_test_np)  for i in range(n_targets)]

    metrics_df = pd.DataFrame({
        'Target'   : target_present,
        'Train_r'  : [m[0] for m in train_m],
        'Test_r'   : [m[0] for m in test_m],
        'Train_rho': [m[1] for m in train_m],
        'Test_rho' : [m[1] for m in test_m],
        'Train_MAE': [m[2] for m in train_m],
        'Test_MAE' : [m[2] for m in test_m],
        'Train_KGE': [m[3] for m in train_m],
        'Test_KGE' : [m[3] for m in test_m],
    })

    print(metrics_df.round(3).to_string(index=False))
    metrics_df.to_csv('evaluation_metrics.txt', index=False, sep=' ')
    print('\n✓ Evaluation metrics saved → evaluation_metrics.txt')

    # Save predictions
    hdr = ' '.join(target_present)
    np.savetxt('predictions_train.txt', Y_train_pred, fmt='%.4f',
               header=hdr, comments='')
    np.savetxt('predictions_test.txt',  Y_test_pred,  fmt='%.4f',
               header=hdr, comments='')
    print('✓ Predictions saved → predictions_train.txt, predictions_test.txt')

    # ------------------------------------------------------------------ #
    # QUALITY ASSESSMENT                                                  #
    # ------------------------------------------------------------------ #
    print('\n' + '=' * 70)
    print('QUALITY ASSESSMENT')
    print('=' * 70)

    oob_mean = model.oob_r2_mean_
    if np.isnan(oob_mean):
        print('OOB CV was not performed (insufficient groups).')
    else:
        print(f'Mean OOB R²  : {oob_mean:.4f}')
        if oob_mean >= 0.7:
            verdict = 'GOOD – model explains most variance out-of-bag'
        elif oob_mean >= 0.5:
            verdict = 'ACCEPTABLE – reasonable predictive skill'
        elif oob_mean >= 0.3:
            verdict = 'WEAK – limited skill; consider more data or tuning'
        else:
            verdict = 'POOR – near-zero out-of-bag skill'
        print(f'Assessment   : {verdict}')
        print(f'Note         : OOB R² computed on 0.01% sample '
              f'({X_train_np.shape[0]} training rows, '
              f'{len(np.unique(groups_train))} stations). '
              f'Scores are expected to be lower than on the full dataset.')

    mean_test_r = np.mean([m[0] for m in test_m])
    print(f'Mean test r  : {mean_test_r:.4f}')

    print('\n✓ Done. Output files in current directory:')
    for f in ('rfecv_ranking_static.txt', 'feature_importances.txt',
              'evaluation_metrics.txt', 'predictions_train.txt',
              'predictions_test.txt'):
        exists = '✓' if os.path.isfile(f) else '✗'
        print(f'  {exists} {f}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        '--data-dir',
        default=os.path.dirname(os.path.abspath(__file__)),
        help='Directory containing sample .asc files '
             '(default: directory of this script)',
    )
    args = parser.parse_args()
    main(args.data_dir)
