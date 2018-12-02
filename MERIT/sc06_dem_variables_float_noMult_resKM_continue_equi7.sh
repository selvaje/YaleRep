#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_dem_variables_float_noMult_resKM_continue_equi7.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_dem_variables_float_noMult_resKM_continue_equi7.sh.%J.err

# for TOPO in deviation multirough  altitude  aspect stdev dx dxx dxy dy dyy pcurv roughness slope  tcurv  tpi  tri vrm tci spi convergence intensity exposition range variance elongation azimuth extend width  ; do  for MATH in min max mean median stdev ; do for  KM in 1 5 10  ; do  sbatch  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc06_dem_variables_float_noMult_resKM_continue_equi7.sh ; done ; done ; done

# create working dir 
# for VAR in altitude stdev  dx dxx dxy dy dyy pcurv roughness slope tcurv  tpi  tri vrm spi tci convergence  intensity exposition range variance elongation azimuth extend width   ; do for MATH in min max mean median  stdev ; do for  KM in 1 5 10 50 100  ; do mkdir -p  $VAR/$MATH/tiles_km$KM ; done ; done ; done

# for testing
# for TOPO in deviation  ; do for MATH in mean ; do for KM in 1; do sbatch --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc06_dem_variables_float_noMult_resKM_continue_equi7.sh; done ; done ; done   

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export RAM=/dev/shm

export TOPO
export MATH
export KM
export res=$( expr $KM \* 10)

if [ $TOPO = "altitude"   ] ; then 

# math ( median ,  mean ... )  on the pixel value

find   $MERIT/equi7/dem -name "*.tif" | xargs -n 1 -P 20  bash -c $'
file=$1
filename=$(basename $file .tif )
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff -dx $res -dy $res -f $MATH -d $res -i $file -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif
' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 10  bash -c $'
CT=$1
gdalbuildvrt -overwrite  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???.tif  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt 
' _
fi 

if [ $TOPO != "aspect"   ] &&  [ $TOPO != "altitude" ]    &&  [ $TOPO != "deviation" ] &&  [ $TOPO != "multirough" ] ; then 

ls -rt  $SCRATCH/$TOPO/tiles/??_???_???.tif     | xargs -n 1 -P 20  bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -9999 -dx $res -dy $res -f $MATH -d $res -i $file -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif
' _ 

echo starting the merging  $SCRATCH/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 10  bash -c $'
CT=$1
gdalbuildvrt  -overwrite  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}.tif  
rm -f $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???.tif            $SCRATCH/$TOPO/$MATH/${CT}_tiles_km$KM.vrt   
' _ 

fi 

if [ $TOPO = "aspect"   ] ; then 

for FUN in sin cos Ew Nw ; do
export FUN

ls -rt  $SCRATCH/$TOPO/tiles/??_???_???_$FUN.tif  | xargs -n 1 -P 20  bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff -nodata -9999 -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif
' _ 



echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'
CT=$1
# if condition not used 
if [ $FUN = "sin" ]       ; then TOPON=aspectsine   ; fi 
if [ $FUN = "cos" ]       ; then TOPON=aspectcosine ; fi 
if [ $FUN = "Ew"  ]       ; then TOPON=eastness     ; fi 
if [ $FUN = "Nw"  ]       ; then TOPON=northness    ; fi 
echo starting the merging  $SCRATCH/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT.tif  
gdalbuildvrt  -overwrite  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_$FUN.vrt  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???_$FUN.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_$FUN.vrt     $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_$FUN.tif  
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???_$FUN.tif  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_$FUN.vrt     
' _ 
done 
fi 


if [ $TOPO = "deviation" ] || [ $TOPO = "multirough" ]  ; then 

if [ $TOPO = "deviation" ]   ; then export  TOPON=devi ; fi 
if [ $TOPO = "multirough" ]  ; then export  TOPON=roug ; fi 

for FUN in mag sca  ; do
export FUN
ls -rt  $SCRATCH/$TOPO/tiles/??_???_???_${TOPON}_$FUN.tif  | xargs -n 1 -P 8  bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff -nodata -9999 -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif
' _ 

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'
CT=$1
# if condition not used 
if [ $FUN = "mag" ]       ; then NAME=multiroughness ; fi 
if [ $FUN = "sca" ]       ; then NAME=scaleroughness ; fi 

echo starting the merging  $SCRATCH/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT.tif  
gdalbuildvrt  -overwrite   $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_$FUN.vrt  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???_${TOPON}_$FUN.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_$FUN.vrt $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_$FUN.tif  
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/${CT}_???_???_${TOP0N}_$FUN.tif  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_${TOPON}_$FUN.vrt     
' _ 
done 
fi 







sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

exit 

