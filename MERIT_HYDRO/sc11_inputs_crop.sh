#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 2:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_inputs_crop.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_inputs_crop.%A_%a.err
#SBATCH --job-name=sc11_inputs_crop.sh 
#SBATCH --array=33
#SBATCH --mem=35G

ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc11_inputs_crop.sh 
#### crop for later use in the TERRA and other variables 
source ~/bin/gdal3
source ~/bin/pktools

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

export  MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export  RAM=/dev/shm

file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${SLURM_ARRAY_TASK_ID}.tif
filename=$(basename $file .tif  )
export tile=$(echo $filename | tr "ID" " " | awk '{ print $2 }' )
export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )
export ulx=$( getCorners4Gtranslate  $file | awk '{ print $1 }'  )
export uly=$( getCorners4Gtranslate  $file | awk '{ print $2 }'  )
export lrx=$( getCorners4Gtranslate  $file | awk '{ print $3 }'  )
export lry=$( getCorners4Gtranslate  $file | awk '{ print $4 }'  )

echo tile_??_ID${SLURM_ARRAY_TASK_ID}.tif

echo are msk elv dep | xargs -n 1 -P 2 bash -c $'
var=$1
GDAL_CACHEMAX=14000
echo translate $var
gdal_translate  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/${var}/all_tif_dis.vrt $MERIT/${var}/${zone}${tile}_${var}.tif 
  gdalinfo -mm  $MERIT/${var}/${zone}${tile}_${var}.tif | grep Comp  > $MERIT/${var}/${zone}${tile}_${var}.mm

if [ $var = "elv" ] || [ $var = "are" ] ; then  
    gdal_edit.py  -a_nodata -9999  $MERIT/${var}/${zone}${tile}_${var}.tif  
  
  gdal_translate -a_nodata -9999  -a_srs EPSG:4326 -r bilinear -tr 0.0083333333333 0.0083333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $MERIT/${var}/${zone}${tile}_${var}.tif $MERIT/${var}/${zone}${tile}_${var}_1km.tif 
else
    gdal_edit.py  -a_nodata 0      $MERIT/${var}/${zone}${tile}_${var}.tif  

  gdal_translate -a_nodata 0  -a_srs EPSG:4326 -r nearest -tr 0.0083333333333 0.0083333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $MERIT/${var}/${zone}${tile}_${var}.tif $MERIT/${var}/${zone}${tile}_${var}_1km.tif 
fi

' _ 

