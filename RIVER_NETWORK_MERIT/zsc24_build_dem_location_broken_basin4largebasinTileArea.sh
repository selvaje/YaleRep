#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc24_build_dem_location_broken_basin4largebasin.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc24_build_dem_location_broken_basin4largebasin.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc24_build_dem_location_broken_basin4largebasin.sh
#SBATCH --array=1-10
#SBATCH --mem-per-cpu=40000

# 10 number of files 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc24_build_dem_location_broken_basin4largebasinTileArea.sh

MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
df -h 

# SLURM_ARRAY_TASK_ID=126 
export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_50d_MERIT_largebasin.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_50d_MERIT_largebasin.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_50d_MERIT_largebasin.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_50d_MERIT_largebasin.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_50d_MERIT_largebasin.txt )

# if [ -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif ] ; then echo lbasin_$tile.tif exist ;  exit ; fi 

echo $ulx $uly $lrx $lry

### take the coridinates from the orginal files and increment of 1 degree 

export ulxL=$ulx
export ulyL=$uly
export lrxL=$lrx
export lryL=$lry

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
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh $GRASS loc_$tile $RAM/${tile}_msk.tif r.in.gdal

g.remove -f  type=raster name=${tile}_msk

# r.in.gdal in=$RAM/${tile}_msk.tif  out=msk    memory=2000 --o ; rm -f $RAM/${tile}_msk.tif
# r.in.gdal in=$RAM/${tile}_dep.tif  out=dep    memory=2000 --o ; rm -f $RAM/${tile}_dep.tif
# r.in.gdal in=$RAM/${tile}_upa.tif  out=upa    memory=2000 --o ; rm -f $RAM/${tile}_upa.tif 

r.external  input=$RAM/${tile}_elv.tif     output=elv        --overwrite 
r.external  input=$RAM/${tile}_msk.tif     output=msk        --overwrite
r.external  input=$RAM/${tile}_dep.tif     output=dep        --overwrite
r.external  input=$RAM/${tile}_upa.tif     output=upa        --overwrite

r.mask raster=msk --o

r.stream.extract elevation=elv  accumulation=upa threshold=0.5    depression=dep     direction=dir  stream_raster=stream memory=30000 --o --verbose  ;  r.colors -r stream
g.remove -f  type=raster name=upa,elv
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream  direction=dir  basins=lbasin        memory=30000 --o --verbose  ;  r.colors -r lbasin

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_large/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_large/lbasin_$tile.tif.aux.xml 

g.region w=$ulx  n=$uly  s=$lry  e=$lrx  res=0:00:03   save=crop --o  

echo g.region w=$ulx  n=$uly  s=$lry  e=$lrx  res=0:00:03   save=crop --o 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_full/stream_$tile.tif 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_full/lbasin_$tile.tif.aux.xml 

echo left stripe 
eS=$(g.region -m  | grep e= | awk -F "=" '{ print $2   }' )
wS=$(g.region -m  | grep e= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry     e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_wstripe    = lbasin " --o

g.region region=crop
echo right stripe 
wS=$(g.region -m  | grep w= | awk -F "=" '{ print $2   }' )
eS=$(g.region -m  | grep w= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry  e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_estripe    = lbasin " --o

####

g.region region=crop
echo top stripe 
nS=$(g.region -m  | grep n= | awk -F "=" '{ print $2   }' )
sS=$(g.region -m  | grep n= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region e=$lrx w=$ulx  n=$nS s=$sS   res=0:00:03
r.mapcalc " lbasin_nstripe    = lbasin " --o

g.region region=crop
echo bottom stripe 
sS=$(g.region -m  | grep ^s= | awk -F "=" '{ print $2   }' )
nS=$(g.region -m  | grep ^s= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region  n=$nS s=$sS  res=0:00:09
r.mapcalc " lbasin_sstripe    = lbasin " --o

g.region region=crop # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_estripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_wstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_sstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_nstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) \
      | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${tile}_reclass.txt 
r.reclass input=lbasin  output=lbasin_rec   rules=/dev/shm/lbasin_${tile}_reclass.txt   --o
 
rm -f /dev/shm/lbasin_${tile}_reclass.txt 

r.mapcalc  " lbasin_clean = lbasin_rec  " --o
g.remove -f  type=raster name=lbasin_rec,lbasin_estripe,lbasin_wstripe,lbasin_nstripe,lbasin_sstripe 

r.mask raster=lbasin_clean --o

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_intb/stream_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_intb/lbasin_$tile.tif  
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_intb/lbasin_$tile.tif.aux.xml 

r.mask raster=msk --o 

r.mapcalc  " lbasin_broke = if ( isnull(lbasin_clean ) , lbasin , null()  )  "        --o 
r.mapcalc  " stream_broke = if ( isnull(lbasin_clean ) , stream  , null()  )  "  --o 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream_broke  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_brokb/stream_$tile.tif 
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin_broke  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif  
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif.aux.xml 

rm -r /tmp/loc_$tile

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"



exit 
