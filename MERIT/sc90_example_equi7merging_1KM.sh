#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 5  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_example_equi7merging_1KM.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_example_equi7merging_1KM.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc90_example_equi7merging_1KM.sh
#SBATCH --mem-per-cpu=10000

# for TOPO in vrm tri spi cti aspect-sine aspect-cosine dxx  dx tcurv  pcurv ; do     sbatch  --export=TOPO=$TOPO  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc90_example_equi7merging_1KM.sh ; done 
# for  TOPO in vrm tri spi cti aspect-sine aspect-cosine dxx  dx tcurv  pcurv ; do  rm $TOPO/${TOPO}*.{vrt,tif}  ; done 
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export TOPO=$TOPO
export RAM=/dev/shm
# export  TOPO=vrm

cd /project/fas/sbsc/ga254/dataproces/MERIT/aspect-cosine/tiles 
# --config GDAL_CACHEMAX 5000 -overwrite -wm 5000

echo AF 
echo  -31 -43 80 0 S  -31 0  80 39 N   | xargs -n 5  -P 2  bash -c $'
CT=AF  # africa south and north  

gdalwarp -overwrite -co COMPRESS=DEFLATE  -r bilinear -srcnodata -9999 -dstnodata -9999 -tr 0.00833333333333333333333333333 0.00833333333333333333333333333 -te $1 $2 $3 $4  -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $MERIT/$TOPO/tiles/all_${CT}_tif.vrt  $MERIT/$TOPO/${TOPO}_${CT}_$5.tif
pksetmask -of GTiff -m $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM1.00.tif -msknodata  0 -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $MERIT/$TOPO/${TOPO}_${CT}_$5.tif  -o $MERIT/$TOPO/${TOPO}_${CT}_1KM_$5.tif
' _ & # send to the background 

echo AS 
echo -180 0 -150 85 W 50 0 180 85 E  | xargs -n 5  -P 2  bash -c $'
CT=AS  # asia west and east 
gdalwarp --config GDAL_CACHEMAX 2000 -overwrite -wm 2000 -overwrite -co COMPRESS=DEFLATE  -r bilinear -srcnodata -9999 -dstnodata -9999 -tr 0.00833333333333333333333333333 0.00833333333333333333333333333 -te $1 $2 $3 $4  -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $MERIT/$TOPO/tiles/all_${CT}_tif.vrt  $MERIT/$TOPO/${TOPO}_${CT}_$5.tif
pksetmask -of GTiff -m $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM1.00.tif -msknodata  0 -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $MERIT/$TOPO/${TOPO}_${CT}_$5.tif  -o $MERIT/$TOPO/${TOPO}_${CT}_1KM_$5.tif
' _ 

echo    AN  EU  NA  OC  SA 
echo    AN  EU  NA  OC  SA | xargs -n 1 -P 6 bash -c $'
CT=$1
gdalwarp --config GDAL_CACHEMAX 2000 -overwrite -wm 2000 -overwrite -co COMPRESS=DEFLATE  -r bilinear -srcnodata -9999 -dstnodata -9999 -tr 0.00833333333333333333333333333 0.00833333333333333333333333333 -te $(getCornersOgr4Gwarp  $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.shp | awk \'{ print int($1) , int($2) , int($3+1) , int($4+1) }\' )   -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $MERIT/$TOPO/tiles/all_${CT}_tif.vrt  $MERIT/$TOPO/${TOPO}_${CT}.tif
pksetmask -of GTiff -m $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM1.00.tif -msknodata  0 -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $MERIT/$TOPO/${TOPO}_${CT}.tif  -o $MERIT/$TOPO/${TOPO}_${CT}_1KM.tif
' _ 

echo start composite 

pkcomposite -cr mean -srcnodata -9999 -dstnodata -9999 -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $MERIT/$TOPO/${TOPO}_AF_1KM.tif  -i $MERIT/$TOPO/${TOPO}_AN_1KM.tif   -i $MERIT/$TOPO/${TOPO}_AS_1KM_E.tif -i $MERIT/$TOPO/${TOPO}_AS_1KM_W.tif -i $MERIT/$TOPO/${TOPO}_AF_1KM_S.tif -i $MERIT/$TOPO/${TOPO}_AF_1KM_N.tif   -i $MERIT/$TOPO/${TOPO}_EU_1KM.tif  -i $MERIT/$TOPO/${TOPO}_NA_1KM.tif -i $MERIT/$TOPO/${TOPO}_OC_1KM.tif  -i $MERIT/$TOPO/${TOPO}_SA_1KM.tif  -o $MERIT/$TOPO/${TOPO}_1KM.tif
