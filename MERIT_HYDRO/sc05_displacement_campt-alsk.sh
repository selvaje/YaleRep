#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_displacement_campt-alsk.sh.sh.%J.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_displacement_campt-alsk.sh.sh.%J.err
#SBATCH --job-name=sc05_displacement_campt-alsk.sh
#SBATCH --mem=20G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc05_displacement_campt-alsk.sh
#### sbatch --dependency=afterany:$( myq | grep sc23_tiling20d_lbasin_reclass.sh | awk '{ print $1}' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc05_displacement_campt-alsk.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# camptch & alaska   # area in displacement from -180 -169 to 180 191   nord 72 south   64

# for var in elv msk upa ; do 
for var in upa ; do 
for tile in n65w180  n65w175 n65w170 n60w180  n60w175 n70w180 ; do 
if [ $var = elv   ]  ; then ND=-9999 ; fi 
if [ $var = msk   ]  ; then ND=0 ; fi 
if [ $var = upa   ]  ; then ND=-9999 ; fi 
echo nodata $ND for var $var 
#### masking the west 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 1 -nodata $ND -i $MERIT/${var}/${tile}_${var}.tif -o $MERIT/${var}/${tile}_${var}_msk.tif 
gdal_edit.py -a_nodata $ND $MERIT/${var}/${tile}_${var}_msk.tif
###  transpose west to east
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 0 -nodata $ND -i $MERIT/${var}/${tile}_${var}.tif -o $MERIT/${var}/${tile}_${var}_tmp.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $MERIT/${var}/${tile}_${var}_tmp.tif | awk '{print $1 + 360, int($2), $3 + 360, int($4)}') $MERIT/${var}/${tile}_${var}_tmp.tif $MERIT/${var}/${tile}_${var}_dis.tif; 
gdal_edit.py -a_nodata $ND $MERIT/${var}/${tile}_${var}_dis.tif
rm $MERIT/${var}/${tile}_${var}_tmp.tif; 
done
done

exit

# no depresion in n65w180  n65w175 n65w170 n60w180  n60w175 n70w180

for var in are ; do 
for tile in n65w180  n65w175 n65w170 n60w180  n60w175 n70w180 ; do 
if [ $var = are ] ; then ND=-9999 ; fi
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $MERIT/${var}/${tile}_${var}.tif | awk '{print $1 + 360, int($2), $3 + 360, int($4)}') $MERIT/${var}/${tile}_${var}.tif $MERIT/${var}/${tile}_${var}_dis.tif
gdal_edit.py -a_nodata $ND $MERIT/${var}/${tile}_${var}_dis.tif
cp $MERIT/${var}/${tile}_${var}.tif $MERIT/${var}/${tile}_${var}_msk.tif
done
done

exit

