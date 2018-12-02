#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_4streamMacroTile1pixeloverlap.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_4streamMacroTile1pixeloverlap.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc20_build_dem_location_4streamMacroTile1pixeloverlap.sh
#SBATCH --array=1-36
#SBATCH --mem-per-cpu=40000

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc20_build_dem_location_4streamMacroTile1pixeloverlap.sh

MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm

find  /tmp/     -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  



# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# SLURM_ARRAY_TASK_ID=126 
export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_40d_MERIT_noheader.txt )

# if [ -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif ] ; then echo lbasin_$tile.tif exist ;  exit ; fi 

echo $ulx $uly $lrx $lry

### take the coridinates from the orginal files and increment of 1 degree 

export ulxL=$(  awk -v ulx=$ulx  'BEGIN{ printf ("%.16f" ,  ulx  - 1 ) }')
export ulyL=$(  awk -v uly=$uly  'BEGIN{ printf ("%.16f" ,  uly  + 1 )}')
export lrxL=$(  awk -v lrx=$lrx  'BEGIN{ printf ("%.16f" ,  lrx  + 1 )}')
export lryL=$(  awk -v lry=$lry  'BEGIN{ printf ("%.16f" ,  lry  - 1 )}')

if [ $(echo " $ulxL < -180 "  | bc ) -eq 1 ] ; then ulxL=-180 ; fi  ; if [ $ulx -lt  -180 ] ; then ulx=-180 ; fi  
if [ $(echo " $ulyL >  85 "   | bc ) -eq 1 ] ; then ulyL=85   ; fi  ; if [ $uly -gt   85  ] ; then uly=85   ; fi 
if [ $(echo " $lrxL >  180"   | bc ) -eq 1 ] ; then lrxL=180  ; fi  ; if [ $lrx -gt   180 ] ; then lrx=180  ; fi  
if [ $(echo " $lryL <  -60"   | bc ) -eq 1 ] ; then lryL=-60  ; fi  ; if [ $lry -lt  -60  ] ; then lry=-60  ; fi  

echo $ulxL $ulyL $lrxL $lryL 

for var in msk elv dep upa ; do 
gdalbuildvrt -overwrite -te $ulxL $lryL $lrxL $ulyL $RAM/${tile}_${var}.vrt  $MERIT/${var}/all_tif.vrt   
gdal_translate -co BIGTIFF=YES   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulxL $ulyL $lrxL $lryL  $RAM/${tile}_${var}.vrt $RAM/${tile}_${var}.tif

if [ $var = "msk" ] ; then MAX=$(pkstat -max  -i     $RAM/${tile}_${var}.tif    | awk '{ print $2  }' )  ; fi 
if [ $MAX -eq 0   ] ; then rm -f $RAM/${tile}_${var}.tif  $RAM/${tile}_${var}.vrt ; exit ; fi 

if [ $var = "elv" ] || [ $var = "upa" ] ; then  
    gdal_edit.py  -a_nodata -9999  $RAM/${tile}_${var}.tif
else
    gdal_edit.py  -a_nodata 0      $RAM/${tile}_${var}.tif
fi
done 
rm -f  $RAM/${tile}_${var}.vrt 

rm -fr $GRASS/loc_$tile
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh $GRASS loc_$tile $RAM/${tile}_elv.tif

rm -f $RAM/${tile}_elv.tif
g.rename  raster=${tile}_elv,elv 

r.in.gdal in=$RAM/${tile}_msk.tif  out=msk    memory=2000 --o ; rm -f $RAM/${tile}_msk.tif
r.in.gdal in=$RAM/${tile}_dep.tif  out=dep    memory=2000 --o ; rm -f $RAM/${tile}_dep.tif
r.in.gdal in=$RAM/${tile}_upa.tif  out=upa    memory=2000 --o ; rm -f $RAM/${tile}_upa.tif 

r.mask raster=msk --o

r.stream.extract elevation=elv  accumulation=upa threshold=0.5    depression=dep     direction=dir  stream_raster=stream memory=30000 --o --verbose  ;  r.colors -r stream
g.remove -f  type=raster name=upa,elv
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir  basins=lbasin        memory=30000 --o --verbose  ;  r.colors -r lbasin

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_large/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif.aux.xml 

export ulxL1p=$(  awk -v ulx=$ulx  'BEGIN{ printf ("%.16f" ,  ulx  - (0 * 0.000833333333333 )) }')
export ulyL1p=$(  awk -v uly=$uly  'BEGIN{ printf ("%.16f" ,  uly  + (0 * 0.000833333333333 )) }')
export lrxL1p=$(  awk -v lrx=$lrx  'BEGIN{ printf ("%.16f" ,  lrx  + (1 * 0.000833333333333 )) }')
export lryL1p=$(  awk -v lry=$lry  'BEGIN{ printf ("%.16f" ,  lry  - (1 * 0.000833333333333 )) }')


if [ $(echo " $ulxL1p < -180 "  | bc ) -eq 1 ] ; then ulxL1p=-180 ; fi  
if [ $(echo " $ulyL1p >  85 "   | bc ) -eq 1 ] ; then ulyL1p=85   ; fi  
if [ $(echo " $lrxL1p >  180"   | bc ) -eq 1 ] ; then lrxL1p=180  ; fi  
if [ $(echo " $lryL1p <  -60"   | bc ) -eq 1 ] ; then lryL1p=-60  ; fi  

echo w=$ulx     n=$uly     s=$lry     e=$lrx      normal dimension 
echo w=$ulxL1p  n=$ulyL1p  s=$lryL1p  e=$lrxL1p   1pixel large 


g.region w=$ulxL1p  n=$ulyL1p  s=$lryL1p  e=$lrxL1p  res=0:00:03   save=crop --o  

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_1pixel/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_1pixel/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif.aux.xml 

exit 
