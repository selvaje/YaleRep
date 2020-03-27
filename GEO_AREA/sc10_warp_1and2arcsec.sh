#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_warp_1and2arcsec.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_warp_1and2arcsec.sh.%A.%a.err
#SBATCH --job-name=sc10_warp_1and2arcsec.sh
#SBATCH --array=2-649

# start from 2 , 1 is the header 
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GEO_AREA/sc10_warp_1and2arcsec.sh

source ~/bin/gdal
source ~/bin/pktools 


geo_string=$(  head  -n  $SLURM_ARRAY_TASK_ID   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_10d.txt   | tail  -1 ) 
tile=$( echo $geo_string | awk '{  print $1 }' ) 
xmin=$( echo $geo_string | awk '{  print $4 }' ) 
ymin=$( echo $geo_string | awk '{  print $7 }' ) 
xmax=$( echo $geo_string | awk '{  print $6 }' ) 
ymax=$( echo $geo_string | awk '{  print $5 }' ) 

DIR=/project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif


echo tile $tile to be processed 

# gdalwarp -wm 2000 -srcnodata 0 -dstnodata 0 -te $xmin $ymin $xmax $ymax -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326 -tr 0.00027777777777777  0.00027777777777777 -r cubic  $DIR/30arc-sec-Area_prj6965.tif  $DIR/1arc-sec-Area_prj6965/$tile.tif 

gdalwarp -wm 4000  -overwrite   -srcnodata 0 -dstnodata 0 -te $xmin $ymin $xmax $ymax -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326 -tr 0.000833333333333333 0.000833333333333333 -r cubic  $DIR/75arc-sec-Area_prj6965.tif  $DIR/3arc-sec-Area_prj6965/$tile.tif 



###  to obtain the area value at 1 3-arcsec pixel   2.5 * 2.5 = 6.25      area / 6.25 * 100 = area *  16 
oft-calc  $DIR/3arc-sec-Area_prj6965/$tile.tif    $DIR/3arc-sec-Area_prj6965/${tile}_tmp.tif <<EOF
1
#1 16 *
EOF

#  $DIR/30arc-sec-Area_prj6965.tif  max value 854796 = 0.854796 km2 
#  $DIR/75arc-sec-Area_prj6965.tif  max value 53424 =  0.053424 km2
#  3arc-sec-Area_prj6965 maxvalue 53424.000  / 6.25    =  max  8547.84 = 0.00854784 km2


gdal_translate --config GDAL_CACHEMAX 4000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $DIR/3arc-sec-Area_prj6965/${tile}_tmp.tif   $DIR/3arc-sec-Area_prj6965/$tile.tif 

rm  $DIR/3arc-sec-Area_prj6965/${tile}_tmp.tif






