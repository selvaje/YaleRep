#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc45_compUnit_stream_order_tile20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc45_compUnit_stream_order_tile20d.sh.%A_%a.err
#SBATCH --array=32,73
#SBATCH --mem=25G

####  1-116

####  for name in strahler  topo shreve hack horton vect ; do sbatch   --export=name=$name  --job-name=sc45_compUnit_stream_order_tile20d_$name.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc45_compUnit_stream_order_tile20d.sh ; done 

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export name=$name
export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=10000

echo $name

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 

if [ $name = strahler ] || [ $name = topo ] || [ $name = horton ] || [ $name = shreve ] || [ $name = hack ] ; then
gdalbuildvrt -overwrite  $SCMH/CompUnit_stream_order/all_tif_${name}_dis.vrt $SCMH/CompUnit_stream_order/${name}/order_${name}_*.tif
fi

if [ $name = vect ] ; then
echo merging vect 
rm -f $SCMH/CompUnit_stream_order/all_gpkg_${name}_dis.vrt
ogrmerge.py -single  -progress -skipfailures -t_srs EPSG:4326 -s_srs EPSG:4326  -overwrite_ds  -f VRT -o $SCMH/CompUnit_stream_order/all_gpkg_${name}_dis.vrt $SCMH/CompUnit_stream_order/${name}/order_${name}_?.gpkg $SCMH/CompUnit_stream_order/${name}/order_${name}_??.gpkg $SCMH/CompUnit_stream_order/${name}/order_${name}_???.gpkg

rm -f $SCMH/CompUnit_stream_order/all_gpkg_${name}_point_dis.vrt
ogrmerge.py -single  -progress -skipfailures -t_srs EPSG:4326 -s_srs EPSG:4326  -overwrite_ds  -f VRT -o $SCMH/CompUnit_stream_order/all_gpkg_${name}_point_dis.vrt $SCMH/CompUnit_stream_order/${name}/order_${name}_point_*.gpkg

rm -f $SCMH/CompUnit_stream_order/all_gpkg_${name}_segment_dis.vrt
ogrmerge.py -single  -progress -skipfailures -t_srs EPSG:4326 -s_srs EPSG:4326  -overwrite_ds  -f VRT -o $SCMH/CompUnit_stream_order/all_gpkg_${name}_segment_dis.vrt $SCMH/CompUnit_stream_order/${name}/order_${name}_segment_*.gpkg


fi 

fi

sleep 1000

if [ $name = strahler ] || [ $name = topo ] || [ $name = horton ] || [ $name = shreve ] || [ $name = hack ] ; then
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $file) $SCMH/CompUnit_stream_order/all_tif_${name}_dis.vrt $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.tif 

gdalinfo -mm $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.mm
fi 

if [ $name = vect ] ; then
echo $name split the vect
rm -f $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.gpkg
ogr2ogr -spat $(getCorners4Gwarp $file) -clipdst $(getCorners4Gwarp $file) -clipdstlayer merged  -t_srs EPSG:4326 -s_srs EPSG:4326  $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_${tile}.gpkg  $SCMH/CompUnit_stream_order/all_gpkg_${name}_dis.vrt

rm -f $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_point_${tile}.gpkg
ogr2ogr -spat $(getCorners4Gwarp $file) -clipdst $(getCorners4Gwarp $file) -clipdstlayer merged  -t_srs EPSG:4326 -s_srs EPSG:4326  $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_point_${tile}.gpkg  $SCMH/CompUnit_stream_order/all_gpkg_${name}_point_dis.vrt

rm -f $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_segment_${tile}.gpkg
ogr2ogr -spat $(getCorners4Gwarp $file) -clipdst $(getCorners4Gwarp $file) -clipdstlayer merged  -t_srs EPSG:4326 -s_srs EPSG:4326  $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_segment_${tile}.gpkg  $SCMH/CompUnit_stream_order/all_gpkg_${name}_segment_dis.vrt
fi 


if [  $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 3000

if [ $name = strahler ] || [ $name = topo ] || [ $name = horton ] || [ $name = shreve ] || [ $name = hack ] ; then
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_order_tiles20d/order_${name}.vrt $SCMH/CompUnit_stream_order_tiles20d/order_${name}_tiles20d/order_${name}_??????.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -r mode -tr 0.00833333333333 0.00833333333333 $SCMH/CompUnit_stream_order_tiles20d/order_${name}.vrt  $SCMH/CompUnit_stream_order_tiles20d/stream_${name}_10p.tif

fi 
fi 
exit 
