#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/sbsc/ga254/stdout/sc02_gdalwarp_wgs84_vrt.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/sbsc/ga254/stderr/sc02_gdalwarp_wgs84_vrt.sh.%A.%a.err
#SBATCH --job-name=sc02_gdalwarp_wgs84_vrt.sh
#SBATCH --array=2-649
#SBATCH --mem=20G

# start from 2 , 1 is the header 
# data from https://zenodo.org/record/1297434#.W4_713XBjNP

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc02_gdalwarp_wgs84_vrt.sh  

# cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01   ; 
#  for file in *.tif ; do  echo $file  $(gdalinfo $file | grep PROJCRS |  awk '{ gsub(/[[",]/," " , $0 ); print $2 }' ) ; done  > filename_zone.txt

# warping vrt to vrt and create global vrt 
# export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
# cd $DIR/GRWL_mask_V01.01

# awk '{print $2}' $DIR/GRWL_mask_V01.01/filename_zone.txt  | sort  | uniq  | xargs -n 1 -P 4 bash -c $' 
# gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite $DIR/GRWL_mask_V01.01_wgs84_vrt/all_${1}_tif.vrt $(for file in $(grep $1 $DIR/GRWL_mask_V01.01/filename_zone.txt | awk \'{print $1}\') ; do echo $DIR/GRWL_mask_V01.01/$file ; done  )
# gdalwarp -overwrite -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcnodata 0 -dstnodata 0  -t_srs EPSG:4326 -tr 0.000277777777777777777777 0.000277777777777777777777 -r near -of VRT $DIR/GRWL_mask_V01.01_wgs84_vrt/all_${1}_tif.vrt $DIR/GRWL_mask_V01.01_wgs84_vrt/all_${1}_tif_wgs84.vrt
# ' _
# gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite $DIR/GRWL_mask_V01.01_wgs84_vrt/all_tif_wgs84_global.vrt $DIR/GRWL_mask_V01.01_wgs84_vrt/all_*_tif_wgs84.vrt

# Pixel classifications: 
# DN = 256 : No Data  : Only lable no pixel 
# DN = 255 : River
# DN = 180 : Lake/reservoir 
# DN = 126 : Tidal rivers/delta 
# DN = 86  : Canal
# DN = 0   : Land/water not connected to the GRWL river network

source ~/bin/gdal3  
source ~/bin/pktools 

geo_string=$(  head  -n  $SLURM_ARRAY_TASK_ID   /gpfs/gibbs/pi/hydro/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_10d.txt   | tail  -1 ) 
tile=$( echo $geo_string | awk '{  print $1 }' ) 
xmin=$( echo $geo_string | awk '{  print $4 }' ) 
ymin=$( echo $geo_string | awk '{  print $7 }' ) 
xmax=$( echo $geo_string | awk '{  print $6 }' ) 
ymax=$( echo $geo_string | awk '{  print $5 }' ) 

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01_wgs84_vrt
OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01_wgs84_tif

gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $xmin $ymax $xmax $ymin $INDIR/all_tif_wgs84_global.vrt  $OUTDIR/${tile}.tif 

gdal_edit.py -a_ullr  $xmin $ymax $xmax $ymin  $OUTDIR/${tile}.tif 
gdal_edit.py -tr 0.000277777777777777777777 -0.000277777777777777777777  $OUTDIR/${tile}.tif 
gdal_edit.py -a_ullr  $xmin $ymax $xmax $ymin  $OUTDIR/${tile}.tif 
gdal_edit.py -tr 0.000277777777777777777777 -0.000277777777777777777777   $OUTDIR/${tile}.tif 


MAX=$(pkstat -max -i  $OUTDIR/${tile}.tif   | awk '{ print $2 }')
if [ $MAX -eq  0 ] ; then 
rm -f $OUTDIR/${tile}.tif 
else
echo tile $OUTDIR/${tile}.tif  processed
fi 

exit 


