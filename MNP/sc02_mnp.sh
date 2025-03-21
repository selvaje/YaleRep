#!/bin/bash
#SBATCH --job-name=sc02_mnp.sh
#SBATCH --ntasks=1 --nodes=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_mnp.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_mnp.sh.%J.err
#SBATCH --array=1860-2014   ###  range of year the data is available

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/MNP/sc02_mnp.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/MNP/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MNP/sc02_mnp.sh

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MNP
OUT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MNP/out

YEAR=$SLURM_ARRAY_TASK_ID

###   Header for ascii-format files - ncols: 4320- nrows: 2124- xllcorner: -180- yllcorner: -88.5- cellsize: 0.0833333- NODATA_value: -9999
printf "ncols 4320\nnrows 2124\nxllcorner -180\nyllcorner -88.5\ncellsize 0.0833333\nNODATA_value -9999" > $OUT/MNP_${YEAR}.asc

echo -e "\n$( cat ManNitPro/yy${YEAR}.txt )" >> $OUT/MNP_${YEAR}.asc

gdal_translate -of GTiff  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9   -a_ullr -180.0 88.5 180 -88.5 $OUT/MNP_${YEAR}.asc $OUT/MNP_${YEAR}.tif

rm $OUT/MNP_${YEAR}.asc
rm ManNitPro/yy${YEAR}.txt
