#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_continue90M_to10KMforValidation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_continue90M_to10KMforValidation.sh.%J.err



# for TOPO in stdev aspect dx dxx dxy dy dyy pcurv roughness slope tcurv  tpi  tri vrm tci spi convergence intensity exposition range variance elongation azimuth extend width  ; do  for MATH in min max mean median stdev ; do for  KM in 5 ; do  sbatch  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc12_continue90M_to10KMforValidation.sh ; done ; done ; done



echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT

export res=$( expr $KM \* 10)
export TOPO
export MATH 
export KM


if [ $TOPO != "aspect"   ] ; then 

ls -rt  $MERIT/$TOPO/tiles/*_E7.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -9999 -dx $res -dy $res -f $MATH -d $res -i $MERIT/$TOPO/tiles/$filename.tif  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )  -overwrite  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*_E7.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7forVal.tif 
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*_E7.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

fi 

if [ $TOPO = "aspect"   ] ; then 

for FUN in sin cos Ew Nw ; do
export FUN

ls -rt  $MERIT/$TOPO/tiles/*_E7_$FUN.tif    | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff -nodata -9999 -dx $res -dy $res -f $MATH -d $res -i $MERIT/$TOPO/tiles/${filename}.tif  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/${filename}.tif

' _ 

if [ $FUN = "sin" ]       ; then TOPON=aspectsine   ; fi 
if [ $FUN = "cos" ]       ; then TOPON=aspectcosine ; fi 
if [ $FUN = "Ew" ]        ; then TOPON=eastness     ; fi 
if [ $FUN = "Nw" ]        ; then TOPON=northness    ; fi 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt -te  $(getCorners4Gwarp /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt ) -overwrite  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*_$FUN.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT_E7forVAL.tif 
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

done 

fi 

sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


exit 
