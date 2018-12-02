#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_stripre_delineation.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_stripre_delineation.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc21_stripre_delineation.sh

MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

awk '{ if ($3==85) print $1  }'  /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt > /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/txt/orizontal_tiles.txt 
awk '{ if ($2==-180) print $1  }'  /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt > /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/txt/vertical_tiles.txt 


# orizontal stripe 
for tiles in $( cat $MERIT/txt/orizontal_tiles.txt ) ; do gdal_translate  -srcwin 0 0 $(pkinfo -ns -i $file | awk '{  print $2 }') 1  $MERIT/lbasin_tiles_1pixel/lbasin_$tile.tif   $MERIT/lbasin_tiles_stripe/stripe_oriz_$tile.tif ;  done 

# vertical  stripe 

for tiles in $( cat $MERIT/txt/vertical_tiles.txt ) ; do gdal_translate  -srcwin 0 0 1 $(pkinfo -nl  -i $file | awk '{  print $2 }')   $MERIT/lbasin_tiles_1pixel/lbasin_$tile.tif   $MERIT/lbasin_tiles_stripe/stripe_vert_$tile.tif ;  done 



pkcomposite   -file 1  -cr sum  $( ls  $MERIT/lbasin_tiles_stripe/stripe_oriz_*.tif  |  xargs -n 1 echo -i $1 ) -o $MERIT/lbasin_tiles_stripe/stripe_oriz.tif 
pkcomposite   -file 1  -cr sum  $( ls  $MERIT/lbasin_tiles_stripe/stripe_vert_*.tif  |  xargs -n 1 echo -i $1 ) -o $MERIT/lbasin_tiles_stripe/stripe_vert.tif 



awk '{ if ($4==-140) print   }'  /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt
awk '{ if ($4==-140) print   }'  /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt

