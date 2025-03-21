#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout1/sc05_global_composit_B1.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr1/sc05_global_composit_B1.sh.%A_%a.err
#SBATCH --mem=50G 
#SBATCH --job-name=sc05_global_composit_B1.sh

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/sc05_global_composit_B1.sh 

ulimit -c 0

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  

source ~/bin/gdal3 
source ~/bin/pktools 

export GLAD=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD
export GLADSC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GLAD_ARD_BK
export RAM=/dev/shm


GDAL_CACHEMAX=40000
rm -f $GLADSC/data/global_med_B1_shp.*
gdaltindex  $GLADSC/data/global_med_B1_shp.shp  $GLADSC/data/*/*/*_med_B1.tif 

gdalbuildvrt -overwrite   $GLADSC/data/global_med_B1.vrt  $GLADSC/data/*/*/*_med_B1.tif
gdal_translate  -co COMPRESS=LZW -co ZLEVEL=9  $GLADSC/data/global_med_B1.vrt  $GLADSC/data/global_med_B1.tif 

