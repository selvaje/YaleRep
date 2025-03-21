#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_GCN250.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_GCN250.sh.%A.%a.err
#SBATCH --job-name=sc03_GCN250.sh
#SBATCH --mem-per-cpu=30000M
#SBATCH --array=2-7   ### seven years to process (2012-2018)

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GCN250/sc03_GCN250.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GCN250

###  Copied the look up table from local computer to GRACE
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/data/GCN250/LookupTable2.csv jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GCN250

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GCN250/sc03_GCN250.sh

########################################################################
module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GCN250

# folder where the Hydrological Soil Group map is located
export DIRSOIL=/gpfs/gibbs/pi/hydro/hydro/dataproces/HYSOGS

#  temporal files
export RAM=/dev/shm

# read the land cover map at a time based on the array
export LC=$( ls $DIR/LC | head -n $SLURM_ARRAY_TASK_ID | tail -n 1 )

export AGNO=$(echo $LC | tr -dc '0-9')

# Go through each of the soil categories
echo 1 2 3 4 11 12 13 14 | xargs -n 1 -P 8 bash -c $'
cod=$1

pksetmask -i $DIR/LC/$LC -m $DIRSOIL/HYSOGs250m.tif -o $RAM/soilCat_${AGNO}_${cod}.tif -ot Byte --msknodata $cod -nodata 0 --operator \'!\' -co COMPRESS=LZW -co ZLEVEL=9

CN="$(head -n1 $DIR/LookupTable2.csv | tr "," "\n" | grep -Fxn ${cod} | cut -f1 -d:)"

awk -F"," -v cn="$CN" \'{ print $1, $cn }\' LookupTable2.csv | tail -n +2 > $RAM/lookup_${AGNO}_${cod}.txt

pkreclass -i $RAM/soilCat_${AGNO}_${cod}.tif -o $RAM/lcCat_${AGNO}_${cod}.tif -code $RAM/lookup_${AGNO}_${cod}.txt -co COMPRESS=LZW -co ZLEVEL=9
' _

# Merge rasters and create the final raster tif
gdalbuildvrt $RAM/tempVRT_${AGNO}.vrt $RAM/lcCat_${AGNO}_1.tif $RAM/lcCat_${AGNO}_2.tif $RAM/lcCat_${AGNO}_3.tif $RAM/lcCat_${AGNO}_4.tif $RAM/lcCat_${AGNO}_11.tif $RAM/lcCat_${AGNO}_12.tif $RAM/lcCat_${AGNO}_13.tif $RAM/lcCat_${AGNO}_14.tif
#gdalbuildvrt $RAM/tempVRT_${AGNO}.vrt $( ls $RAM/lcCat_${AGNO}_*.tif)

gdal_translate  -of GTiff -ot Byte -a_nodata 255 $RAM/tempVRT_${AGNO}.vrt  $DIR/GCN_${AGNO}.tif -co COMPRESS=LZW -co ZLEVEL=9

# REMOVE temporal files
rm $RAM/tempVRT_${AGNO}.vrt  $RAM/lcCat_${AGNO}_*.tif $RAM/soilCat_${AGNO}_*.tif $RAM/lookup_${AGNO}_*.txt


exit


###############################################################################
###############################################################################

# extract land cover categories that overlap with pixels of each soil category
pksetmask -i $DIR/LC/$LC -m $DIRSOIL/HYSOGs250m.tif -o $RAM/soilCat_${AGNO}_${cod}.tif -ot Byte --msknodata $cod -nodata 0 --operator \'!\' -co COMPRESS=LZW -co ZLEVEL=9
# for testing ---- pksetmask -i $j -m $DIRSOIL/HYss2.tif -o $DIRLC/soilCat_${cod}.tif -ot Byte --msknodata $cod -nodata 0 --operator \'!\' -co COMPRESS=LZW -co ZLEVEL=9

# prepare the look up table of land cover categories and the curve number for each soil category in turn
# identify the position (column number) of the soil category in turn
CN="$(head -n1 $DIR/LookupTable2.csv | tr "," "\n" | grep -Fxn ${cod} | cut -f1 -d:)"

# extract only land use category and curve numbers for soil category in turn
#csvcut --columns=1,$CN $DIR/LookupTable.csv | tail -n +2 > $DIR/lookup_${cod}.txt
#sed -i "s/,/ /g" $DIR/lookup_${cod}.txt # replace coma with space
awk -F"," -v cn="$CN" \'{ print $1, $cn }\' LookupTable2.csv | tail -n +2 > $RAM/lookup_${AGNO}_${cod}.txt

# reclassify the land cover map according to the curve number in the look up table
pkreclass -i $RAM/soilCat_${AGNO}_${cod}.tif -o $RAM/lcCat_${AGNO}_${cod}.tif -code $RAM/lookup_${AGNO}_${cod}.txt -co COMPRESS=LZW -co ZLEVEL=9
