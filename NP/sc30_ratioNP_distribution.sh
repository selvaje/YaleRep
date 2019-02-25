



export NP=/project/fas/sbsc/ga254/dataproces/NP

# ls $NP/predictors/*season?.tif $NP/predictors/lu_7.tif  | xargs -n 1 -P 4 bash -c $'

# file=$1
# filename=$(basename $file .tif )
# gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   -projwin $(getCorners4Gtranslate $NP/ratioNP/map_pred_CONUS_mean_TDN_TDP_ratio_1.tif   ) $file   $NP/predictors/${filename}_usa.tif 

# ' _


#   <11 heaviliy   N limited class_A
# 11-14 moderately N limited class_B
# 14-18 balanced             class_C
# 18-25 moderately P limited class_D
#   >25 heavily    P limited class_F
 

# ls $NP/ratioNP/map_pred_CONUS_mean_*_ratio_?.tif  | xargs -n 1 -P 8 bash -c $'

# file=$1
# filename=$(basename $file .tif )
# pkgetmask -ot Int16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min -0.5  -max 10.999999999   -nodata 0  data 1 -i  $file -o  $NP/ratioNP/${filename}_class_A.tif 
# pkgetmask -ot Int16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min   11  -max 13.999999999   -nodata 0  data 1 -i  $file -o  $NP/ratioNP/${filename}_class_B.tif 
# pkgetmask -ot Int16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min   14  -max 17.999999999   -nodata 0  data 1 -i  $file -o  $NP/ratioNP/${filename}_class_C.tif 
# pkgetmask -ot Int16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min   18  -max 24.999999999   -nodata 0  data 1 -i  $file -o  $NP/ratioNP/${filename}_class_D.tif 
# pkgetmask -ot Int16  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min   25  -max 99999          -nodata 0  data 1 -i  $file -o  $NP/ratioNP/${filename}_class_F.tif 
# ' _
# 


# for PRED in  $NP/predictors/lu_7_usa.tif   ; do 
# export PRED
# export PREDNAME=$(basename $PRED .tif)
# ls $NP/ratioNP/map_pred_CONUS_mean_*_ratio_?_class_?.tif  | xargs -n 1 -P 8 bash -c $'

# file=$1
# filename=$(basename $file .tif )
# filename2=${filename:20}
# pksetmask    -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $file -msknodata 0 -nodata 255 -i $PRED   -o $NP/ratioNP_dist_predictors/${PREDNAME}_${filename2}.tif  

# pkstat -nodata 255  -src_min 0 -src_max 100   --hist  -i  $NP/ratioNP_dist_predictors/${PREDNAME}_${filename2}.tif  > $NP/ratioNP_dist_predictors/${PREDNAME}_${filename2}.hist
# rm -f $NP/ratioNP_dist_predictors/${PREDNAME}_${filename2}.tif  
# ' _
# done 

for SEA in 1 2 3 4 ; do 
paste  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_A.hist   \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_B.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_C.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_D.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_F.hist) \
 >   $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_${SEA}_class_ABCDF.hist
done 

for SEA in 1 2 3 4 ; do 
paste  $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_A.hist   \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_B.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_C.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_D.hist) \
        <(awk '{ print $2 }'  $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_F.hist) \
 >   $NP/ratioNP_dist_predictors/lu_7_usa_TN_TP_ratio_${SEA}_class_ABCDF.hist
done 


# rm  $NP/ratioNP_dist_predictors/lu_7_usa_TDN_TDP_ratio_?_class_?.hist


#  $NP/predictors/*_season?_usa.tif


