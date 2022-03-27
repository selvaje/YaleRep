#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc22_broken_basin_clumping.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc22_broken_basin_clumping.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc22_broken_basin_clumping.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc22_broken_basin_clumping.sh
# sbatch -d afterany:$(qmys | grep sc21_broken_basin_manip.sh  | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc22_broken_basin_clumping.sh
module load Apps/GRASS/7.3-beta

MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm


gdalbuildvrt -overwrite    /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/all_tif.vrt    /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/lbasin_h??v??.tif  

gdalbuildvrt -overwrite  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk/all_tif.vrt  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk/lbasin_h??v??.tif 
geo_string=$(oft-bb  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk/all_tif.vrt  1 |  grep "Band 1"  |  awk '{ print $6 , $7 , $8-$6+1 , $9-$7+1  }'  )
gdal_translate -srcwin $geo_string   -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9  $MERIT/lbasin_tiles_brokb_msk/all_tif.vrt  $MERIT/lbasin_tiles_brokb_msk/all_tif.tif 

rm  -f     /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/all_tif_shp.*
gdaltindex     /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/all_tif_shp.shp     /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/lbasin_h??v??.tif  

gdal_translate  -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9  $MERIT/lbasin_tiles_brokb_msk1km/all_tif.vrt  $MERIT/lbasin_tiles_brokb_msk1km/all_tif.tif 

 # clumping 1km 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh /tmp/  loc_$tile  $MERIT/lbasin_tiles_brokb_msk1km/all_tif.tif  r.in.gdal 

r.clump -d  --overwrite    input=all_tif     output=brokb_msk1km_clump 
r.colors -r map=brokb_msk1km_clump 
r.out.gdal -c -m nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=brokb_msk1km_clump   output=$MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump.tif 
rm -fr  /tmp/loc_$tile 


pkstat -hist -i  $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump.tif | sort -k 1,1 -g  > $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist0.txt  
awk '{ if (NR>1) print  }'  $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist0.txt  > $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist1.txt

sort -k 2,2 -g  $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist1.txt > $MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist1_s.txt

# clumping 90m 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh /tmp/  loc_$tile  $MERIT/lbasin_tiles_brokb_msk/all_tif.tif   r.in.gdal 

r.clump -d  --overwrite    input=all_tif     output=brokb_msk_clump 
r.colors -r map=brokb_msk_clump 
r.out.gdal -c -m nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=brokb_msk_clump   output=$MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump.tif 
rm -fr  /tmp/loc_$tile 

pkstat -hist -i  $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump.tif | sort -k 1,1 -g  > $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump_hist0.txt  
awk '{ if (NR>1) print  }'  $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump_hist0.txt  > $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1.txt

# -r in this way the larg pol start first
sort -k 2,2 -rg  $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1.txt > $MERIT/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1_s.txt

# start the next scritp 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc23_build_dem_location_broken_basin.sh 


