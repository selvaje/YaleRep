#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH --array=1-1150
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000

# for TOPO in altitude ; do  for MATH in min ; do for  KM in 0.2 0.3 0.4 0.5 ; do  sbatch --dependency=afterok:$(qmys | grep sc01_wget_merit_river.sh  | awk '{  print $1 }'  | uniq )   -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err -J sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc04_elvCorrect_MultiRes.sh  ; done   ; done ; done   

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


file=$(ls  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/*_elv.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )
filename=$(basename $file .tif )  
pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -dx $res -dy $res -f $MATH -d $res -i $file  -o $SCRATCH/$TOPO/$MATH/tiles_km$KM/$filename.tif







