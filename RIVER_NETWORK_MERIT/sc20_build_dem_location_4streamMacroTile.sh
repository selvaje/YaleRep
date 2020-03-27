#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_4streamMacroTile.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_4streamMacroTile.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc20_build_dem_location_4streamMacroTile.sh
#SBATCH --array=1-24
#SBATCH --mem=120000

# 24  row for the 45 degree 
# sbatch   /gpfs/loomis/project/sbsc/hydro/scripts/MERIT_HYDRO/sc20_build_dem_location_4streamMacroTile.sh 

# chek for errors 
# for file in    /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_4streamMacroTile.sh.*.err  ; do echo $file ;  grep CANCELLED $file  ;    done


source ~/bin/gdal
source ~/bin/pktools
source ~/bin/grass


echo SLURM_JOB_ID $SLURM_JOB_ID
echo SLURM_ARRAY_JOB_ID $SLURM_ARRAY_JOB_ID
echo SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID
echo SLURM_ARRAY_TASK_COUNT $SLURM_ARRAY_TASK_COUNT
echo SLURM_ARRAY_TASK_MAX $SLURM_ARRAY_TASK_MAX
echo SLURM_ARRAY_TASK_MIN  $SLURM_ARRAY_TASK_MIN

export MERIT=/gpfs/loomis/project/fas/sbsc/hydro/dataproces/MERIT_HYDRO
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO


find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

## to check size of the tiles 
## cd /tmp
## cp  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk_enlarge/msk_enl1km/msk_1km.tif /tmp
## cat  /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt | xargs -n 5 -P 4 bash -c $'  gdal_translate -projwin $2 $3 $4 $5 msk_1km.tif test$1.tif ' _ 
## gdaltindex  all_tif.shp testh0*.tif
## for file in  testh0* ; do pkinfo -nl -ns -f  -i $file ; done  | awk '{  print $2 , $4 * $6  }'  | sort -g -k 2,2 

##  SLURM_ARRAY_TASK_ID=12                                                                       # dimension for the 45  56400  61200 = 3,451,680,000 = 
export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_45d_MERIT_noheader.txt )

#### for testing lunching bash
####  export tile=h03v03 ; export  ulx=14 ; export  uly=42 ; export lrx=17 ; export lry=38

# if [ -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb/lbasin_$tile.tif ] ; then echo lbasin_$tile.tif exist ;  exit ; fi 

echo $ulx $uly $lrx $lry

### take the coridinates from the orginal files and increment of 1 degree 
# 1200 * 0.000833333333333 =  1 degree 
export ulxL=$(  awk -v ulx=$ulx  'BEGIN{ printf ("%.16f" ,  ulx  - 1 ) }')
export ulyL=$(  awk -v uly=$uly  'BEGIN{ printf ("%.16f" ,  uly  + 1 ) }')
export lrxL=$(  awk -v lrx=$lrx  'BEGIN{ printf ("%.16f" ,  lrx  + 1 ) }')
export lryL=$(  awk -v lry=$lry  'BEGIN{ printf ("%.16f" ,  lry  - 1 ) }')

if [ $(echo " $ulxL < -180 "  | bc ) -eq 1 ] ; then export ulxL=-180 ; fi  ; if [ $ulx -lt  -180 ] ; then export ulx=-180 ; fi  
if [ $(echo " $ulyL >   85 "  | bc ) -eq 1 ] ; then export ulyL=85   ; fi  ; if [ $uly -gt   85  ] ; then export uly=85   ; fi 
if [ $(echo " $lrxL >  180 "  | bc ) -eq 1 ] ; then export lrxL=180  ; fi  ; if [ $lrx -gt   180 ] ; then export lrx=180  ; fi  
if [ $(echo " $lryL <  -60 "  | bc ) -eq 1 ] ; then export lryL=-60  ; fi  ; if [ $lry -lt  -60  ] ; then export lry=-60  ; fi  

echo $ulxL $ulyL $lrxL $lryL 

echo are msk elv dep | xargs -n 1 -P 2 bash -c $'
var=$1

gdalbuildvrt   -a_srs EPSG:4326   -overwrite -te $ulxL $lryL $lrxL $ulyL $RAM/${tile}_${var}.vrt  $MERIT/${var}/all_tif.vrt   
gdal_translate --config GDAL_CACHEMAX 20000  -a_srs EPSG:4326 -co BIGTIFF=YES   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulxL $ulyL $lrxL $lryL  $RAM/${tile}_${var}.vrt $RAM/${tile}_${var}.tif
rm $RAM/${tile}_${var}.vrt

if [ $var = "elv" ] || [ $var = "are" ] ; then  
    gdal_edit.py  -a_nodata -9999  $RAM/${tile}_${var}.tif
else
    gdal_edit.py  -a_nodata 0      $RAM/${tile}_${var}.tif
fi

rm -f  $RAM/${tile}_${var}.vrt 

' _ 



export OMP_NUM_THREADS=4
export USE_PTHREAD=4
export WORKERS=4

grass76  -f -text --tmp-location  -c $RAM/${tile}_elv.tif    <<'EOF'

g.remove -f  type=raster name=${tile}_msk
r.external  input=$RAM/${tile}_elv.tif     output=elv        --overwrite 
r.external  input=$RAM/${tile}_msk.tif     output=msk        --overwrite
r.external  input=$RAM/${tile}_dep.tif     output=dep        --overwrite
r.external  input=$RAM/${tile}_are.tif     output=are        --overwrite

