#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_gevapt_process.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_gevapt_process.sh.%A.%a.err
#SBATCH --job-name=sc02_gevapt_process.sh
#SBATCH --mem-per-cpu=20000M

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GEVAPT/sc02_gevapt_process.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GEVAPT

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEVAPT/sc02_gevapt_process.sh

module purge
source ~/bin/gdal

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEVAPT

####    ANNUAL

gdalwarp -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcnodata -32768 -dstnodata -9999 $DIR/et0_yr/et0_yr.tif $DIR/out/EVAPT_annual.tif

gdal_edit.py -a_ullr  -180 90 180 -60  $DIR/out/EVAPT_annual.tif

####     MONTHLY

ls $DIR/et0_month/et0_*.tif | xargs -n 1 -P 12  bash -c $'

	file=$1
	filename=$( basename  $file .tif)
	#gdalbuildvrt -overwrite  $file  $DIR/temp/${filename}.vrt
	gdalwarp -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcnodata -32768 -dstnodata -9999   $file  $DIR/out/${filename}.tif
	gdal_edit.py -a_ullr -180 90 180 -60 $DIR/out/${filename}.tif

' _

#rm temp/*.vrt
