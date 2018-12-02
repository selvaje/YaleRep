#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc03_cost_1k.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_cost_1k.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_cost_1k.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

#  sbatch   --mem-per-cpu=50000  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc03_cost_1k.sh

export DIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_watershad

rm -rf /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/cost1k
gdal_edit.py -a_nodata 0  $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core.tif 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/ cost1k  $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core.tif

# source /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh   $DIR/grassdb/cost/PERMANENT 

g.rename   raster=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core,core
g.region   rast=core 
r.in.gdal  in=$DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif   output=impervius    --overwrite   memory=2047 
gdal_edit.py -a_nodata  3767 $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif
r.in.gdal  in=$DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif   output=clump_UNIT    --overwrite   memory=2047 

# r.mask   raster=clump_UNIT  --o non piu maskata 

r.mapcalc " impervius_neg =  ( 1 - impervius )   "  --overwrite

echo start to calculate the cost 
r.cost  -k input=impervius_neg output=impervius_cost start_raster=core  --overwrite  memory=48000  null_cost=-1
r.colors  -r map=impervius_cost

r.out.gdal --overwrite nodata=-1 -c -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff  input=impervius_cost  output=$DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_cost.tif

# rm -rf  /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/cost1k

sbatch  --mem-per-cpu=50000  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc04_watershed_1k.sh 




