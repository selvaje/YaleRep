#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 2  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_displacement_campt-alsk.sh.sh.%J.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_displacement_campt-alsk.sh.sh.%J.err
#SBATCH --job-name=sc09_displacement_campt-alsk.sh
#SBATCH --mem=20G

#### for var in change extent occurrence recurrence seasonality; do sbatch --export=var=$var   /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc09_displacement_campt-alsk.sh; done 

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GSW=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input
export RAM=/dev/shm

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

## var=change

# camptch & alaska   # area in displacement from -180 -169 to 180 191   nord 72 south   64
#########  for file in h*v*.tif ; do   gdal_edit.py -tr 0.00027777777777777   -0.00027777777777777 $file  ; done 

#### without displacement 
gdalbuildvrt -overwrite  -srcnodata 255  -vrtnodata 255  $GSW/$var/all_tif.vrt  $GSW/$var/${var}_*_*v1_1_2019.tif
rm -f $GSW/$var/all_tif_shp.* 
gdaltindex $GSW/$var/all_tif_shp.shp  $GSW/$var/${var}_*_*v1_1_2019.tif

for tile in 180W_80N 170W_80N 170W_70N 180W_70N ;  do   
#### masking the west 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 1 -nodata 255  -i $GSW/${var}/${var}_${tile}v1_1_2019.tif -o $GSW/${var}/${var}_${tile}v1_1_2019_msk.tif 
gdal_edit.py -a_nodata 255  $GSW/${var}/${var}_${tile}v1_1_2019_msk.tif
###  transpose west to east
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $MERIT/displacement/camp.tif -msknodata 0 -nodata 255  -i $GSW/${var}/${var}_${tile}v1_1_2019.tif -o $GSW/${var}/${var}_${tile}v1_1_2019_tmp.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr $(getCorners4Gtranslate $GSW/${var}/${var}_${tile}v1_1_2019_tmp.tif | awk '{print $1 + 360, int($2), $3 + 360, int($4)}') $GSW/${var}/${var}_${tile}v1_1_2019_tmp.tif $GSW/${var}/${var}_${tile}v1_1_2019_dis.tif
gdal_edit.py -a_nodata 255  $GSW/${var}/${var}_${tile}v1_1_2019_dis.tif
rm $GSW/${var}/${var}_${tile}v1_1_2019_tmp.tif
done

#### with displacement 
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $GSW/${var}/all_tif_dis.vrt $(ls $GSW/${var}/${var}_*_*v1_1_2019.tif | grep -v 180W_80N | grep -v 170W_80N | grep -v 170W_70N | grep -v 180W_70N)  $GSW/${var}/${var}_*_dis.tif $GSW/${var}/${var}_*_msk.tif

rm  -f   $GSW/${var}/all_tif_dis_shp.*
gdaltindex $GSW/${var}/all_tif_dis_shp.shp $(ls $GSW/${var}/${var}_*_*v1_1_2019.tif | grep -v 180W_80N | grep -v 170W_80N | grep -v 170W_70N | grep -v 180W_70N)  $GSW/${var}/${var}_*_dis.tif  $GSW/${var}/${var}_*_msk.tif 

######  1k rest 
GDAL_CACHEMAX=14000
gdal_translate -tr 0.00833333333333333  0.00833333333333333 -co NUM_THREADS=2 -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $GSW/${var}/all_tif.vrt       $GSW/${var}/${var}_all_tif_1km.tif
gdal_translate -tr 0.00833333333333333  0.00833333333333333 -co NUM_THREADS=2 -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9   $GSW/${var}/all_tif_dis.vrt   $GSW/${var}/${var}_all_tif_dis_1km.tif

