#!/bin/bash
#SBATCH --job-name=sc01_wget_nutrientAvail.sh
#SBATCH --ntasks=1 --nodes=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_wget_nutrientAvail.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_wget_nutrientAvail.sh.%J.err


# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/HWSD/sc01_wget_nutrientAvail.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HWSD/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HWSD/sc01_wget_nutrientAvail.sh

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HWSD

cd $DIR
wget http://webarchive.iiasa.ac.at/Research/LUC/External-World-soil-database/Soil_Quality/sq1.asc


# 1: No or slight limitations
# 2: Moderate limitations
# 3: Sever limitations
# 4: Very severe limitations
# 5: Mainly non-soil
# 6: Permafrost area
# 7: Water bodies

gdalwarp  -t_srs EPSG:4326 -dstnodata 0  -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 sq1.asc hwsd_nutava.tif

rm sq1.asc

exit

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/HWSD/hwsd_nutava.tif /home/jaime/Data/
