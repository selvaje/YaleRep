#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 7  -N 1  
#SBATCH -t 10:00:00
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_equi_warp_wgs84_continue_1_100KM.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_equi_warp_wgs84_continue_1_100KM.sh.%J.err

# for TOPO in deviation multirough altitude stdev aspect dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm tci spi convergence intensity exposition range variance elongation azimuth extend width ; do for MATH in min max mean median stdev ; do for KM in 1 5 10; do sbatch --export=TOPO=$TOPO,KM=$KM,MATH=$MATH /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_1_100KM.sh ; done ; done ; done 

# sbatch  --export=TOPO=altitude,MATH=median,KM=5 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_warp_wgs84_continue_1_100KM.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm

export TOPO
export KM
export MATH
export RES=$(echo  0.00083333333333333333333333333 \* 10 \* $KM | bc -l )

if [ $TOPO != "aspect" ] &&  [ $TOPO != "deviation" ] &&  [ $TOPO != "multirough" ]  ; then 

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'
CT=$1
# for these resolutions we keep the te equal to the full globe
gdalwarp -overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -r bilinear -srcnodata -9999 -dstnodata -9999 -tr ${RES:0:22} ${RES:0:22} -te -180.0000000 -60.0000000 180.0000000 85.0000000 -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj    -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}.tif $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM$KM.tif  -msknodata 0 -nodata -9999 -i $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif -o  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_wgs84.tif 

rm $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif

' _

echo start pkstatprofile 
gdalbuildvrt  -overwrite  -separate  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt   $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_wgs84.tif
pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -nodata -9999 -f mean  -i  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt -o  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7.tif  

rm   $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif   $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt  $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_wgs84.tif

fi


if [ $TOPO = "aspect"   ] ; then 

for FUN in sin cos Ew Nw ; do
export FUN

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'
CT=$1
gdalwarp -overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -r bilinear -srcnodata -9999 -dstnodata -9999 -tr ${RES:0:22} ${RES:0:22} -te -180.0000000 -60.0000000 180.0000000 85.0000000 -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj    -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${FUN}.tif $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${FUN}.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM$KM.tif  -msknodata 0 -nodata -9999 -i $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${FUN}.tif -o  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${FUN}_wgs84.tif 

rm $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${FUN}.tif

' _

if [ $FUN = "sin" ]       ; then TOPON=aspectsine   ; fi
if [ $FUN = "cos" ]       ; then TOPON=aspectcosine ; fi
if [ $FUN = "Ew"  ]       ; then TOPON=eastness     ; fi  
if [ $FUN = "Nw"  ]       ; then TOPON=northness    ; fi 

echo start pkstatprofile 
gdalbuildvrt  -overwrite  -separate  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${FUN}_wgs84.vrt   $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_${FUN}_wgs84.tif
pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -nodata -9999 -f mean  -i  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${FUN}_wgs84.vrt -o  $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT_E7_tmp.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT_E7_tmp.tif  $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT_E7.tif  
 
rm $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${FUN}_wgs84.vrt  $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_${FUN}_wgs84.tif  $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT_E7_tmp.tif  
done 
fi 

if [ $TOPO = "deviation" ]  ||  [ $TOPO = "multirough" ] ; then 


if [ $TOPO = "deviation" ]   ; then export  TOPON=devi ; fi 
if [ $TOPO = "multirough" ]  ; then export  TOPON=roug ; fi 

for FUN in mag sca ; do
export FUN

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'   
CT=$1
gdalwarp -overwrite  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -r bilinear -srcnodata -9999 -dstnodata -9999 -tr ${RES:0:22} ${RES:0:22} -te -180.0000000 -60.0000000 180.0000000 85.0000000 -s_srs  $EQUI/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj    -t_srs $EQUI/${CT}/GEOG/EQUI7_V13_${CT}_GEOG_ZONE.prj $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_${FUN}.tif $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${TOPON}_${FUN}.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM$KM.tif  -msknodata 0 -nodata -9999 -i $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${TOPON}_${FUN}.tif -o  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_${FUN}_wgs84.tif 

rm $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}_${TOPON}_${FUN}.tif

' _

if [ $FUN = "mag" ] && [ $TOPO = "multirough" ]    ; then NAME=roughnessmag ; fi
if [ $FUN = "sca" ] && [ $TOPO = "multirough" ]    ; then NAME=roughnesssca ; fi
if [ $FUN = "mag" ] && [ $TOPO = "deviation" ]     ; then NAME=deviationmag ; fi
if [ $FUN = "sca" ] && [ $TOPO = "deviation" ]     ; then NAME=deviationsca ; fi


echo start pkstatprofile  
gdalbuildvrt  -overwrite  -separate  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${TOPON}_${FUN}_wgs84.vrt   $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_${TOPON}_${FUN}_wgs84.tif
pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -nodata -9999 -f mean  -i  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${TOPON}_${FUN}_wgs84.vrt -o  $MERIT/$TOPO/$MATH/${NAME}_${KM}KM${MATH}_MERIT_E7_tmp.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $MERIT/$TOPO/$MATH/${NAME}_${KM}KM${MATH}_MERIT_E7_tmp.tif  $MERIT/$TOPO/$MATH/${NAME}_${KM}KM${MATH}_MERIT_E7.tif  
 
rm $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_${TOPON}_${FUN}_wgs84.vrt  $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_${TOPON}_${FUN}_wgs84.tif  $MERIT/$TOPO/$MATH/${NAME}_${KM}KM${MATH}_MERIT_E7_tmp.tif  
done 
fi 

sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

