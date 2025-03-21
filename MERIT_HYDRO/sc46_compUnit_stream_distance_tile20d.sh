#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc46_compUnit_stream_distance_tile20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc46_compUnit_stream_distance_tile20d.sh.%A_%a.err
#SBATCH --job-name=sc46_compUnit_stream_distance_tile20d.sh
#SBATCH --array=1-116
#SBATCH --mem=45G

####  1-116

#### sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j" | grep sc42_compUnit_stream_distance.sh |  awk '{ printf ("%i:" , $1)} END {gsub(":","") ; print $1 }'  )   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc46_compUnit_stream_distance_tile20d.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=20000

if [ $SLURM_ARRAY_TASK_ID -eq 1 ] ; then 

echo  stream_dist_proximity outlet_diff_dw_basin outlet_dist_dw_basin stream_diff_dw_near stream_diff_up_near  stream_dist_up_farth outlet_diff_dw_scatch outlet_dist_dw_scatch stream_diff_up_farth stream_dist_dw_near stream_dist_up_near | xargs -n 1 -P 2 bash -c $'
var=$1
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_dist/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_dist/$var/${var}_*.tif
' _ 

else
sleep 300
fi

echo stream_dist_proximity outlet_diff_dw_basin outlet_dist_dw_basin stream_diff_dw_near stream_diff_up_near stream_dist_up_farth outlet_diff_dw_scatch outlet_dist_dw_scatch stream_diff_up_farth stream_dist_dw_near stream_dist_up_near | xargs -n 1 -P 2 bash -c $'
var=$1
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -projwin $( getCorners4Gtranslate $file) $SCMH/CompUnit_stream_dist/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_dist_tiles20d/${var}_tiles20d/${var}_${tile}.tif 
gdalinfomm $SCMH/CompUnit_stream_dist_tiles20d/${var}_tiles20d/${var}_${tile}.tif 
' _ 


if [ $SLURM_ARRAY_TASK_ID -eq 116 ] ; then
export GDAL_CACHEMAX=40000
sleep 3000

echo outlet_diff_dw_basin outlet_dist_dw_basin stream_diff_dw_near stream_diff_up_near stream_dist_up_farth outlet_diff_dw_scatch outlet_dist_dw_scatch stream_diff_up_farth stream_dist_dw_near stream_dist_up_near  stream_dist_proximity  | xargs -n 1 -P 1 bash -c $'
var=$1
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_dist_tiles20d/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_dist_tiles20d/${var}_tiles20d/${var}_??????.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -r average -tr 0.00833333333333 0.00833333333333 $SCMH/CompUnit_stream_dist_tiles20d/all_tif_${var}_dis.vrt  $SCMH/CompUnit_stream_dist_tiles20d/all_tif_${var}_dis_10p.tif 
' _ 
fi

exit 




#### old proximity 

## calculate stream euclidian distance proximity 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $file | awk  '{print $1-1, $2+1, $3+1, $4-1}') $SCMH/stream_tiles_final20d_1p/all_stream_dis.vrt $RAM/prox_${tile}.tif 
# cp $RAM/prox_${tile}.tif  $SCMH/CompUnit_stream_dist_tiles20d/stream_dist_proximity_tiles20d 
gdal_proximity.py -of GTiff -ot  Int16  -distunits PIXEL -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/prox_${tile}.tif $RAM/prox_${tile}_proxy.tif 
# cp $RAM/prox_${tile}_proxy.tif    $SCMH/CompUnit_stream_dist_tiles20d/stream_dist_proximity_tiles20d 
gdalbuildvrt -separate -overwrite -te $(getCorners4Gwarp $file ) $RAM/are_proxy_${tile}_crop.vrt $MERIT/are/all_tif_dis.vrt $RAM/prox_${tile}_proxy.tif
# 1.207106781  average between the lato and diagonal 
# sqrt ( area pixel  ) * 1.207106781 * 1000 = km per pixel 

oft-calc -ot Int16 $RAM/are_proxy_${tile}_crop.vrt  $RAM/are_proxy_${tile}_crop.tif <<EOF
1
#1 0.5 ^ 1207.106781 * #2  *
EOF
# cp $RAM/are_proxy_${tile}_crop.tif    $SCMH/CompUnit_stream_dist_tiles20d/stream_dist_proximity_tiles20d 

pksetmask -ot Int16   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/msk/all_tif_dis.vrt -msknodata 0 -nodata -1 \
-m   lbasin_tiles_final20d_1p/lbasin_${tile}.tif -msknodata 0 -1 -i  $RAM/are_proxy_${tile}_crop.tif  \
-o $SCMH/CompUnit_stream_dist_tiles20d/stream_dist_proximity_tiles20d/stream_dist_proximity_${tile}.tif

rm -f $RAM/are_proxy_${tile}_crop.vrt  $RAM/are_proxy_${tile}_crop.tif   $RAM/are_proxy_${tile}_crop.vrt $RAM/prox_${tile}.tif 
