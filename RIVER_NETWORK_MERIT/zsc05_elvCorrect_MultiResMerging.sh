#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000

# for TOPO in altitude ; do  for MATH in min ; do for  KM in 0.2 0.3 0.4 0.5 ; do  sbatch  --dependency=afterok$( qmys | grep sc04_elvCorrect_MultiRes  | awk '{  printf (":%i" ,  $1 ) }'  | uniq  )   -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err -J sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc05_elvCorrect_MultiResMerging.sh  ; done   ; done ; done   

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

export res=${KM:2}
export TOPO
export MATH 
export KM


echo starting the merging  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif  

gdalbuildvrt  -te  $(getCorners4Gwarp   $MERIT/elv/all_tif.vrt )    -overwrite       $SCRATCH/$TOPO/$MATH/tiles_km$KM/all_tif.vrt   $SCRATCH/$TOPO/$MATH/tiles_km$KM/*.tif
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES $SCRATCH/$TOPO/$MATH/tiles_km$KM/all_tif.vrt $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif 
gdal_edit.py -a_nodata -9999  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT.tif

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

