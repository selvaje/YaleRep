#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_merge5-10p_colorComposite.sh.%J.out   
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_merge5-10p_colorComposite.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_merge5-10p_colorComposite.sh

####   sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc31_merge5-10p_colorComposite.sh
####   sbatch  --dependency=afterany:$(qmys | grep sc28_tiling20d_aggregate.sh  | awk '{ print $1  }' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc31_merge5-10p_colorComposite.sh

export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# solo fatto per lbasin rstream non ha senso. 

echo lbasin stream dir  | xargs -n 1 -P 3 bash -c $'  
VAR=$1

if [ $VAR = "lbasin" ] ; then export TYPE=UInt32 ; export NODATA=0   ; fi 
if [ $VAR = "stream" ] ; then export TYPE=UInt32 ; export NODATA=0   ; fi 
if [ $VAR = "dir"    ] ; then export TYPE=Int16  ; export NODATA=-10 ; fi 


gdalbuildvrt -srcnodata $NODATA -vrtnodata $NODATA  -overwrite  -te -180 -60 180 85  $MERIT/${VAR}_tiles_final20d/all_tif.vrt   $MERIT/${VAR}_tiles_final20d/${VAR}_h??v??.tif 

gdalbuildvrt -srcnodata $NODATA -vrtnodata $NODATA  -overwrite  -te -180 -60 180 85  $MERIT/${VAR}_tiles_final20d_5p/all_tif.vrt   $MERIT/${VAR}_tiles_final20d_5p/${VAR}_h??v??_5p.tif 
gdalbuildvrt -srcnodata $NODATA -vrtnodata $NODATA  -overwrite  -te -180 -60 180 85  $MERIT/${VAR}_tiles_final20d_10p/all_tif.vrt   $MERIT/${VAR}_tiles_final20d_10p/${VAR}_h??v??_10p.tif 

echo merge the tiles
gdal_translate -a_nodata $NODATA -ot $TYPE  -co COMPRESS=DEFLATE -co ZLEVEL=9  $MERIT/${VAR}_tiles_final20d_5p/all_tif.vrt  $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p.tif
gdal_translate -a_nodata $NODATA -ot $TYPE  -co COMPRESS=DEFLATE -co ZLEVEL=9  $MERIT/${VAR}_tiles_final20d_10p/all_tif.vrt  $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p.tif

echo create color tif 

bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p.tif   $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p_color.txt
awk \'{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }\'    $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p_color.txt >   $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p_color0.txt
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9    $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p.tif   $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p_color0.txt  $MERIT/${VAR}_tiles_final20d_10p/${VAR}_10p_ct.tif  

bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p.tif   $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p_color.txt
awk \'{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }\'    $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p_color.txt >   $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p_color0.txt
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9   $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p.tif   $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p_color0.txt  $MERIT/${VAR}_tiles_final20d_5p/${VAR}_5p_ct.tif  


' _ 





