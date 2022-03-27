#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_dem_variables_float_noMult_resKM.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_dem_variables_float_noMult_resKM.sh.%J.err

# for TOPO in altitude  aspect dx dxx dxy dy dyy pcurv roughness slope  tcurv  tpi  tri vrm tci spi convergence intensity exposition range variance elongation azimuth extend width  ; do  for MATH in min max mean median stdev ; do for  KM in 1 5 10 50 100 ; do  sbatch  -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err -J sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_dem_variables_float_noMult_resKM_continue.sh ; done ; done ; done

# create working dir 
# for VAR in  dx dxx dxy dy dyy pcurv roughness slope tcurv  tpi  tri vrm spi tci convergence  intensity exposition range variance elongation azimuth extend width   ; do for MATH in min max mean median  stdev ; do for  KM in 1 5 10 50 100  ; do mkdir -p  $VAR/$MATH/tiles_km$KM ; done ; done ; done

# grep pkfilter  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_re* | awk -F : '{ print $1 }' | uniq > /tmp/fale_node.txt
# grep slurmstepd:  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_r* |  awk -F : '{ print $1 }' | uniq  > /tmp/fale_node.txt
# awk '{  gsub ("/gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_resKM"," ") ; gsub ("TOPO"," ")  ;  gsub ("MATH"," ") ; gsub (".sh"," ") ;   print $1 , $2  , $3    }'   /tmp/fale_node.txt  > /tmp/fale_node_clean.txt 

# cat /tmp/fale_node_clean.txt | xargs -n 3 -P 1 bash -c $' sbatch  -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_variables_merge_resKM${1}TOPO${2}MATH${3}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_resKM${1}TOPO${2}MATH${3}.sh.%J.err -J sc04_variables_merge_resKM${1}TOPO${2}MATH${3}.sh  --export=TOPO=$2,MATH=$3,KM=$1 /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_dem_variables_float_noMult_resKM.sh ' _ 
# for file in $( cat  /tmp/fale_node.txt | awk '{ gsub("err" , "out") ; print   }'   ) ; do rm $file ; done ; for file in $( cat  /tmp/fale_node.txt   ) ; do rm $file ; done


# altitude
# for testing
# for TOPO in altitude  ; do for MATH in min ; do for  KM in 1  ; do   sbatch  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_dem_variables_float_noMult_resKM.sh ; done ; done ; done   

# 

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


if [ $TOPO = "altitude"   ] ; then 

# median and mean direct on the pixel value 

ls -rt  $MERIT/input_tif/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

# median on the stdev 3x3 

ls -rt  $MERIT/$TOPO/tiles/*_stdev.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/stdev_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999  $MERIT/$TOPO/$MATH/stdev_${KM}KM${MATH}_MERIT.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

fi 

if [ $TOPO != "aspect"   ] &&  [ $TOPO != "altitude" ] ; then 

ls -rt  $MERIT/$TOPO/tiles/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -9999 -dx $res -dy $res -f $MATH -d $res -i $MERIT/$TOPO/tiles/$filename.tif  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif 
# rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

fi 



if [ $TOPO = "aspect"   ] ; then 

for FUN in sin cos Ew Nw ; do
export FUN

ls -rt  $MERIT/$TOPO/tiles/*_$FUN.tif    | xargs -n 1 -P 8 bash -c $' 
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
gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999   $MERIT/$TOPO/$MATH/${TOPON}_${KM}KM${MATH}_MERIT.tif 
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

done 

fi 

sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 


exit 



for id in $(   grep slurmstepd:  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_r* | grep CANCELLED | awk -F : '{ print $1 }' | uniq  | awk -F "." '{ print $(NF-1)}' | sort | uniq  ) ; do sacct  -j  $id --format=NodeList ; done | sort | uniq

for id in $(grep pkfilter /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_re* | awk -F : '{ print $1 }' | uniq | awk -F .  '{  print $(NF-1)  }'  | sort | uniq ) ; do sacct  -j  $id  --format=NodeList ; done  | sort | uniq 
