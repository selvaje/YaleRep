#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_broken_basin_manip.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_broken_basin_manip.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc21_broken_basin_manip.sh
#SBATCH --array=1-24

# 35  number of files 
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_broken_basin_manip.sh
# sbatch -d afterany:$(qmys | grep  sc20_build_dem_location_4streamTile.sh | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_broken_basin_manip.sh

MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm

file=$(ls /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_h??v??.tif   | head -n  $SLURM_ARRAY_TASK_ID | tail  -1 )

filename=$( basename $file ) 

MAX=$( pkstat -max -i  $file | awk '{ print int($2) }'  )

if [ $MAX -eq 0 ] ; then 
echo remove  $file  
exit 
else
pkgetmask  -min 0.1  -max 10000000000000 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $file  -o $MERIT/lbasin_tiles_brokb_msk/$filename  
gdal_edit.py -a_nodata  0 $MERIT/lbasin_tiles_brokb_msk/$filename  
pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx 10  -dy 10 -d 10  -f max   -i $MERIT/lbasin_tiles_brokb_msk/$filename  -o  $MERIT/lbasin_tiles_brokb_msk1km/$filename  
gdal_edit.py -a_nodata 0   $MERIT/lbasin_tiles_brokb_msk1km/$filename  
fi 


exit 
