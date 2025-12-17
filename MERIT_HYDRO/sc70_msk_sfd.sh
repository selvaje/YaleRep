#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc70_msk_sfd.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc70_msk_sfd.sh.%J.err
#SBATCH --mem=200G

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc70_msk_sfd.sh

ulimit -c 0

source ~/bin/gdal3     2>/dev/null
source ~/bin/pktools   2>/dev/null

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

ls $MERIT/msk_sfd/*1.gpkg | xargs -n 1 -P 4 bash -c $' 
file=$1
filename=$(basename $file .gpkg) 
xmin=$(ogrinfo -al -so  $file | grep "Extent:" | awk \'{ gsub ("[(),]"," ") ; printf ("%.1f" , $2)  }\' )
ymax=$(ogrinfo -al -so  $file | grep "Extent:" | awk \'{ gsub ("[(),]"," ") ; printf ("%.1f" , $6)  }\' ) 
xmax=$(ogrinfo -al -so  $file | grep "Extent:" | awk \'{ gsub ("[(),]"," ") ; printf ("%.1f" , $5)  }\' ) 
ymin=$(ogrinfo -al -so  $file | grep "Extent:" | awk \'{ gsub ("[(),]"," ") ; printf ("%.1f" , $3)  }\' ) 

GDAL_CACHEMAX=20000
gdal_rasterize -burn 1 -tr 0.0008333333333333333 0.0008333333333333333  -ot Byte -te $xmin $ymin $xmax $ymax -co COMPRESS=DEFLATE -co ZLEVEL=9 $file $MERIT/msk_sfd/${filename}_box.tif 

pksetmask -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk/all_tif_dis.vrt -msknodata 0 -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte   -i $MERIT/msk_sfd/${filename}_box.tif   -o $MERIT/msk_sfd/${filename}_msk.tif

' _

### integrate these line in the xargs to create 
# run the first time for one var and for all the box        
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v
.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif $MERITH/flow_sfd/flow_sfd_$box.tif &      
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERIT/are/all_tif_dis.v
rt $MERIT/are/${box}_are.tif &              
# gdal_translate -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITH/hydrography90m_v
.1.0/r.watershed/direction_tiles20d/direction.tif $MERITH/dir_sfd/dir_sfd_$box.tif &   
