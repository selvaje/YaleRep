# change trh
#  for EUROASIA in LEFT CENTER RIGHT ; do bsub  -J sc08_river_newtworkGMTED250_EUROASIA.sh   -W 24:00 -M 70000  -R "rusage[mem=70000]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc08_river_newtworkGMTED250_EUROASIA.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250_EUROASIA.sh.%J.err   -J sc08_river_newtworkGMTED250_EUROASIA.sh   bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc08_river_newtworkGMTED250_EUROASIA.sh $EUROASIA 1 ; done 

#  grep -B 5  G_malloc /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250.sh.*.err  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250_EUROASIA.sh.*.err

# this should be the maximum with the ram
# expr 2000000000 / 1000000 \* 31    = 62000 MB   ##  60 GIGA, so asking always 70

# 90420 11750011      MADAGASCAR        
# 10328 12535192      canada island 
# 80691 13772932     indonesia 
# 84397 14731200     guinea 
# 2285 22431475      canada island 
# 26487 26414813     canada island 
# 33778 150020638    greenland      
# 92404 158200595     AUSTRALIA
# 11000 350855901     south america 
# 11001 576136081     africa 
# 98343 596887982     north america 
# 91518 1474765872    EUROASIA    
# 19899               EUROASIA camptacha

EUROASIA=$1
TRH=$2

# euroasia camptacha data preparation 

DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2.sh $DIR/grassdb/loc_river_EUROASIA/PERMANENT  

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc$UNIT

UNIT=91518

echo create mapset unit$UNIT

rm -fr  $DIR/grassdb/loc_river/unit${UNIT}_${TRH}_$EUROASIA

g.mapset -c  mapset=unit${UNIT}_${TRH}_$EUROASIA  location=loc_river_EUROASIA  dbase=$DIR/grassdb   --quiet --overwrite 

cp $DIR/grassdb/loc_river_EUROASIA/PERMANENT/WIND  $DIR/grassdb/loc_river_EUROASIA/unit${UNIT}_${TRH}_$EUROASIA/WIND

rm -f $DIR/grassdb/loc_river_EUROASIA/unit${UNIT}_${TRH}_$EUROASIA/.gislock

g.gisenv 

g.region raster=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA   res=0:00:07.5
if [ $EUROASIA = LEFT ]    ; then  g.region  e=53        res=0:00:07.5 zoom=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA ; fi 
if [ $EUROASIA = CENTER ]  ; then  g.region  w=-20  e=92 res=0:00:07.5 zoom=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA ; fi 
if [ $EUROASIA = RIGHT ]   ; then  g.region  w=50        res=0:00:07.5 zoom=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA ; fi 

r.mask   rast=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA   --overwrite

echo start r.watershed 

echo starting use treshold $TRH $TRH  $TRH  $TRH                                   # also cal direction 

r.watershed  elevation=be75_grd_LandEnlarge_cond_carv100smoth_EUROASIA  basin=basin  stream=stream drainage=drainage  accumulation=accumulation  memory=65000 threshold=$TRH  --overwrite   

echo r.stream.basins l option basin_last 

/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins   direction=drainage  stream_rast=stream  basins=basin_last  -l  --o memory=65000

echo r.stream.basins l option basin_elem # create error under 100  

# /lustre/home/client/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins  direction=drainage  stream_rast=stream  basins=basin_elem  --o     memory=65000

echo r.stream.order 

/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.order  direction=drainage stream_rast=stream strahler=strahler horton=horton shreve=shreve hack=hack topo=topo memory=65000
g.list rast 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=stream output=$DIR/output/stream/stream${UNIT}_${EUROASIA}_trh$TRH.tif

pkcreatect -min 0 -max 1 > /tmp/color.txt  
pkgetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct /tmp/color.txt     -ot Byte   -min 0.5   -max  9999999999999  -data 1   -i $DIR/output/stream/stream${UNIT}_${EUROASIA}_trh$TRH.tif -o $DIR/output/stream/stream01_${UNIT}_${EUROASIA}_trh$TRH.tif

r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16  format=GTiff nodata=-99    input=drainage output=$DIR/output/drainage/drainage${UNIT}_${EUROASIA}_trh$TRH.tif 
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES"             format=GTiff nodata=-999999999      input=accumulation output=$DIR/output/accumulation/accumulation${UNIT}_${EUROASIA}_trh$TRH.tif #in automatic Flat64 and nodata 

r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin output=$DIR/output/basin/basin${UNIT}_${EUROASIA}_trh$TRH.tif   
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin_last output=$DIR/output/basin_last/basin_last${UNIT}_${EUROASIA}_trh$TRH.tif
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin_elem output=$DIR/output/basin_elem/basin_elem${UNIT}_${EUROASIA}_trh$TRH.tif

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"        format=GTiff nodata=-1  input=tci output=$DIR/output/tci/tci${UNIT}_${EUROASIA}_trh$TRH.tif

rm -f $DIR/output/*/*trh$TRH.tif.aux.xml 
rm -fr  $DIR/grassdb/loc_river/unit${UNIT}_${TRH}_$EUROASIA
exit 


# stream order 

r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=strahler     output=$DIR/output/strahler/strahler${UNIT}_${EUROASIA}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=horton       output=$DIR/output/horton/horton${UNIT}_${EUROASIA}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=shreve       output=$DIR/output/shreve/shreve${UNIT}_${EUROASIA}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=hack         output=$DIR/output/hack/hack${UNIT}_${EUROASIA}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=topo         output=$DIR/output/topo/topo${UNIT}_${EUROASIA}_trh$TRH.tif



# rm -fr $DIR/grassdb/loc_river/unit$UNIT
