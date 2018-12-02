# rmember to change the trh=$1                                                                                                                                        # 102400 = 50GIGA 
# for UNIT in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 90420 10328 80691 84397 2285 26487 33778 92404 11000 11001 98343  ; do bsub  -J sc08_river_newtworkGMTED250.sh   -W 24:00 -M 70000  -R "rusage[mem=70000]" -n 1  -R "span[hosts=1]"    -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc08_river_newtworkGMTED250.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250.sh.%J.err   -J sc08_river_newtworkGMTED250.sh   bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc08_river_newtworkGMTED250.sh $UNIT 4 ; done 

# echo "58261 * 37729 / 1000000 * 31"  | bc    = 68138 

#  bsub   ..   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc08_river_newtworkGMTED250.sh 90420 100

# check for memory error in the err file 
# grep -B 5  G_malloc /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250.sh.*.err  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_river_newtworkGMTED250_EUROASIA.sh.*.err

# 90420 11750011      MADAGASCAR        
# 10328 12535192      canada island 
# 80691 13772932      indonesia 
# 84397 14731200      guinea 
# 2285 22431475       canada island 
# 26487 26414813      canada island 
# 33778 150020638     greenland      
# 92404 158200595     AUSTRALIA
# 11000 350855901     south america 
# 11001 576136081     africa 
# 98343 596887982     north america 
# 91518 1474765872    EUROASIA    


# madagascar  90420
UNIT=$1
TRH=$2
DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK


gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9   -projwin    $(getCorners4Gtranslate $DIR/unit/UNIT${UNIT}msk.tif )  $DIR/../GIW_LANDSAT/tif_250m_from_30m4326/GIW_water_250m_max_bordermsk_ct.tif  $DIR/output/GIW_water/GWI_UNIT${UNIT}.tif
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9   -projwin    $(getCorners4Gtranslate $DIR/unit/UNIT${UNIT}msk.tif )  $DIR/dem/be75_grd_LandEnlarge_cond_carv100smoth.tif $DIR/output/dem/cond_carv100_UNIT${UNIT}.tif  
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9   -projwin    $(getCorners4Gtranslate $DIR/unit/UNIT${UNIT}msk.tif )  $DIR/dem/be75_grd_LandEnlarge_cond.tif              $DIR/output/dem/cond_UNIT${UNIT}.tif  

source   /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2.sh  $DIR/grassdb/loc_river/PERMANENT/ 

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc${UNIT}_${TRH}

echo create mapset unit$UNIT

rm -fr  $DIR/grassdb/loc_river/unit${UNIT}_${TRH}

g.mapset  -c  mapset=unit${UNIT}_${TRH} location=loc_river  dbase=$DIR/grassdb   --quiet --overwrite 

cp $DIR/grassdb/loc_river/PERMANENT/WIND $DIR/grassdb/loc_river/unit${UNIT}_${TRH}/WIND

rm -f  $DIR/grassdb/loc_river/unit$UNIT/.gislock

g.gisenv 

r.in.gdal in=$DIR/unit/UNIT${UNIT}msk.tif   out=UNIT$UNIT   --overwrite

g.region raster=be75_grd_LandEnlarge_cond_carv100smoth   res=0:00:07.5
g.region raster=UNIT$UNIT  res=0:00:07.5

r.mask   rast=UNIT$UNIT  --overwrite

echo start r.watershed 

echo starting use treshold $TRH $TRH  $TRH  $TRH                                   # also cal direction 

r.watershed -b  elevation=be75_grd_LandEnlarge_cond_carv100smoth  basin=basin  stream=stream    drainage=drainage    accumulation=accumulation  memory=65000  threshold=$TRH   --overwrite   

echo r.stream.basins l option basin_last 

/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins  direction=drainage  stream_rast=stream  basins=basin_last  -l  --o memory=65000

echo r.stream.basins l option basin_elem # create error under 100  
# /lustre/home/client/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins  direction=drainage  stream_rast=stream  basins=basin_elem  --o     memory=65000

echo r.stream.order 
# /home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.order   direction=drainage  stream_rast=stream  strahler=strahler horton=horton shreve=shreve hack=hack topo=topo memory=65000
g.list rast 

r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0      input=stream output=$DIR/output/stream/stream${UNIT}_trh$TRH.tif

pkcreatect -min 0 -max 1 > /tmp/color.txt  
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct /tmp/color.txt -ot Byte -min 0.5 -max 9999999999999 -data 1 -i $DIR/output/stream/stream${UNIT}_trh$TRH.tif -o $DIR/output/stream/stream01_${UNIT}_trh$TRH.tif
rm /tmp/color.txt  

r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16  format=GTiff nodata=-99         input=drainage output=$DIR/output/drainage/drainage${UNIT}_trh$TRH.tif 
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" format=GTiff nodata=-999999999  input=accumulation output=$DIR/output/accumulation/accumulation${UNIT}_trh$TRH.tif # in automatic Flat64 and nodata 

r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin      output=$DIR/output/basin/basin${UNIT}_trh$TRH.tif   
r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin_last output=$DIR/output/basin_last/basin_last${UNIT}_trh$TRH.tif
# r.out.gdal --overwrite  -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32       format=GTiff nodata=0 input=basin_elem output=$DIR/output/basin_elem/basin_elem${UNIT}_trh$TRH.tif

rm -f $DIR/output/*/*trh$TRH.tif.aux.xml 
exit 

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"        format=GTiff nodata=-1  input=tci output=$DIR/output/tci/tci${UNIT}_trh$TRH.tif

# stream order 

r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=strahler     output=$DIR/output/strahler/strahler${UNIT}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=horton       output=$DIR/output/horton/horton${UNIT}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=shreve       output=$DIR/output/shreve/shreve${UNIT}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=hack         output=$DIR/output/hack/hack${UNIT}_trh$TRH.tif
r.out.gdal --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt16   format=GTiff nodata=0   input=topo         output=$DIR/output/topo/topo${UNIT}_trh$TRH.tif

rm -f $DIR/output/*/*trh$TRH.tif.aux.xml 

# rm -fr $DIR/grassdb/loc_river/unit${UNIT}_${TRH} 
