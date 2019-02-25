#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 7  -N 1  
#SBATCH -t 10:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_equi_categorical_1_100KM.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_equi_categorical_1_100KM.sh.%J.err

# for TOPO in forms  ; do for MATH in mode countid  ; do for KM in 1 5 10; do sbatch --export=TOPO=$TOPO,KM=$KM,MATH=$MATH /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_categorical_1_100KM.sh ; done ; done ; done 

# sbatch  --export=TOPO=altitude,MATH=median,KM=5  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc09_equi_categorical_1_100KM.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_BK
export EQUI=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm

export TOPO
export KM
export MATH
export RES=$(echo 10 \* $KM | bc -l )

# not compleate  leave it interropted

if [ $TOPO = "forms" ]  ; then 

echo  AF AN AS EU NA OC SA | xargs -n 1 -P 7  bash -c $'
CT=$1
# for these resolutions we keep the te equal to the full globe

pkfilter  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -f mode -ot Byte  -nodata 0  -dx $RES -dy $RES  -f countid  -d $RES  -i $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}.tif -o $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $EQUI/$CT/GEOG/EQUI7_V13_${CT}_GEOG_ZONE_KM$KM.tif  -msknodata 0 -nodata -9999 -i $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif -o  $SCRATCH/$TOPO/$MATH/${CT}_tiles_km${KM}_wgs84.tif 

rm $RAM/${TOPO}_${MATH}_${CT}_tiles_km${KM}.tif

' _

echo start pkstatprofile 
gdalbuildvrt  -overwrite  -separate  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt   $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_wgs84.tif
pkstatprofile -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -nodata -9999 -f mean  -i  $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt -o  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif  $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7.tif  

rm   $MERIT/$TOPO/$MATH/${TOPO}_${KM}KM${MATH}_MERIT_E7_tmp.tif   $SCRATCH/$TOPO/$MATH/GLOBE_tiles_km${KM}_wgs84.vrt  $SCRATCH/$TOPO/$MATH/??_tiles_km${KM}_wgs84.tif

fi


