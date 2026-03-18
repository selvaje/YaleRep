What do you think about the BoundedGroupAwareRandomForest? 
in my case the IDraster and the uniq ID of station observations. So wouldlike that RF does not mix IDraster to simulate as much as possible the prediction in locations where I do not have stations. 
The BoundedGroupAwareRandomForest you've implemented is a clever approach to address the specific challenge of spatial data and the desire to avoid mixing data from different IDraster locations, which represent unique station observations. Here's my assessment:

Strengths:

Spatial Awareness: The core idea of preventing the RF from mixing IDraster data during training is excellent. This directly addresses your goal of simulating predictions in unobserved locations. By ensuring that each tree only trains on data from a subset of IDraster locations, you're forcing the model to learn more generalizable patterns that are less dependent on specific station characteristics.
Group-wise Bootstrapping: The use of np.random.choice(unique_groups, size=len(unique_groups), replace=True) to sample IDraster groups for each tree's bootstrap sample is a key strength. This ensures that each tree sees a different combination of stations, promoting diversity in the ensemble and reducing the risk of overfitting to individual station properties.
OOB Error Calculation: The compute_oob_error method is a good way to estimate the model's generalization performance, especially given the grouped nature of your data. Calculating correlations for each IDraster and then averaging them provides a more robust assessment than a single overall metric.
Parallelization: Using joblib to parallelize both the tree training and prediction steps is crucial for performance, especially with a large number of trees and stations.
Potential Considerations and Improvements:

Minimum Group Size: The check if np.sum(mask) <= 5: in compute_group_error is good for handling small groups, but the threshold (5) might need adjustment based on your dataset. Too small a threshold could lead to unreliable correlation estimates for some stations.
OOB Prediction Handling: The initialization of self.oob_predictions with np.nan is appropriate, but ensure that you're handling NaN values correctly in the compute_oob_error calculation (e.g., using np.nanmean).
Prediction Time: The prediction time will be impacted because the code checks if X has the IDraster column.
Feature Importance: The feature importance calculation is based on the standard RF implementation, which might not fully reflect the group-aware nature of your model. Consider exploring alternative feature importance methods that take the group structure into account.
Alternative to Pearson Correlation: While Pearson correlation is a good starting point, consider other metrics like Spearman's rank correlation or even custom metrics that are more sensitive to specific aspects of your streamflow prediction task.
Regularization: Explore regularization techniques (e.g., L1 or L2 regularization) within the individual decision trees to further prevent overfitting, especially if you have a high number of features.
Overall:

Your BoundedGroupAwareRandomForest is a well-designed model that addresses a specific challenge in your spatial prediction problem. The group-aware training approach and the careful OOB error calculation are particularly commendable. By addressing the potential considerations and improvements I've outlined, you can further refine your model and potentially achieve even better generalization performance in unobserved locations.
