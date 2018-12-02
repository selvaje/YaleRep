#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc25_corine_reclass.sh 
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc25_corine_reclass.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc25_corine_reclass.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc25_corine_reclass.sh 

DIR=/project/fas/sbsc/ga254/dataproces/GSHL/g250_clc12_V18_5a

# gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -overwrite -s_srs EPSG:3035 -t_srs EPSG:4326  -tr 0.002083333333333 0.002083333333333  $DIR/g250_clc12_V18_5.tif $DIR/g250_clc12_V18_5_wgs84.tif

# pkreclass -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -code  $DIR/corineUrban_legend.txt -i  $DIR/g250_clc12_V18_5_wgs84.tif -o   $DIR/g250_clc12_V18_5_wgs84_urban.tif

#   rm -fr  $DIR/grassdb/loc_CCA
# source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2-grace2.sh  $DIR/grassdb loc_CCA $DIR/g250_clc12_V18_5_wgs84_urban.tif

source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  $DIR/grassdb/loc_CCA/PERMANENT

# r.grow  input=g250_clc12_V18_5_wgs84_urban   output=g250_clc12_V18_5_wgs84_urban_grown  old=1 new=1   radius=1.01  --overwrite
# r.clump  input=g250_clc12_V18_5_wgs84_urban_grown   output=g250_clc12_V18_5_wgs84_urban_clump   --overwrite
# r.colors -r g250_clc12_V18_5_wgs84_urban_clump
# r.out.gdal -f --overwrite   -c     createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32   format=GTiff nodata=0   input=g250_clc12_V18_5_wgs84_urban_clump output=$DIR/g250_clc12_V18_5_wgs84_urban_clump.tif 

# rm -r $DIR/g250_clc12_V18_5_wgs84_urban_clump.tif.aux.xml

g.region w=-1 e=1 s=50 n=53

r.mapcalc "   g250_clc12_V18_5_wgs84_urban_clump_london =  if( g250_clc12_V18_5_wgs84_urban_clump == 40119 , 1 , null()  )"  --overwrite

r.mapcalc "   g250_clc12_V18_5_wgs84_urban_1  =  if( isnull(g250_clc12_V18_5_wgs84_urban_clump) , 1 , 1  )"  --overwrite
r.cost -k   input=g250_clc12_V18_5_wgs84_urban_1  output=g250_clc12_V18_5_wgs84_urban_london_cost start_raster=g250_clc12_V18_5_wgs84_urban_clump_london  --overwrite

r.mapcalc "g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk = if( isnull(g250_clc12_V18_5_wgs84_urban_clump) ||| g250_clc12_V18_5_wgs84_urban_clump == 40119  , g250_clc12_V18_5_wgs84_urban_london_cost , null() )"  --overwrite 

r.mapcalc " g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk100 = int ( g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk  * 100 )"  --overwrite

AREAval=$(r.report -h   map=g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk100   units=c   | awk '{ gsub("[|]"," " ) ;  if(NR==5) {  print $1 , $NF ; val0=$NF } else { sum=$NF+sum ; if (sum<val0) {  print $1  }   }  }  ' | tail -1)


r.mapcalc "g250_clc12_V18_5_wgs84_urban_clump_london_bufmskAREA = if( g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk100 <= $AREAval  , 1  , null()  )"  --overwrite 

r.mapcalc "g250_clc12_V18_5_wgs84_urban_clump_london_bufmskAREAcore = (  g250_clc12_V18_5_wgs84_urban_clump_london_bufmskAREA +   if( isnull(g250_clc12_V18_5_wgs84_urban_clump_london) , 0 , 1 )    )   "  --overwrite 



r.colors -r  g250_clc12_V18_5_wgs84_urban_clump_london_bufmsk
r.out.gdal -f --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32  format=GTiff nodata=0  input=g250_clc12_V18_5_wgs84_urban_clump_london_bufmskAREAcore  output=$DIR/g250_clc12_V18_5_wgs84_urban_clump_london_bufmskAREAcore.tif 

rm -f $DIR/g250_clc12_V18_5_wgs84_urban_clump_london_buffmsk.tif.aux.xml
