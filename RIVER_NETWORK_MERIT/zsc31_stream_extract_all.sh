#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_stream_extract_all.sh.%J.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_stream_extract_all.sh.%J.out  
#SBATCH --mem-per-cpu=402000
#SBATCH --array=1-1
#SBATCH --nodelist=bigmem04

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc31_stream_extract_all.sh

## file number 1150 
# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)


export GRASS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb

echo start to copy 
cp -r  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/grassdb/loc_MERIT_ALL  /tmp
echo end copy 

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /tmp/loc_MERIT_ALL/PERMANENT

r.mask raster=msk --o
g.region n=80  s=60 e=80  w=100 

r.stream.extract  elevation=elv  accumulation=upa  threshold=5  depression=dep direction=dir stream_raster=stream memory=400000 --o --verbose 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir   basins=lbasin   memory=400000 --o --verbose 

r.colors -r stream ; r.colors -r lbasin 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_bigmem.tif  
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles/stream_bigmem.tif 

rm -r /tmp/loc_MERIT_ALL  



