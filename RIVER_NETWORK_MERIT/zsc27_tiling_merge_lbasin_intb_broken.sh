#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 9 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc27_tiling_merge_lbasin_intb_broken.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc27_tiling_merge_lbasin_intb_broken.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc27_tiling_merge_lbasin_intb_broken.sh
#SBATCH --array=12,18,22
#SBATCH --mem-per-cpu=6000

# 1-24 
####    sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc27_tiling_merge_lbasin_intb_broken.sh

# check for errors 
# grep "Bus error"  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc27_tiling_merge_lbasin_intb_broken.sh.*

export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm
# export RAMT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/tmp
export RAMT=/dev/shm

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# SLURM_ARRAY_TASK_ID=7

export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )

echo $ulx $uly $lrx $lry

if [ $(echo " $ulx < -180 "  | bc ) -eq 1 ] ; then ulx=-180 ; fi  ; if [ $ulx -lt  -180 ] ; then ulx=-180 ; fi  
if [ $(echo " $uly >  85 "   | bc ) -eq 1 ] ; then uly=85   ; fi  ; if [ $uly -gt   85  ] ; then uly=85   ; fi 
if [ $(echo " $lrx >  180"   | bc ) -eq 1 ] ; then lrx=180  ; fi  ; if [ $lrx -gt   180 ] ; then lrx=180  ; fi  
if [ $(echo " $lry <  -60"   | bc ) -eq 1 ] ; then lry=-60  ; fi  ; if [ $lry -lt  -60  ] ; then lry=-60  ; fi  

echo $ulx $uly $lrx $lry   

echo lbasin stream dir  | xargs -n 1 -P 3 bash -c $'  
VAR=$1
echo create tile   $MERIT/${VAR}_unit_tile/${VAR}_${tile}.tif 

# crop only unit in the tie. 

if [ $VAR = "lbasin" ] ; then  UNITDIR=${VAR}_unit_large_reclass ; TILEDIR=${VAR}_tiles_intb_reclass ;  export TYPE=UInt32  ; export NODATA=0 ;  fi 
if [ $VAR = "stream" ] ; then  UNITDIR=${VAR}_unit_large_reclass ; TILEDIR=${VAR}_tiles_intb_reclass ;  export TYPE=UInt32  ; export NODATA=0   ;  fi 
if [ $VAR = "dir" ]    ; then  UNITDIR=${VAR}_unit_large         ; TILEDIR=${VAR}_tiles_intb         ;  export TYPE=Int16   ; export NODATA=-10 ;  fi 

ls  $MERIT/$UNITDIR/${VAR}_brokb*.tif | xargs -n 1 -P 3 bash -c $\'
file=$1 
filename=$(basename $file .tif )
gdal_translate -a_nodata $NODATA  -ot $TYPE -eco -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $ulx $uly $lrx $lry  $file   $RAMT/${filename}_${tile}.tif 
if [  -e   $RAMT/${filename}_${tile}.tif  ] ; then 
MAX=$(pkstat -max -i  $RAMT/${filename}_${tile}.tif  | cut -d " " -f 2 )
if [ $MAX -eq $NODATA  ] ; then  
    rm  $RAMT/${filename}_${tile}.tif 
    echo  "the  $RAMT/${filename}_${tile}.tif has been removed"  
fi   # remove files that can have only no data value 
fi 

\' _

tilefile=$(ls  $RAMT/${VAR}_brokb?_${tile}.tif $RAMT/${VAR}_brokb??_${tile}.tif  $RAMT/${VAR}_brokb???_${tile}.tif 2>/dev/null | wc -l   )
echo tiledfile n $tilefile
if [ $tilefile -eq 0  ] ; then echo cp the file ; cp $MERIT/$TILEDIR/${VAR}_${tile}.tif $MERIT/${VAR}_tiles_final ; 
else  

gdalbuildvrt   -separate -overwrite $RAMT/${VAR}_brokb_${tile}.vrt $( ls  $RAMT/${VAR}_brokb?_${tile}.tif $RAMT/${VAR}_brokb??_${tile}.tif  $RAMT/${VAR}_brokb???_${tile}.tif 2>/dev/null )   
BANDN=$( gdalinfo  $RAMT/${VAR}_brokb_${tile}.vrt  | grep Band  | tail -1 | awk \'{ print $2 }\' )

echo first oft-calc on $RAMT/${VAR}_brokb_${tile}.vrt that has $BANDN band

EQUATION=$(for band in $(seq 1 $BANDN); do echo -ne "#$band " ; done ; for band in $(seq 1 $(expr $BANDN  \-  1 )) ; do echo -ne   " M"  ; done )

echo $EQUATION 

oft-calc -of GTiff    -ot $TYPE   $RAMT/${VAR}_brokb_${tile}.vrt  $RAMT/${VAR}_brokb_${tile}.tif    <<EOF
1
$EQUATION
EOF
gdal_translate  -a_nodata $NODATA  -ot $TYPE   -co COMPRESS=DEFLATE -co ZLEVEL=9   $RAMT/${VAR}_brokb_${tile}.tif    $MERIT/${VAR}_unit_tile/${VAR}_brokb_${tile}.tif 
rm -f $RAMT/${VAR}_brokb_${tile}.vrt $RAMT/${VAR}_brokb?_${tile}.tif $RAMT/${VAR}_brokb??_${tile}.tif  $RAMT/${VAR}_brokb???_${tile}.tif  $RAMT/${VAR}_brokb_${tile}.tif  

echo start the second oft-calc

gdalbuildvrt  -srcnodata $NODATA   -vrtnodata $NODATA   -separate -overwrite    $MERIT/${VAR}_unit_tile/${VAR}_${tile}.vrt   $MERIT/${VAR}_unit_tile/${VAR}_brokb_${tile}.tif     $MERIT/$TILEDIR/${VAR}_${tile}.tif
echo oft-calc  M maximum value 
oft-calc -of GTiff  -ot $TYPE  $MERIT/${VAR}_unit_tile/${VAR}_${tile}.vrt  $MERIT/${VAR}_tiles_final/${VAR}_${tile}_tmp.tif    <<EOF
1
#1 #2 M
EOF
gdal_translate -a_nodata $NODATA   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot $TYPE  $MERIT/${VAR}_tiles_final/${VAR}_${tile}_tmp.tif     $MERIT/${VAR}_tiles_final/${VAR}_${tile}.tif
rm $MERIT/${VAR}_unit_tile/${VAR}_${tile}.vrt $MERIT/${VAR}_tiles_final/${VAR}_${tile}_tmp.tif  $RAMT/${VAR}_brokb_${tile}.tif 

fi 

' _ 
