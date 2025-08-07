#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 8:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc15_IDraster.sh.%A_%a.out  
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc15_IDraster.sh.%A_%a.err
#SBATCH --job-name=sc15_IDraster.sh
#SBATCH --mem=30G
#SBATCH --array=1-116

###  --array=1-116
### testing 58    h18v02
### testing 19    h06v02  points 3702   x_y_ID_h06v02.txt 
#######1-116
####   sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc15_IDraster.sh

ulimit -c 0

source ~/bin/gdal3    2> /dev/null
source ~/bin/pktools  2> /dev/null

export SC=/vast/palmer/scratch/sbsc/hydro/dataproces/GSI_TS
export IN=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS
export QNT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/quantiles
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export RAM=/dev/shm
export MH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export INP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/snapFlow_area

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## SLURM_ARRAY_TASK_ID=112  ##### array  112    ID 96  small area for testing 

export file=$(ls $MH/CompUnit_stream_uniq_tiles20d/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )      ## select the tile file 
export filename=$(basename $file .tif  )
export TILE=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

~/bin/echoerr $file 
echo          $file 
########################         
# select all the points that fall inside the tile
paste -d " "  $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist.txt    <( gdallocationinfo -geoloc -valonly $file  <  <(awk '{print $7, $8 }' $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist.txt  ) ) | awk '{if (NF==11) print }'  > $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt

if [ -s  $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt  ] ; then 

awk '{ print $7, $8 }'       $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt  > $RAM/xsnap_ysnap_$TILE.txt
awk '{ print $7, $8 , $1 }'  $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt  > $RAM/xsnap_ysnap_IDs_$TILE.txt
awk '{ print $1, $7, $8  }'  $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt  > $RAM/IDs_xsnap_ysnap_$TILE.txt
awk '{ print $4, $5 , $1 }'  $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt  > $RAM/x_y_IDs_$TILE.txt

cp $RAM/xsnap_ysnap_IDs_$TILE.txt  $IN/snapFlow_txt/xsnap_ysnap_IDs_$TILE.txt
cp $RAM/xsnap_ysnap_$TILE.txt      $IN/snapFlow_txt/xsnap_ysnap_$TILE.txt
cp $RAM/IDs_xsnap_ysnap_$TILE.txt  $IN/snapFlow_txt/IDs_xsnap_ysnap_$TILE.txt

pkascii2ogr -f "GPKG" -n "GSI_TM_no" -ot "Integer" -i $RAM/xsnap_ysnap_IDs_$TILE.txt -o $IN/snapFlow_gpkg/x_y_snap_IDs_$TILE.gpkg # crate a GPKG
pkascii2ogr -f "GPKG" -n "GSI_TM_no" -ot "Integer" -i $RAM/x_y_IDs_$TILE.txt         -o $IN/snapFlow_gpkg/x_y_orig_IDs_$TILE.gpkg # crate a GPKG

export GDAL_CACHEMAX=15000 

### calculate raster ID.
xsize=$(gdalinfo $MH/CompUnit_stream_uniq_tiles20d/stream_$TILE.tif | grep "Size is" | awk '{ print int($3)}' )
ysize=$(gdalinfo $MH/CompUnit_stream_uniq_tiles20d/stream_$TILE.tif | grep "Size is" | awk '{ print int($4)}' )
xll=$(getCorners4Gtranslate $MH/CompUnit_stream_uniq_tiles20d/stream_$TILE.tif | awk '{ print $1}')
yll=$(getCorners4Gtranslate $MH/CompUnit_stream_uniq_tiles20d/stream_$TILE.tif | awk '{ print $4}') 

echo "ncols        $xsize"                  >  $SC/rasterID/rasterID_$TILE.asc 
echo "nrows        $ysize"                  >> $SC/rasterID/rasterID_$TILE.asc 
echo "xllcorner    $xll"                    >> $SC/rasterID/rasterID_$TILE.asc 
echo "yllcorner    $yll"                    >> $SC/rasterID/rasterID_$TILE.asc 
echo "cellsize     0.000833333333333"       >> $SC/rasterID/rasterID_$TILE.asc

awk -v xsize=$xsize -v ysize=$ysize  ' BEGIN {  
 for (row=1 ; row<=ysize ; row++)  { 
      for (col=1 ; col<=xsize ; col++) { 
          printf ("%i " ,  col+(row-1)*xsize  ) } ; printf ("\n")  }}'  >> $SC/rasterID/rasterID_$TILE.asc
gdal_translate -a_srs epsg:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 $SC/rasterID/rasterID_$TILE.asc    $SC/rasterID/rasterID_$TILE.tif 
rm -f $SC/rasterID/rasterID_$TILE.asc 

paste -d " " $RAM/IDs_xsnap_ysnap_$TILE.txt   \
      <(gdallocationinfo -valonly -geoloc  $MH/CompUnit_stream_uniq_tiles20d/stream_$TILE.tif < $RAM/xsnap_ysnap_$TILE.txt) \
      <(gdallocationinfo -valonly -geoloc  $SC/rasterID/rasterID_$TILE.tif                    < $RAM/xsnap_ysnap_$TILE.txt) \
      > $IN/snapFlow_txt/IDs_xsnap_ysnap_IDseg_IDr_$TILE.txt 

pkascii2ogr -x 1 -y 2   -f "GPKG" -n "IDstation"  -ot "Integer"  -n "IDstream" -ot "Integer" -n "IDraster" -ot "Integer" -i $IN/snapFlow_txt/x_y_snapFlowYesSnap_$TILE.txt -o $IN/snapFlow_gpkg/IDs_xsnap_ysnap_IDseg_IDr_$TILE.gpkg

rm -f $RAM/*${TILE}*.tif   $RAM/*${TILE}*.txt

else 

rm   $INP/IDs_x_y_areaDB_xsnap_ysnap_areaSFD_dist_$TILE.txt 
fi 