g.region  zoom=msk
r.mask raster=msk --o
g.region  -m

### maximum ram 66571M  for 2^63  (2147483648 cell)  / 1 000 000  * 31 M   

r.watershed -m -a  -b  elevation=elv  depression=dep   accumulation=flow drainage=dir_rw flow=are   memory=90000 --o --verbose 
r.stream.extract  elevation=elv  accumulation=flow depression=dep   threshold=0.05  direction=dir  stream_raster=stream  memory=90000 --o --verbose 
r.stream.basins -m -l  stream_rast=stream direction=dir   basins=lbasin  memory=90000 --o --verbose  
r.colors -r stream ; r.colors -r lbasin ; r.colors -r flow

g.remove -f  type=raster name=elv,dep,are  ; rm -f $RAM/${tile}_elv.tif $RAM/${tile}_are.tif $RAM/${tile}_dep.tif


# r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES"      type=UInt32 format=GTiff nodata=0 input=lbasin  output=$SC/lbasin_tiles_brokb/lbasin_$tile.tif &
# r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES"      type=UInt32 format=GTiff nodata=0 input=stream  output=$SC/stream_tiles_brokb/stream_$tile.tif 
# r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES"   type=Int16  format=GTiff nodata=-10   input=dir_rw   output=$SC/dir_rw_tiles_brokb/dir_rw_$tile.tif 
# r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES,INTERLEAVE=BAND,TILED=YES"  type=Float32 format=GTiff input=flow   output=$RAM/flow_$tile.tif 

# pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co BIGTIFF=YES -min -99999999 -max 99999999 -i $RAM/flow_${tile}.tif   -o  $RAM/flowB_${tile}.tif
# pksetmask -m  $RAM/flowB_${tile}.tif   -msknodata 0 -nodata -999999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co BIGTIFF=YES  -co TILED=YES -i $RAM/flow_${tile}.tif  -o $SC/flow_tiles_brokb/flow_${tile}.tif

r.mapcalc " small_zone_flow =   if( !isnull(msk) && isnull(lbasin) , 1 , null()) " --o

g.region w=$ulx  n=$uly  s=$lry  e=$lrx  res=0:00:03   save=crop --o  
g.region region=crop
g.region -m 

echo left stripe 
eS=$(g.region -m  | grep ^e= | awk -F "=" '{ print $2   }' )
wS=$(g.region -m  | grep ^e= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry     e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_wstripe    = lbasin " --o

g.region region=crop
echo right stripe 
wS=$(g.region -m  | grep ^w= | awk -F "=" '{ print $2   }' )
eS=$(g.region -m  | grep ^w= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region n=$uly s=$lry  e=$eS w=$wS  res=0:00:03
r.mapcalc " lbasin_estripe    = lbasin " --o

####

g.region region=crop
echo top stripe 
nS=$(g.region -m  | grep ^n= | awk -F "=" '{ print $2   }' )
sS=$(g.region -m  | grep ^n= | awk -F "=" '{ printf ("%.14f\n" , $2 - ( 1 *  0.000833333333333 )) }' )

g.region e=$lrx w=$ulx  n=$nS s=$sS   res=0:00:03
r.mapcalc " lbasin_nstripe    = lbasin " --o

g.region region=crop
echo bottom stripe 
sS=$(g.region -m  | grep ^s= | awk -F "=" '{ print $2   }' )
nS=$(g.region -m  | grep ^s= | awk -F "=" '{ printf ("%.14f\n" , $2 + ( 1 *  0.000833333333333 )) }' )

g.region e=$lrx w=$ulx  n=$nS s=$sS  res=0:00:03 --o

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

r.mask raster=lbasin_clean  --o

r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0    input=stream  output=$SC/stream_tiles_intb/stream_$tile.tif &
r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0    input=lbasin  output=$SC/lbasin_tiles_intb/lbasin_$tile.tif 

rm -f $SC/stream_tiles_intb/stream_$tile.tif.aux.xml $SC/lbasin_tiles_intb/lbasin_$tile.tif.aux.xml


############## just for the floting area  to save
r.mask raster=msk --o 
r.mapcalc  " lbasin_flow_clean  = if ( !isnull(lbasin_clean ) || !isnull(small_zone_flow) , 1 , null()  ) "
r.mask  raster=lbasin_flow_clean   --o
r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES,INTERLEAVE=BAND,TILED=YES" nodata=-9999   type=Float32 format=GTiff input=flow  output=$SC/flow_tiles_intb/flow_${tile}.tif   &
r.out.gdal --overwrite -f -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,INTERLEAVE=BAND,TILED=YES"    type=Int16   format=GTiff nodata=-10   input=dir_rw           output=$SC/dir_rw_tiles_intb/dir_rw_$tile.tif
##########################################

r.mask raster=msk --o
g.region region=crop # report on the basis of the region setting 

r.mapcalc    " lbasin_broke = if ( isnull(lbasin_flow_clean) , 2  , 1  )  "  --o 
r.out.gdal --overwrite -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte format=GTiff nodata=255  input=lbasin_broke  output=$SC/lbasin_tiles_brokb_msk/lbasin_$tile.tif 
rm -f $SC/lbasin_tiles_brokb/lbasin_$tile.tif .aux.xml 

EOF

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

