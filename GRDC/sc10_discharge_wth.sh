#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_discharge_wth.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_discharge_wth.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc10_discharge_wth.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRDC/sc10_discharge_wth.sh

find  /tmp/     -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

export GRDC=/project/fas/sbsc/ga254/dataproces/GRDC 
export RAM=/dev/shm

pksetmask -of GTiff  -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $GRDC/runoff/cmp_ro.grd  -msknodata -9999  -p '='  -nodata -9999 \
-m $GRDC/runoff/cmp_ro.grd  -msknodata 0  -p '<'  -nodata 0  -i $GRDC/runoff/cmp_ro.grd   -o $GRDC/runoff/cmp_ro.tif 

gdalwarp -s_srs EPSG:4326 -t_srs EPSG:4326 -ot Float32 -co COMPRESS=DEFLATE -co ZLEVEL=9  -overwrite -tr 0.08333333333333333333333  0.08333333333333333333333  -srcnodata -9999  -dstnodata -9999 -r bilinear   $GRDC/runoff/cmp_ro.tif  $GRDC/runoff_10km/cmp_ro_10km.tif

ls /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/wth/*_wth.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif  )
pkfilter -nodata -9999 -nodata 0  -nodata -1   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32  -dx 100 -dy 100 -d 100  -f mean -i $file -o   $RAM/$filename.tif
' _ 

gdalbuildvrt   -overwrite -srcnodata 0  -vrtnodata 0  $RAM/all_tif.vrt   $RAM/???????_wth.tif
gdal_translate  -a_nodata 0  -co COMPRESS=DEFLATE  -co ZLEVEL=9    $RAM/all_tif.vrt   $GRDC/runoff_10km/wth_mean10km.tif 

rm -f  $RAM/???????_wth.tif   $RAM/all_tif.vrt 

pksetmask -co COMPRESS=DEFLATE  -co ZLEVEL=9    -m  $GRDC/runoff_10km/cmp_ro_10km.tif  -msknodata -9999 -nodata -9999  -i    $GRDC/runoff_10km/wth_mean10km.tif   -o  /tmp/wth_mean10km_msk.tif 
gdal_translate -co COMPRESS=DEFLATE  -co ZLEVEL=9   -projwin $( getCorners4Gtranslate  $GRDC/runoff_10km/cmp_ro_10km.tif  )  /tmp/wth_mean10km_msk.tif  $GRDC/runoff_10km/wth_mean10km_msk.tif
 
rm -f /tmp/wth_mean10km_msk.tif

gdal_translate -of  XYZ $GRDC/runoff_10km/cmp_ro_10km.tif  /tmp/cmp_ro_10km.txt 
gdal_translate -of  XYZ $GRDC/runoff_10km/wth_mean10km_msk.tif  /tmp/wth_mean10km_msk.txt 

paste <( awk '{ print $3 }' /tmp/cmp_ro_10km.txt) <(awk '{ print $3}'   /tmp/wth_mean10km_msk.txt) | grep -v "\-9999"  | awk '{ if($1!=0 && $2!=0 ) print $0  }' | awk '{ if($2 >= 0 ) print $0  }'   > $GRDC/runoff_10km/cmp_ro_vs_wth_mean10km.txt 



