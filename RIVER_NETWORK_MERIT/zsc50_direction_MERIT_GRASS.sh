#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc50_direction_MERIT_GRASS.sh.%J.out   
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc50_direction_MERIT_GRASS.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc50_direction_MERIT_GRASS.sh
#SBATCH --mem-per-cpu=2000

# bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc50_direction_MERIT_GRASS.sh 

DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

for CT in sicily ; do #  madag ; do 

if  [  $CT  = "sicily" ] ; then geo_string="12.38   38.35  15.70  36.60" ; fi 
if  [  $CT  = "madag" ]  ; then geo_string="43.1 -11.8 50.7 -25.6" ; fi 

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/all_tif.vrt  $CT/elv_MERIT.tif  &

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final20d/lbasin_h18v04.tif       $CT/lbasin_GRASS.tif  & 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upa/all_tif.vrt  $CT/upa_MERIT.tif & 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upg/all_tif.vrt  $CT/upg_MERIT.tif & 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/all_tif.vrt  $CT/dep_MERIT.tif &

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dir/all_tif.vrt  $CT/dir_MERIT.tif &

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/slope/tiles/all_tif.vrt        $CT/slope_MERIT.tif & 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string  /project/fas/sbsc/ga254/dataproces/LCESA/1998/LC160_Y1998.tif $CT/LC160_Y1998.tif 

# area pixels 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/75arc-sec-Area_prj28.tif  $CT/75arc-sec-Area_prj28.tif 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $geo_string /project/fas/sbsc/ga254/dataproces/GEO_AREA/area_tif/30arc-sec-Area_prj28.tif  $CT/30arc-sec-Area_prj28.tif 

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/$CT

rm -rf $DIR/$CT/grassdb
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $DIR/$CT/grassdb loc_$CT  elv_MERIT.tif

r.in.gdal in=$DIR/$CT/upa_MERIT.tif out=upa_MERIT  memory=2000 --o 
r.in.gdal in=$DIR/$CT/upg_MERIT.tif out=upg_MERIT  memory=2000 --o 
r.in.gdal in=$DIR/$CT/dep_MERIT.tif out=dep_MERIT  memory=2000 --o
r.in.gdal in=$DIR/$CT/dir_MERIT.tif out=dir_MERIT  memory=2000 --o
r.in.gdal in=$DIR/$CT/elv_MERIT.tif out=elv_MERIT  memory=2000 --o

r.in.gdal in=$DIR/$CT/slope_MERIT.tif           out=slope_MERIT  memory=2000 --o

r.in.gdal in=$DIR/$CT/LC160_Y1998.tif           out=LC160_Y1998  memory=2000 --o
r.in.gdal in=$DIR/$CT/75arc-sec-Area_prj28.tif  out=75arc-sec-Area_prj28  memory=2000 --o
r.in.gdal in=$DIR/$CT/30arc-sec-Area_prj28.tif  out=30arc-sec-Area_prj28  memory=2000 --o

# reclass dir_MERIT

echo 0 = 0 >  $DIR/$CT/reclass_dir.txt
echo 1 = 8 >> $DIR/$CT/reclass_dir.txt
echo 2 = 7 >> $DIR/$CT/reclass_dir.txt
echo 4 = 6 >> $DIR/$CT/reclass_dir.txt
echo 8 = 5 >> $DIR/$CT/reclass_dir.txt
echo 16 = 4 >> $DIR/$CT/reclass_dir.txt
echo 32 = 3 >> $DIR/$CT/reclass_dir.txt
echo 64 = 2 >> $DIR/$CT/reclass_dir.txt
echo 128 = 1 >> $DIR/$CT/reclass_dir.txt

r.reclass input=dir_MERIT output=dir_MERIT4grass rules=$DIR/$CT/reclass_dir.txt  --overwrite --verbose

r.mapcalc " dir_MERIT4grass =  dir_MERIT4grass "  ; r.colors -r dir_MERIT4grass
r.out.gdal --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte format=GTiff nodata=255  input=dir_MERIT4grass output=$DIR/$CT/dir_MERIT4grass.tif

# get the stream from the flow accumulation 
r.mapcalc " stream  = if( upa_MERIT > 0.2  , 1 , null()  )   " 
# give the ID to each stream (not to each segment-river) 
r.clump -d  --overwrite    input=stream     output=stream_ID 

# get the basin 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream_ID  direction=dir_MERIT4grass  basins=lbasin_MERIT  memory=8000 --o --verbose

# consider that to run the r.stream.basins for the subasin we need to create a segment-stream ID and than run r.stream.basins.

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.channel stream_rast=stream  direction=dir_MERIT4grass  elevation=elv_MERIT  memory=8000 identifier=stream_segID   --overwrite
# unfortunatly the r.stream.basins do not accept stream_segID  this is probabaly due becouse the ID is not at each segment. 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins  stream_rast=stream_segID  direction=dir_MERIT4grass  basins=subbasin_MERIT  memory=8000 --o --verbose

r.colors  map=stream_segID color=random

