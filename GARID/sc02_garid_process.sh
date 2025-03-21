#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_garid_process.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_garid_process.sh.%A.%a.err
#SBATCH --job-name=sc02_garid_process.sh
#SBATCH --mem-per-cpu=10000M

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GARID/sc02_garid_process.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GARID

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GARID/sc02_garid_process.sh

module purge
source ~/bin/gdal

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GARID

####    ANNUAL
gdalwarp -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcnodata -32768 -dstnodata -9999 $DIR/ai_et0/ai_et0.tif $DIR/out/ARID_annual.tif

gdal_edit.py -a_ullr  -180 90 180 -60  $DIR/out/ARID_annual.tif
