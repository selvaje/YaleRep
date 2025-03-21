#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7_fromEqui7_to_WGS84.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7_fromEqui7_to_WGS84.sh.%J.err
#SBATCH --mem-per-cpu=10000

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7_fromEqui7_to_WGS84.sh

source ~/bin/gdal
source ~/bin/pktools

export INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/test 
export EQUI=/gpfs/gibbs/pi/hydro/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm

cd $INDIR/

export RES=0.00083333333333333333333333333 
CT=EU


PROJ4=$(cat /gpfs/gibbs/pi/hydro/hydro/dataproces//EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.proj4  | tr -d "\'" )

for file in direction_ws_inEqui7.tif direction_ex_inEqui7.tif   lbasin_inEqui7.tif  stream_inEqui7.tif ; do
filename=$(basename $file  _inEqui7.tif)

#  9999MEGA 
gdalwarp   -wm 9999   \
-overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  \
-r near  -tr ${RES} ${RES} -tap  -te  4 57 20 70    \
-s_srs  "${PROJ4}"     -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj   -of vrt  $INDIR/$file /vsistdout/ | gdal_translate  --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 15000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  /vsistdin/   $INDIR/${filename}_fromEqui7.tif
done 


for file in accumulation_nodataset_inEqui7.tif  accumulation_inEqui7.tif  ; do 

filename=$(basename $file _inEqui7.tif )

#  9999MEGA 
gdalwarp   -wm 9999   \
-overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  \
-r bilinear  -tr ${RES} ${RES} -tap  -te  4 57 20 70    \
-s_srs  "${PROJ4}"    -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj   -of vrt  $INDIR/$file /vsistdout/ | gdal_translate  --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 15000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  /vsistdin/   $INDIR/${filename}_fromEqui7.tif

done 

exit 

ogr2ogr -s_srs  "${PROJ4}" -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj  $INDIR/stream_fromEqui7.shp  $INDIR/stream_inEqui7.shp



