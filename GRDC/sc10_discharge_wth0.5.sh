#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_discharge_wth0.5.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_discharge_wth0.5.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc10_discharge_wth0.5.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GRDC/sc10_discharge_wth0.5.sh

# find  /tmp/     -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
# find  /dev/shm  -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

export GRDC=/project/fas/sbsc/ga254/dataproces/GRDC 
export RAM=/dev/shm

ls /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/wth/*_wth.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif  )
pkfilter -nodata -9999 -nodata 0  -nodata -1   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32  -dx 600 -dy 600 -d 600  -f mean -i $file -o   $RAM/$filename.tif
' _ 

gdalbuildvrt   -overwrite -srcnodata 0  -vrtnodata 0  $RAM/all_tif.vrt   $RAM/???????_wth.tif
gdal_translate  -a_nodata 0  -co COMPRESS=DEFLATE  -co ZLEVEL=9    $RAM/all_tif.vrt   $GRDC/runoff_10km/wth_mean0.5deg.tif 



rm -f  $RAM/???????_wth.tif   $RAM/all_tif.vrt 

pksetmask -co COMPRESS=DEFLATE  -co ZLEVEL=9    -m  $GRDC/runoff/cmp_ro.tif  -msknodata -9999 -nodata -9999  -i    $GRDC/runoff_10km/wth_mean0.5deg.tif   -o  /tmp/wth_mean0.5deg_msk.tif 
gdal_translate -co COMPRESS=DEFLATE  -co ZLEVEL=9   -projwin $( getCorners4Gtranslate  $GRDC/runoff/cmp_ro.tif   )  /tmp/wth_mean0.5deg_msk.tif    $GRDC/runoff_10km/wth_mean0.5deg_msk.tif 
 
rm -f  /tmp/wth_mean0.5deg_msk.tif 

gdal_translate -of  XYZ $GRDC/runoff/cmp_ro.tif                   /tmp/cmp_ro_0.5deg.txt 
gdal_translate -of  XYZ $GRDC/runoff_10km/wth_mean0.5deg_msk.tif  /tmp/wth_mean0.5deg_msk.txt 

paste <( awk '{ print $3 }'   /tmp/cmp_ro_0.5deg.txt  ) <(awk '{ print $3}'  /tmp/wth_mean0.5deg_msk.txt  ) | grep -v "\-9999"  | awk '{ if($1!=0 && $2!=0 ) print $0  }' | awk '{ if($2 >= 0 ) print $0  }'   > $GRDC/runoff_10km/cmp_ro_vs_wth_mean0.5deg.txt 



