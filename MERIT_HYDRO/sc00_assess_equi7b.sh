#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc00_assess_equi7b.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc00_assess_equi7b.sh.%J.err
#SBATCH --mem-per-cpu=10000

#### sbatch /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc00_assess_equi7b.sh 

source ~/bin/gdal
source ~/bin/pktools

export INDIR=/project/fas/sbsc/hydro/dataproces/MERIT_HYDRO/test 
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm

cd $INDIR/

export RES=0.00083333333333333333333333333 
CT=EU

for file in direction.tif  lbasin.tif  stream.tif ; do
filename=$(basename $file .tif )

#  9999MEGA 
gdalwarp   -wm 9999   \
-overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  \
-r near  -tr ${RES} ${RES} -tap  -te  4 55 20 70    \
-s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj   -of vrt  $INDIR/$file /vsistdout/ | gdal_translate  --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 30000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  /vsistdin/   $INDIR/${filename}_wgs84.tif
done 


file=accumulation_fillnodata.tif
filename=$(basename $file .tif )

#  9999MEGA 
gdalwarp   -wm 9999   \
-overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  \
-r bilinear  -tr ${RES} ${RES} -tap  -te  4 55 20 70    \
-s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj   -of vrt  $INDIR/$file /vsistdout/ | gdal_translate  --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 30000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  /vsistdin/   $INDIR/${filename}_wgs84.tif


gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 30000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -projwin $(getCorners4Gtranslate $INDIR/direction_wgs84.tif) /gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO/dep/all_tif.vrt $INDIR/dep_wgs84.tif
gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 30000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -projwin $(getCorners4Gtranslate $INDIR/direction_wgs84.tif) /gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt $INDIR/dem_wgs84.tif

pksetmask --config GDAL_CACHEMAX 3000   -m  $INDIR/dem_wgs84.tif  -msknodata -9999  -nodata -999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -i $INDIR/${filename}_wgs84.tif -o  $INDIR/${filename}_wgs84_msk.tif 
