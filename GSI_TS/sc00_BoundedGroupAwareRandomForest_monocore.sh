import os
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.base import RegressorMixin
from sklearn.metrics import mean_squared_error

# Define the structure
columns = ["IDraster", "QMIN", "Q10", "Q20", "Q30", "Q40", "Q50", "Q60", "Q70", "Q80", "Q90", "QMAX"]

# Generate unique IDs (10 times repeated twice = 100 rows)
id_values = np.repeat(np.arange(15139, 15149), 10)  # 10 unique IDs, each repeated 10 times

# Shuffle the ID values
np.random.shuffle(id_values)

# Generate random values for Q columns
q_values = np.random.rand(100, 11)  # 100 rows, 11 columns

# Create Y_train DataFrame
Y_train = pd.DataFrame(np.column_stack((id_values, q_values)), columns=columns)

# Add 2 rows with IDraster = 2, 5 rows with IDraster = 5, and 8 rows with IDraster = 8
extra_rows = pd.DataFrame(
    [[2] + list(np.random.rand(11)) for _ in range(2)] +
    [[5] + list(np.random.rand(11)) for _ in range(5)] +
    [[8] + list(np.random.rand(11)) for _ in range(8)],
    columns=columns
)

# Append and shuffle IDraster values
Y_train = pd.concat([Y_train, extra_rows], ignore_index=True)
Y_train = Y_train.sample(frac=1).reset_index(drop=True)

# Extract ID values for X_train
x_id_values = Y_train["IDraster"].values.reshape(-1, 1)

# Define the structure
columns = ["IDraster", "RMIN", "R10", "R20", "R30", "R40", "R50", "R60", "R70", "R80", "R90", "RMAX"]

# Generate random values for X_train columns
q_values = np.random.rand(len(x_id_values), 11)  # Match the length of x_id_values

# Create DataFrame
X_train = pd.DataFrame(np.hstack((x_id_values, q_values)), columns=columns)

print('X_train')
print(X_train.head())
print('Y_train')
print(Y_train.head())

# Ensure IDraster is present
if 'IDraster' not in X_train.columns or 'IDraster' not in Y_train.columns:
    raise KeyError("IDraster column not found in X_train or Y_train")

# Custom Decision Tree to enforce Group constraints
class GroupAwareDecisionTree(DecisionTreeRegressor):
    def fit(self, X, y, sample_weight=None, check_input=True):
        super().fit(X, y, sample_weight=sample_weight, check_input=check_input)

# Custom Random Forest to enforce Group constraints & ensure non-negative predictions
class BoundedGroupAwareRandomForest(RandomForestRegressor, RegressorMixin):
    def fit(self, X, Y):
        self.oob_predictions = np.full(Y.drop(columns=['IDraster']).shape, fill_value=np.nan, dtype=np.float64)  # OOB storage
        unique_groups = np.unique(X['IDraster'])
        self.estimators_ = []
        
        for _ in range(self.n_estimators):
            boot_groups = np.random.choice(unique_groups, size=len(unique_groups), replace=True)
            train_mask = X['IDraster'].isin(boot_groups)
            oob_mask = ~train_mask

            tree = GroupAwareDecisionTree()
            X_train_filtered = X.loc[train_mask].drop(columns=['IDraster']).copy()
            Y_train_filtered = Y.loc[train_mask].drop(columns=['IDraster']).copy()
            tree.fit(X_train_filtered, Y_train_filtered)
            self.estimators_.append(tree)

            if np.any(oob_mask):
                X_oob_filtered = X.loc[oob_mask].drop(columns=['IDraster']).copy()
                self.oob_predictions[oob_mask, :] = tree.predict(X_oob_filtered)

        return self
    
    def predict(self, X):
        X_filtered = X.drop(columns=['IDraster']).copy()
        y_pred = np.mean([tree.predict(X_filtered) for tree in self.estimators_], axis=0)
        return np.maximum(y_pred, 0)  # Ensure non-negative predictions
    
    def compute_oob_error(self, Y_true):
        """Compute OOB error for each Q (QMIN to QMAX) at the group level, ensuring IDraster is retained and filtering by observation count."""
        unique_idrasters = Y_true['IDraster'].unique()
        oob_errors_list = []
        
        for idraster in unique_idrasters:
            if (Y_true['IDraster'] == idraster).sum() <= 5:
                oob_errors_list.append([idraster] + [np.nan] * (Y_true.shape[1] - 1))
                continue
            mask = Y_true['IDraster'] == idraster
            if np.any(mask):
                Y_true_filtered = Y_true.loc[mask].drop(columns=['IDraster'])
                oob_pred_filtered = self.oob_predictions[mask, :]
                errors = [pearsonr(Y_true_filtered[col], oob_pred_filtered[:, i])[0] for i, col in enumerate(Y_true_filtered.columns)]
                oob_errors_list.append([idraster] + errors)
        
        oob_errors = np.array(oob_errors_list)
        overall_oob_error = np.nanmean(oob_errors[:, 1:], axis=0)  # Ignore IDraster column in mean calculation
        return oob_errors, overall_oob_error

