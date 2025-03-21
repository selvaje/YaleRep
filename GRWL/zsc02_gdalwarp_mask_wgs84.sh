#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/sbsc/ga254/stdout/sc02_gdalwarp_mask_wgs84.sh.%A.%a.out  
#SBATCH -e /gpfs/scratch60/sbsc/ga254/stderr/sc02_gdalwarp_mask_wgs84.sh.%A.%a.err
#SBATCH --job-name=sc02_gdalwarp_mask_wgs84.sh
#SBATCH --array=2-649

# start from 2 , 1 is the header 
# data from https://zenodo.org/record/1297434#.W4_713XBjNP

# create the vrt one for each zone north and south 

# cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01   ; 
#  for file in *.tif ; do  echo $file  $(gdalinfo $file | grep PROJCRS |  awk '{ gsub(/[[",]/," " , $0 ); print $2 }' ) ; done  > filename_zone.txt

# awk '{print $2}'  filename_zone.txt  | sort  | uniq  | xargs -n 1 -P 4 bash -c $' 
# gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite all_${1}_tif.vrt $(grep $1 filename_zone.txt | awk \'{print $1}\' )  
# ' _

# cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01   ; 
# for ZONE  in all_*_tif.vrt  ; do sbatch --export=ZONE=$ZONE  /project/fas/sbsc/hydro/scripts/GRWL/sc02_gdalwarp_mask_wgs84.sh  ; done 

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

ZONENAME1=$(basename  $ZONE _tif.vrt )
ZONENAME=${ZONENAME1:4:20}
NS=${ZONENAME: -1} 

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01 
OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL/GRWL_mask_V01.01_wgs84

echo tile $tile for $ZONENAME check if process or not

# process the north zone 
if [ $NS = "N" ] &&  [ $ymin -gt -1 ] ; then 

gdalwarp -ot Byte -wm 2000  -srcnodata 0 -dstnodata 0 -te  $xmin $ymin $xmax $ymax -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326 -tr 0.0002777777777777 0.0002777777777777  -r near  $INDIR/$ZONE   $OUTDIR/${tile}_$ZONENAME.tif 

MAX=$(pkstat -max -i   $OUTDIR/${tile}_$ZONENAME.tif   | awk '{ print $2 }')
if [ $MAX -eq  0 ] ; then 
rm -f    $OUTDIR/${tile}_$ZONENAME.tif 
fi
else
echo tile $tile for $ZONENAME not processed
fi 

# process the south  zone 

if [ $NS = "S" ] &&  [ $ymin -lt -1 ] ; then 

gdalwarp -ot Byte -wm 2000  -srcnodata 0 -dstnodata 0 -te  $xmin $ymin $xmax $ymax -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs EPSG:4326 -tr 0.00027777777777 0.00027777777777  -r near  $INDIR/$ZONE   $OUTDIR/${tile}_$ZONENAME.tif 

MAX=$(pkstat -max -i   $OUTDIR/${tile}_$ZONENAME.tif   | awk '{ print $2 }')
if [ $MAX -eq   0 ] ; then 
rm -f    $OUTDIR/${tile}_$ZONENAME.tif 
fi
else
echo tile $tile for $ZONENAME not processed
fi 


