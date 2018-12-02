#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000

# for TOPO in altitude ; do  for MATH in min max mean median stdev ; do for  KM in 0.2 0.3  ; do  sbatch  -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err -J sc04_variables_merge_resKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_dem_variables_float_noMult_res2x2.sh ; done   ; done ; done   

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT

export res=${KM:2}
export TOPO
export MATH 
export KM



ls -rt  $MERIT/input_tif/*.tif   | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif

' _ 

echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp    /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif
rm -f  $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif  $SCRATCH/$TOPO/$MATH/tiles_km$KM.vrt   



