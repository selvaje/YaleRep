#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_dem_variables_float_noMult_resKM.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_dem_variables_float_noMult_resKM.sh.%J.err

# for TOPO in forms ; do  for MATH in count majority percent  ; do for  KM in 1 5 10 50 100 ; do  sbatch  -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err -J sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_dem_variables_float_noMult_resKM_categorical.sh ; done   ; done ; done   


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


if [ $MATH = "count"   ] ; then 

# count for forms  

ls -rt  $MERIT/forms/tiles/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  

pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx $res -dy $res -f countid  -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/geom_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata   0  $MERIT/$TOPO/$MATH/geom_${KM}KM${MATH}_MERIT.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

fi 

if [ $MATH = "majority"   ] ; then 

# count for forms  

ls -rt  $MERIT/forms/tiles/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  

pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx $res -dy $res -f mode  -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/geom_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata   0  $MERIT/$TOPO/$MATH/geom_${KM}KM${MATH}_MERIT.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   

fi 


if [ $MATH = "percent"   ] ; then 

# count for forms  

for class in $(seq 1 10) ;  do

export class 

if [ $class -eq 1   ] ; then export  geom=flat      ; fi 
if [ $class -eq 2   ] ; then export  geom=peak      ; fi 
if [ $class -eq 3   ] ; then export  geom=ridge     ; fi 
if [ $class -eq 4   ] ; then export  geom=shoulder  ; fi 
if [ $class -eq 5   ] ; then export  geom=spur      ; fi 
if [ $class -eq 6   ] ; then export  geom=slope     ; fi 
if [ $class -eq 7   ] ; then export  geom=hollow    ; fi 
if [ $class -eq 8   ] ; then export  geom=footslope ; fi 
if [ $class -eq 9   ] ; then export  geom=valley    ; fi 
if [ $class -eq 10  ] ; then export  geom=pit       ; fi 


ls -rt  $MERIT/forms/tiles/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -m $file  -msknodata 0  -nodata 255  -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/msk_$filename.tif
pkfilter -nodata 255  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32  -of GTiff  -dx $res -dy $res   -f density -class $class   -d $res -i $SCRATCH/$TOPO/$MATH/tiles_km$KM/msk_$filename.tif  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

rm  $SCRATCH/$TOPO/$MATH/tiles_km$KM/msk_$filename.tif 
oft-calc -ot UInt16  $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif $SCRATCH/$TOPO/$MATH/tiles_km$KM/tmp_$filename.tif   <<EOF
1
#1 100 * 
EOF
rm  $SCRATCH/$TOPO/$MATH/tiles_km$KM/class${class}_$filename.tif 
gdal_translate -co COMPRESS=DEFLATE    -co ZLEVEL=9  -co INTERLEAVE=BAND   -ot UInt16   $SCRATCH/$TOPO/$MATH/tiles_km$KM/tmp_$filename.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM/class${class}_$filename.tif
rm $SCRATCH/$TOPO/$MATH/tiles_km$KM/tmp_$filename.tif
' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt -srcnodata 25500 -vrtnodata 65535 -te $(getCorners4Gwarp $MERIT/input_tif/all_tif.vrt )  -overwrite  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/class${class}_*.tif
gdal_translate -a_nodata 65535   -ot UInt16   -co COMPRESS=DEFLATE -co ZLEVEL=9   $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $MERIT/$TOPO/$MATH/geom${geom}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata 65535    $MERIT/$TOPO/$MATH/geom${geom}_${KM}KM${MATH}_MERIT.tif 
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/class${class}_*.tif

done 

fi 




