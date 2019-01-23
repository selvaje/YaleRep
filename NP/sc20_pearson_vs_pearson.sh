

DIR=/project/fas/sbsc/ga254/dataproces/NP/pearson

lu_7_TN_season_1_CONUS_corr_mask.tif 
lu_9_TN_season_1_CONUS_corr_mask.tif 




gdal_calc.py --overwrite --NoDataValue=-9 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A lu_7_TN_season_1_CONUS_corr_mask.tif -B lu_9_TN_season_1_CONUS_corr_mask.tif   --calc="(  sqrt (( A.astype(float) ** 2 ) + ( B.astype(float) ** 2))   )" --outfile=lu_7-9_TN_season_1_CONUS_corr_mask_ipot.tif


gdal_calc.py --overwrite --NoDataValue=-9 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND \
 -A lu_9_TN_season_1_CONUS_corr_mask.tif  \
 -B lu_7_TN_season_1_CONUS_corr_mask.tif  \
 -C lu_7-9_TN_season_1_CONUS_corr_mask_ipot.tif  \
  --calc="(arccos(A.astype(float) / C.astype(float))/pi*(B>0)  +  ((arccos(A.astype(float) / C.astype(float))/pi)-1) *(B<0) )" --outfile=lu_7-9_TN_season_1_CONUS_corr_mask_angle.tif



