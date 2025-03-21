#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 1:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_rasterize_clumping_stations.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_rasterize_clumping_stations.sh.%J.err
#SBATCH --job-name=sc90_rasterize_clumping_stations.sh 
#SBATCH --mem=50G

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc90_rasterize_clumping_stations.sh 
ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools 
source ~/bin/grass78m

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/zip/GSIM_indices/TIMESERIES/monthly_shp 
export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/zip/GSIM_indices/TIMESERIES/monthly_shp 
export RAM=/dev/shm 
######                                                                              85 north limit of the MERIT_HYDRO
gdal_rasterize -a_nodata 0   -co COMPRESS=DEFLATE  -co ZLEVEL=9   -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2  -te -180 -51 180 85 -tr 0.0083333333333333 0.0083333333333333  -burn 1 -ot Byte -l station_x_y_gsim_no_shp     $DIR/station_x_y_gsim_no_shp.shp $DIR/station_x_y_gsim_no_1km.tif

echo  masking the west ### 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata 0 -i $DIR/station_x_y_gsim_no_1km.tif -o $RAM/station_x_y_gsim_no_1km_mskwest.tif

echo   transpose west to east ## 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  -180 75 -169 60 $DIR/station_x_y_gsim_no_1km.tif    $RAM/station_x_y_gsim_no_1km_cropwest.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif  -msknodata 0 -nodata 0  -i  $RAM/station_x_y_gsim_no_1km_cropwest.tif   -o   $RAM/station_x_y_gsim_no_1km_cropwestmsk.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr 180 75 191 60 $RAM/station_x_y_gsim_no_1km_cropwestmsk.tif $RAM/station_x_y_gsim_no_1km_transpose2east.tif 

echo  merge  #### 
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -te -180 -51 191 85 $RAM/station_x_y_gsim_no_1km.vrt  $RAM/station_x_y_gsim_no_1km_transpose2east.tif  $RAM/station_x_y_gsim_no_1km_mskwest.tif

gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot Byte $RAM/station_x_y_gsim_no_1km.vrt $DIR/station_x_y_gsim_no_1km_dis.tif

rm -f $RAM/station_x_y_gsim_no_1km_cropwestmsk.tif $RAM/station_x_y_gsim_no_1km_transpose2east.tif  $RAM/station_x_y_gsim_no_1km_cropwest.tif $RAM/station_x_y_gsim_no_1km.vrt $RAM/station_x_y_gsim_no_1km_mskwest.tif  

cp $DIR/station_x_y_gsim_no_1km_dis.tif /dev/shm 

grass78  -f -text --tmp-location  -c /dev/shm/station_x_y_gsim_no_1km_dis.tif   <<'EOF'
r.external input=/dev/shm/station_x_y_gsim_no_1km_dis.tif output=raster 
r.grow  input=raster   output=raster_grow  radius=10
r.clump -d  input=raster_grow   output=raster_clump       --o 
r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=Int16  format=GTiff nodata=0  input=raster_clump output=$DIR/station_x_y_gsim_no_1km_clump.tif
EOF

rm -f /dev/shm/station_x_y_gsim_no_1km.tif 

cp $DIR/station_x_y_gsim_no_1km_clump.tif  /dev/shm/station_x_y_gsim_no_1km_clump.tif 

seq 1 $(pkstat -max  -i   /dev/shm/station_x_y_gsim_no_1km_clump.tif | awk '{ print $2  }' ) | xargs -n 1 -P 8   bash -c $' 
geo_string=$( oft-bb station_x_y_gsim_no_1km_clump.tif   ${1}  | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\') 1>/dev/null
gdal_translate -srcwin $geo_string  -co COMPRESS=DEFLATE  -co ZLEVEL=9   /dev/shm/station_x_y_gsim_no_1km_clump.tif  /dev/shm/ID${1}.tif   1>/dev/null 
echo $1 $(getCorners4Gtranslate  /dev/shm/ID${1}.tif )
rm /dev/shm/ID$1.tif 
' _     >   $DIR/station_clump_tmp.txt

sed 's/667/666/g'  $DIR/station_clump_tmp.txt > $DIR/station_clump.txt 
mv  $DIR/station_clump_tmp.txt

rm /dev/shm/station_x_y_gsim_no_1km_clump.tif 


