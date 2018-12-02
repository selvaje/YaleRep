#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_stream_extract.sh%J.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_stream_extract.sh%J.out
#SBATCH --mem-per-cpu=5000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_stream_extract.sh


GRASS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb
DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  $GRASS/loc_MERIT_ALL/PERMANENT


# g.region  w=-118 n=38 e=-114 s=34 
g.region  w=-124 n=42 e=-112 s=30

# 247 is already no data 0 become also no data

# Flow direction is prepared in 1-byte SIGNED integer (int8). The flow direction is represented as follows.
# 1: east, 2: southeast, 4: south, 8: southwest, 16: west, 32: northwest, 64: north. 128: northeast
# 0: river mouth, -1: inland depression, -9: undefined (ocean)
# NOTE: If a flow direction file is opened as UNSIGNED integer, undefined=247 and inland depression=255


# r.recode input=dir output=direc  rules=- << EOF
# 1:1:8:8 
# 2:2:7:7 
# 4:4:6:6 
# 8:8:5:5 
# 16:16:4:4
# 32:32:3:3
# 64:64:2:2
# 128:128:1:1
# 255:255:0:0
# EOF

r.stream.extract elevation=elv  accumulation=upa threshold=5 depression=dep memory=4000  direction=dir_grass  stream_raster=stream12   --o --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream12 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/stream12.tif 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream12  direction=dir_grass   basins=lbasin_grass_12 memory=4000 --o  --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=0  input=lbasin_grass_12  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/lbasin_grass_12.tif 

exit 



r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999        input=dir_grass    output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dir_grass_12.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999        input=dir          output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dir_merit_12.tif 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream12  direction=direc        basins=lbasin_merit_12 memory=4000 --o  --verbose 



r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=0  input=lbasin_merit_12  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/lbasin_merit_12.tif 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=dep output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dep12.tif 

exit







g.region  w=-120 n=40 e=-116 s=32 

r.stream.extract elevation=elv  accumulation=upa threshold=5 depression=dep memory=4000 direction=dir1  stream_raster=stream1   --o  --verbose
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=stream1 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/stream1.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999      input=dir1 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dir1.tif 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins   stream_rast=stream  direction=dir1  basins=lbasin1 memory=4000 --o  --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=0      input=lbasin1 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/lbasin1.tif 

g.region  w=-118 n=40 e=-114 s=32 

r.stream.extract elevation=elv  accumulation=upa threshold=5 depression=dep memory=4000 direction=dir2  stream_raster=stream2   --o --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=stream2 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/stream2.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999      input=dir2 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dir2.tif 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir2  basins=lbasin2 memory=4000 --o --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=0      input=lbasin2 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/lbasin2.tif 

g.region  w=-120 n=40 e=-114 s=32 
r.stream.extract elevation=elv  accumulation=upa threshold=5 depression=dep memory=4000 direction=dir12  stream_raster=stream12   --o --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0        input=stream12 output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/stream12.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=-9999        input=dir12    output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dir12.tif 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir12    basins=lbasin12 memory=4000 --o  --verbose 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32  format=GTiff nodata=0      input=lbasin12  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/lbasin12.tif 


r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=dep output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/tmp/dep12.tif 



echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

