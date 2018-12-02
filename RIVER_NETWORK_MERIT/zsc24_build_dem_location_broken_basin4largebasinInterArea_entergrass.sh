#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 168:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc24_build_dem_location_broken_basin4largebasinInterArea_entergrass.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc24_build_dem_location_broken_basin4largebasinInterArea_entergrass.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc24_build_dem_location_broken_basin4largebasinInterArea_entergrass_entergrass.sh 
#SBATCH --array=132-132
#SBATCH --mem-per-cpu=100000

# 132 broken basin ; 131 and 132 sent on the big ram  
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc24_build_dem_location_broken_basin4largebasinInterArea_entergrass.sh

module load Apps/GRASS/7.3-beta

MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb 
RAM=$GRASS/tif 

find  /tmp/     -user $USER    2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER    2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# SLURM_ARRAY_TASK_ID=60
UNIT=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1 }' /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist1_s.txt ) 

geo_string=$(oft-bb /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump.tif $UNIT | grep BB | awk '{ print $6,$7,$8,$9 }'  ) 

echo $geo_string for UNIT $UNIT

### take the coridinates from the orginal files and increment of 10 pixel 

export ulxL=$( echo $geo_string | awk  '{ printf ("%.16f" , -180 + (($1 - 10) * 0.00833333333333)) }')
export ulyL=$( echo $geo_string | awk  '{ printf ("%.16f" ,   85 - (($2 - 10) * 0.00833333333333)) }')
export lrxL=$( echo $geo_string | awk  '{ printf ("%.16f" , -180 + (($3 + 10) * 0.00833333333333)) }')
export lryL=$( echo $geo_string | awk  '{ printf ("%.16f" ,   85 - (($4 + 10) * 0.00833333333333)) }')

echo  $ulxL $ulyL $lrxL  $lryL 


source /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.3-grace2.sh    $GRASS/loc_$UNIT/PERMANENT

r.mask raster=msk  --o 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir  basins=lbasin        memory=25000 --o --verbose  ;  r.colors -r lbasin

echo "second ############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit
echo "############################################################"

r.mask raster=msk_brokb  --o

r.out.gdal --overwrite -c -m   createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_unit_large/lbasin_brokb$UNIT.tif
r.out.gdal --overwrite -c -m   createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_unit_large/stream_brokb$UNIT.tif

# rm -r /tmp/loc_$UNIT

echo "third ############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

exit 