# Train Model
RFreg = BoundedGroupAwareRandomForest(
    random_state=24, 
    n_estimators=100, 
    n_jobs=-1, 
    bootstrap=True
)

RFreg.fit(X_train, Y_train)  # Train the model with ID constraints

oob_errors, overall_oob_error = RFreg.compute_oob_error(Y_train)
print(oob_errors)
print(overall_oob_error)

oob_errors_df = pd.DataFrame(oob_errors, columns=Y_train.columns)
overall_oob_error_df = pd.DataFrame(overall_oob_error.reshape(1, -1), columns=Y_train.columns.drop('IDraster'))

# Append IDraster to predictions
Y_train_predOOB = pd.DataFrame(RFreg.oob_predictions, columns=Y_train.columns.drop('IDraster'))
Y_train_predOOB.insert(0, 'IDraster', Y_train['IDraster'].values)

Y_train_pred = pd.DataFrame(RFreg.predict(X_train), columns=Y_train.columns.drop('IDraster'))

print('Y_train_predOOB')
print(Y_train_predOOB.head(4))
print('Y_train_pred')
print(Y_train_pred.head(4))
print('oob_errors_df')
print(oob_errors_df.head(40))
print('overall_oob_error_df')
print(overall_oob_error_df)
                oob_errors_list.append([idraster] + errors)
        
        oob_errors = np.array(oob_errors_list)
        overall_oob_error = np.nanmean(oob_errors[:, 1:], axis=0)  # Ignore IDraster column in mean calculation
        return oob_errors, overall_oob_error

# Train Model
RFreg = BoundedGroupAwareRandomForest(
    random_state=24, 
    n_estimators=100, 
    n_jobs=-1, 
    bootstrap=True
)

RFreg.fit(X_train, Y_train)  # Train the model with ID constraints

oob_errors, overall_oob_error = RFreg.compute_oob_error(Y_train)
print(oob_errors)
print(overall_oob_error)

oob_errors_df = pd.DataFrame(oob_errors, columns=Y_train.columns)
overall_oob_error_df = pd.DataFrame(overall_oob_error.reshape(1, -1), columns=Y_train.columns.drop('IDraster'))

# Append IDraster to predictions
Y_train_predOOB = pd.DataFrame(RFreg.oob_predictions, columns=Y_train.columns.drop('IDraster'))
Y_train_predOOB.insert(0, 'IDraster', Y_train['IDraster'].values)

Y_train_pred = pd.DataFrame(RFreg.predict(X_train), columns=Y_train.columns.drop('IDraster'))

print('Y_train_predOOB')
print(Y_train_predOOB.head(4))
print('Y_train_pred')
print(Y_train_pred.head(4))
print('oob_errors_df')
print(oob_errors_df.head(40))
print('overall_oob_error_df')
print(overall_oob_error_df)
