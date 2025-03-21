#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc48_compUnit_stream_channel_tile20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc48_compUnit_stream_channel_tile20d.sh.%A_%a.err
#SBATCH --job-name=sc48_compUnit_stream_channel_tile20d.sh
#SBATCH --array=1-116
#SBATCH --mem=40G

####  1-116

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc48_compUnit_stream_channel_tile20d.sh

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
export GDAL_CACHEMAX=16000

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 

echo channel_curv_cel channel_dist_dw_seg channel_dist_up_seg channel_elv_dw_seg channel_elv_up_seg channel_grad_up_cel channel_ident channel_dist_up_cel channel_elv_dw_cel  channel_elv_up_cel channel_grad_dw_seg channel_grad_up_seg | xargs -n 1 -P 2 bash -c $'
var=$1
gdalbuildvrt  -overwrite  $SCMH/CompUnit_stream_channel/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_channel/${var}/${var}_*.tif
' _
 
else
sleep 400
fi

echo channel_curv_cel channel_dist_dw_seg channel_dist_up_seg channel_elv_dw_seg channel_elv_up_seg channel_grad_up_cel channel_ident channel_dist_up_cel channel_elv_dw_cel  channel_elv_up_cel channel_grad_dw_seg channel_grad_up_seg | xargs -n 1 -P 2 bash -c $'
var=$1
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co NUM_THREADS=2 -projwin $(getCorners4Gtranslate $file) $SCMH/CompUnit_stream_channel/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_channel_tiles20d/${var}_tiles20d/${var}_${tile}.tif 

gdalinfo -mm $SCMH/CompUnit_stream_channel_tiles20d/${var}_tiles20d/${var}_${tile}.tif | grep Computed | awk \'{ gsub(/[=,]/," ",$0); print $3,$4}\' > $SCMH/CompUnit_stream_channel_tiles20d/${var}_tiles20d/${var}_${tile}.mm

' _

if [  $SLURM_ARRAY_TASK_ID -eq 116  ] ; then 

sleep 1000

echo channel_curv_cel channel_dist_dw_seg channel_dist_up_seg channel_elv_dw_seg channel_elv_up_seg channel_grad_up_cel channel_ident channel_dist_up_cel channel_elv_dw_cel  channel_elv_up_cel channel_grad_dw_seg channel_grad_up_seg | xargs -n 1 -P 2 bash -c $'
var=$1
gdalbuildvrt  -overwrite $SCMH/CompUnit_stream_channel_tiles20d/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_channel_tiles20d/${var}_tiles20d/${var}_??????.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.00833333333333 0.00833333333333 $SCMH/CompUnit_stream_channel_tiles20d/all_tif_${var}_dis.vrt  $SCMH/CompUnit_stream_channel_tiles20d/all_tif_${var}_dis_10p.tif
' _

fi 
