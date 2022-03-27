#!/bin/bash
#SBATCH -p day
#SBATCH -n 4 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc07_build_dem_location_GLOBE_imp_stdev.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc07_build_dem_location_GLOBE_imp_stdev.sh.%J.err
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

# sbatch  -J sc07_build_dem_location_GLOBE_imp_stdev.sh  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc04_build_dem_location_GLOBE_imp_stdev.sh

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT 
rm -f   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock

# echo  11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161 | xargs -n 1 -P 4 bash -c $'  
echo  171 | xargs -n 1 -P 4 bash -c $'  
RADIUS=$1
r.in.gdal in=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_stdev/stdev${RADIUS}/be75_grd_LandEnlarge_stdev${RADIUS}.tif  out=be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk   --overwrite

r.mapcalc "be75_grd_LandEnlarge_std${RADIUS}_norm_GLOBE_pk = be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk / $( r.info be75_grd_LandEnlarge_std${RADIUS}_GLOBE_pk  | grep max | awk \'{  print $10".0"  }\' ) "    --overwrite

' _






