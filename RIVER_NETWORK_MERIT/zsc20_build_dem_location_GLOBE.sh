#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_GLOBE.sh%J.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_GLOBE.sh%J.out
#SBATCH --mem-per-cpu=5000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc20_build_dem_location_GLOBE.sh 


GRASS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb
DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

####  comment rm for securit   

### rm -rf $GRASS/loc_MERIT_ALL
### source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh $GRASS loc_MERIT_ALL $DIRP/elv/all_tif.vrt 

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  $GRASS/loc_MERIT_ALL/PERMANENT

g.rename raster=all_tif.vrt,elv

r.in.gdal in=$DIRP/msk/all_tif.vrt    out=msk    memory=2000 --o 
r.in.gdal in=$DIRP/dep/all_tif.vrt    out=dep    memory=2000 --o 
r.in.gdal in=$DIRP/upa/all_tif.vrt    out=upa    memory=2000 --o  

r.mask raster=msk --o 


sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_stream_extract_tiles.sh


echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

