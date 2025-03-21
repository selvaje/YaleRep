#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc33_merge20d_1-40p_ct_compUnit.sh.%A_%a.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc33_merge20d_1-40p_ct_compUnit.sh.%A_%a.err
#SBATCH --job-name=sc33_merge20d_1-40p_ct_compUnit.sh
#SBATCH --mem=40G
#SBATCH --array=1-116

####  sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc33_merge20d_1-40p_ct_compUnit.sh

ulimit -c 0

source ~/bin/gdal3

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

### find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr
### find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr

export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )

if [ $SLURM_ARRAY_TASK_ID -eq 1 ] ; then 
rm -f $SCMH/lbasin_compUnit_overview/lbasin_compUnit.vrt $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.vrt
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit.vrt    $SCMH/lbasin_compUnit_tiles/bid*_msk.tif    $SCMH/lbasin_compUnit_large/bid???_msk.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.vrt $SCMH/lbasin_compUnit_tiles_ct/bid*_msk.tif $SCMH/lbasin_compUnit_large_ct/bid???_msk.tif
else 
sleep 100
fi 
echo start the computation 
GDAL_CACHEMAX=15000
gdal_translate -a_nodata 0 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $file) -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit.vrt  $SCMH/lbasin_compUnit_final20d_1p/${tile}_1p.tif 

echo filter ct

gdal_translate -a_nodata 0 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $file) -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.vrt $SCMH/lbasin_compUnit_final20d_1p_ct/${tile}_1p_ct.tif 


gdal_translate -a_nodata 0 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $file ) -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.0041666666666666666 0.0041666666666666666 -r mode -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit.vrt  $SCMH/lbasin_compUnit_final20d_5p/${tile}_5p.tif 

echo filter ct

gdal_translate -a_nodata 0 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $file  ) -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.0041666666666666666 0.0041666666666666666 -r mode -ot Byte -of GTiff $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.vrt $SCMH/lbasin_compUnit_final20d_5p_ct/${tile}_5p_ct.tif 

if [ $SLURM_ARRAY_TASK_ID -eq 116 ] ; then 

sleep 600

rm -f $SCMH/lbasin_compUnit_overview/lbasin_compUnit.vrt.ovr $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct.vrt.ovr

gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_1p.vrt    $SCMH/lbasin_compUnit_final20d_1p/*_1p.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct_1p.vrt $SCMH/lbasin_compUnit_final20d_1p_ct/*_1p_ct.tif
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_5p.vrt.ovr    $SCMH/lbasin_compUnit_final20d_5p/*_5p.tif 
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -a_srs EPSG:4326 -overwrite -te -180 -60 191 85 $SCMH/lbasin_compUnit_overview/lbasin_compUnit_ct_5p.vrt.ovr $SCMH/lbasin_compUnit_final20d_5p_ct/*_5p_ct.tif 

### merge 5p
echo "lbasin_compUnit lbasin_compUnit_ct"  | xargs -n 1 -P 2 bash -c $'
var=$1
GDAL_CACHEMAX=8000
gdal_translate -a_nodata 0 -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co TILED=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND \
$SCMH/lbasin_compUnit_overview/${var}_5p.vrt.ovr    $SCMH/lbasin_compUnit_overview/${var}_5p.tif
' _  
#### merge 1p 
echo "lbasin_compUnit lbasin_compUnit_ct"  | xargs -n 1 -P 2 bash -c $'
var=$1
GDAL_CACHEMAX=8000
gdal_translate -a_nodata 0 -projwin -180 85 191 -60 -co COPY_SRC_OVERVIEWS=YES -co TILED=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND \
$SCMH/lbasin_compUnit_overview/${var}.vrt   $SCMH/lbasin_compUnit_overview/${var}.tif
' _ 

fi 

exit 
### create computational  shapefile  for article figure 
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_overview
gdal_polygonize.py  lbasin_compUnit_5p.tif lbasin_compUnit_5p_shp.shp
ogr2ogr -simplify 0.1  -sql "SELECT * FROM lbasin_compUnit_5p_shp  WHERE OGR_GEOM_AREA > 0.01"   lbasin_compUnit_5p_shp_simp.shp  lbasin_compUnit_5p_shp.shp  
