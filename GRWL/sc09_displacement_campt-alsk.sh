#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_displacement_campt-alsk.sh.sh.%J.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_displacement_campt-alsk.sh.sh.%J.err
#SBATCH --job-name=sc09_displacement_campt-alsk.sh
#SBATCH --mem=20G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc09_displacement_campt-alsk.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRWL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01_wgs84_tif
export RAM=/dev/shm

find  /tmp/     -user $USER -mtime +4   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +4   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# camptch & alaska   # area in displacement from -180 -169 to 180 191   nord 72 south   64

for tile in h00v01  h00v02;  do   
#### masking the west 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 1 -nodata 0  -i $GRWL/${tile}.tif -o $GRWL/${tile}_msk.tif 
gdal_edit.py -a_nodata 0 $GRWL/${tile}_msk.tif
###  transpose west to east
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 0 -nodata 0 -i $GRWL/${tile}.tif -o $GRWL/${tile}_tmp.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $GRWL/${tile}_tmp.tif | awk '{print $1 + 360, int($2), $3 + 360, int($4)}') $GRWL/${tile}_tmp.tif $GRWL/${tile}_dis.tif
gdal_edit.py -a_nodata 0 $GRWL/${tile}_dis.tif
rm $GRWL/${tile}_tmp.tif
done

#### without displacement 
gdalbuildvrt -overwrite  -srcnodata 0 -vrtnodata  0  $GRWL/all_tif.vrt  $GRWL/h??v??.tif 
rm -f $GRWL/all_tif_shp.* 
gdaltindex $GRWL/all_tif_shp.shp $GRWL/h??v??.tif 

#### with displacement 
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $GRWL/all_tif_dis.vrt $(ls $GRWL/h??v??.tif | grep -v h00v01 | grep -v h00v02) $GRWL/h00v01_dis.tif $GRWL/h00v02_dis.tif $GRWL/h00v02_msk.tif $GRWL/h00v01_msk.tif

rm  -f   $GRWL/all_tif_dis_shp.*
gdaltindex $GRWL/all_tif_dis_shp.shp $GRWL/all_tif_dis.vrt $(ls $GRWL/h??v??.tif | grep -v h00v01 | grep -v h00v02) $GRWL/h00v01_dis.tif $GRWL/h00v02_dis.tif $GRWL/h00v02_msk.tif $GRWL/h00v01_msk.tif

######  1k rest 
GDAL_CACHEMAX=14000
gdal_translate -tr 0.00833333333333333  0.00833333333333333  -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $GRWL/all_tif.vrt       $GRWL/all_tif_1km.tif
gdal_translate -tr 0.00833333333333333  0.00833333333333333  -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $GRWL/all_tif_dis.vrt   $GRWL/all_tif_dis_1km.tif

