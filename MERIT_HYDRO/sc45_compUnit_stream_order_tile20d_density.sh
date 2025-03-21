#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc45_compUnit_stream_order_tile20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc45_compUnit_stream_order_tile20d.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=25G

####  1-116

## sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc45_compUnit_stream_order_tile20d_density.sh 
source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export name=$name
export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=10000

echo $name

name=strahler
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -min 0.5 -max 20 -ot Byte -i $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.tif -o  /tmp/order_${name}_${tile}.tif

pkfilter -ot UInt16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -dy 100 -dx 100 -d 100  -f sum  -i  /tmp/order_${name}_${tile}.tif -o $SCMH/CompUnit_stream_order_tiles20d/order_denisty_tiles20d/order_density_${tile}.tif

rm -f /tmp/order_${name}_${tile}.tif


