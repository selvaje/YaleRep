#!/bin/bash

export RAM=/dev/shm

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=97  #####   ID 96 small area for testing 
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### SLURM_ARRAY_TASK_ID=43
export file=$(ls /gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO/lbasin_compUnit_{tiles,large}/bid*_msk.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("bid","") ; gsub("_msk","") ; print }'   )

echo $file 
export GDAL_CACHEMAX=8000


###  after accumulation /gpfs/loomis/project/sbsc/hydro/dataproces/TERRA/tmin_acc/1958/tmin_1958_12.vrt  0.000833333333333333333333 

# crop base on compunit extend
gdal_translate  -a_ullr $(getCorners4Gtranslate $file)  -projwin $(getCorners4Gtranslate $file)  -co COMPRESS=DEFLATE -co ZLEVEL=9 /gpfs/loomis/project/sbsc/hydro/dataproces/TERRA/tmin_acc/1958/tmin_1958_12.vrt  $RAM/timin_${ID}_acc_crop.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $RAM/timin_${ID}_acc_crop.tif 
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file)  $RAM/timin_${ID}_acc_crop.tif

# mask base on the compunit 
pksetmask of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $file  -msknodata 0 -nodata -9999999  -i $RAM/timin_${ID}_acc_crop.tif -o  $RAM/timin_${ID}_acc_crop_msk.tif

# hist 
pkstat -hist -src_min 0 -src_max 999999  -i $RAM/timin_${ID}_acc_crop_msk.tif  > /gpfs/loomis/scratch60/sbsc/ga254/dataproces/TERRA/tmin_qc/1958/timin_${ID}_acc_crop_msk.hist

###  input before accumulation /gpfs/loomis/project/sbsc/hydro/dataproces/TERRA/tmin/tmin_1958_12.tif  0.04166666666666666

gdal_translate  -a_nodata -9999  -a_srs EPSG:4326 -r bilinear -ot Int32  -tr 0.000833333333333333333 0.000833333333333333333   -projwin $(getCorners4Gtranslate $file)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES /gpfs/loomis/project/sbsc/hydro/dataproces/TERRA/tmin/tmin_1958_12.tif  $RAM/timin_${ID}_orig_crop.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/timin_${ID}_orig_crop.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate $file)  $RAM/timin_${ID}_orig_crop.tif

pksetmask -of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $file  -msknodata 0 -nodata -9999999  -i $RAM/timin_${ID}_orig_crop.tif -o  $RAM/timin_${ID}_orig_crop_msk.tif

##################################################                                                                           ls24
pkstat -hist -src_min 0 -src_max 999999 -i $RAM/timin_${ID}_orig_crop_msk.tif    > /gpfs/loomis/scratch60/sbsc/ga254/dataproces/TERRA/tmin_qc/1958/timin_${ID}_orig_crop_msk.hist