r.colors -r lbasin_MERIT ; r.colors -r stream_ID

r.out.gdal     --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin_MERIT  output=$DIR/$CT/lbasin_MERIT.tif 
r.out.gdal     --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=subbasin_MERIT  output=$DIR/$CT/subbasin_MERIT.tif 
r.out.gdal -f  --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream       output=$DIR/$CT/stream.tif 
r.out.gdal -f  --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream_ID       output=$DIR/$CT/stream_ID.tif 
r.out.gdal -f  --overwrite -c  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream_segID       output=$DIR/$CT/stream_segID.tif 

rm -f  $DIR/$CT/*.tif.aux.xml 

# random color creation basin 
bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh  $DIR/$CT/lbasin_MERIT.tif  $DIR/$CT/lbasin_MERIT_color.txt
awk '{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }'     $DIR/$CT/lbasin_MERIT_color.txt > $DIR/$CT/lbasin_MERIT_color_0.txt

gdaldem color-relief -alpha   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/$CT/lbasin_MERIT.tif  $DIR/$CT/lbasin_MERIT_color_0.txt    $DIR/$CT/lbasin_MERIT_ct.tif

# random color creation stream
bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh  $DIR/$CT/stream_segID.tif   $DIR/$CT/stream_segID_color.txt
awk '{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }'     $DIR/$CT/stream_segID_color.txt > $DIR/$CT/stream_segID_color_0.txt

gdaldem color-relief -alpha   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/$CT/stream_segID.tif $DIR/$CT/stream_segID_color_0.txt $DIR/$CT/stream_segID_ct.tif

/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.cell.area output=area_km2  units=km2
r.colors -r area_km2
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=area_km2   output=$DIR/$CT/area_km2.tif 

# accumulate down using the direction , cumulate the slope, area_pixel and the pixel 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.accumulate direction=dir_MERIT4grass accumulation=slop_accumulate  weight=slope_MERIT
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.accumulate direction=dir_MERIT4grass accumulation=area_accumulate  weight=area_km2
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.accumulate direction=dir_MERIT4grass accumulation=pix_accumulate  

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.hydrodem  input=elv_MERIT  output=elv_MERIT_cond
r.watershed  elevation=elv_MERIT_cond  drainage=drainage_w   stream=stream_w accumulation=accumulation_w  threshold=100  --o
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins  direction=drainage_w  stream_rast=stream_w  basins=basins_last_w  -l  --o
r.clump -d input=basins_last_w  output=basins_cat_w  --o 
r.mapcalc "drainage_sub_w = if (basins_cat_w==147, drainage_w, null() ) "  --o
r.mapcalc "stream_sub_w   = if (basins_cat_w==147, stream_w, null() ) "  --o

r.out.gdal  input=drainage_sub_w   output=$DIR/$CT/drainage_sub_w.tif  type=Int32  nodata=-9999  --o  -c    createopt="COMPRESS=LZW,ZLEVEL=9"
r.out.gdal  input=stream_sub_w     output=$DIR/$CT/stream_sub_w.tif    type=Int32  nodata=-9999  --o  -c    createopt="COMPRESS=LZW,ZLEVEL=9"

/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.stream.watersheds   stream=stream_sub_w    drainage=drainage_sub_w  cpu=8
/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.stream.variables  variable=elv_MERIT_cond  output=sum  area=watershed   scale=1  cpu=8

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.accumulate direction=drainage_w  accumulation=elv_MERIT_cond_raccumul  weight=elv_MERIT_cond

r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=0  input=elv_MERIT_cond_raccumul  output=$DIR/$CT/elv_MERIT_cond_raccumul.tif


r.colors -r area_accumulate      ;  r.colors -r slop_accumulate         ; r.colors -r  pix_accumulate 
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=pix_accumulate  output=$DIR/$CT/pix_accumulate.tif 
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=slop_accumulate output=$DIR/$CT/slop_accumulate.tif 
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=area_accumulate output=$DIR/$CT/area_accumulate.tif 

# calculate difference between flowaccumulationArea_r.accumulate and  flowaccumulationArea_MERIT
r.mapcalc " area_upa  =  area_accumulate - upa_MERIT " # the results of this != 0 this becouse the area pixel calculate by grass is slitly different from the Dai's area_pixel 

# calculate difference between flowaccumulationPixel_r.accumulate and  flowaccumulationPixel_MERIT
r.mapcalc " pix_upg  =   pix_accumulate  - upg_MERIT " # the results of this = 0 this means that the r.accumulate cumulate down following the flow accumulation 

r.info area_upa 
r.info pix_upg 

r.colors -r pix_upg ; r.colors -r area_upa 
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float64 format=GTiff nodata=-9999  input=area_upa output=$DIR/$CT/area_upa.tif 
r.out.gdal --overwrite -c -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float64 format=GTiff nodata=-9999  input=pix_upg output=$DIR/$CT/pix_upg.tif 

rm -f  $DIR/$CT/*.tif.aux.xml

done 
