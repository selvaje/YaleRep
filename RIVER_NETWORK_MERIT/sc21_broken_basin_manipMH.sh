#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_broken_basin_manip.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_broken_basin_manip.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc21_broken_basin_manip.sh
#SBATCH --mem=20000

# sbatch /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc21_broken_basin_manip.sh
# sbatch -d afterany:$(qmys | grep  sc20_build_dem_location_4streamTile.sh | awk '{ print $1}' | uniq) /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc21_broken_basin_manip.sh

source ~/bin/gdal
source ~/bin/pktools
source ~/bin/grass

echo SLURM_JOB_ID $SLURM_JOB_ID
echo SLURM_ARRAY_JOB_ID $SLURM_ARRAY_JOB_ID
echo SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID
echo SLURM_ARRAY_TASK_COUNT $SLURM_ARRAY_TASK_COUNT
echo SLURM_ARRAY_TASK_MAX $SLURM_ARRAY_TASK_MAX
echo SLURM_ARRAY_TASK_MIN  $SLURM_ARRAY_TASK_MIN

export MERIT=/gpfs/loomis/project/fas/sbsc/hydro/dataproces/MERIT_HYDRO
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO


ls  $SC/lbasin_tiles_brokb_msk/lbasin_h??v??.tif | xargs  -n 1 -P 8 bash -c $' 
file=$1
filename=$( basename $file ) 
pkfilter     -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx 10  -dy 10 -d 10  -f mode   -i $SC/lbasin_tiles_brokb_msk/$filename  -o  $SC/lbasin_tiles_brokb_msk1km/$filename  
gdal_edit.py -a_nodata 255   $SC/lbasin_tiles_brokb_msk1km/$filename  

' _ 

gdalbuildvrt -overwrite   $SC/lbasin_tiles_brokb_msk1km/all_tif.vrt   $SC/lbasin_tiles_brokb_msk1km/lbasin_h*v*.tif
gdal_translate -a_nodata 255  --config GDAL_CACHEMAX 16000  -co  TILED=YES  -co INTERLEAVE=BAND -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte $SC/lbasin_tiles_brokb_msk1km/all_tif.vrt $SC/lbasin_tiles_brokb_msk1km/all_tif.tif 

exit 
