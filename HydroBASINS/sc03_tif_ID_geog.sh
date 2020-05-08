#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 9  -N 1  
#SBATCH -t 4:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_tif_ID_geog.sh%J.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_tif_ID_geog.sh%J.out
#SBATCH --job-name=sc03_tif_ID_geog.sh
#SBATCH --mem=50G
 
##### final  

###### sbatch /gpfs/loomis/home.grace/ga254/scripts/HydroBASINS/sc03_tif_ID_geog.sh

export SHP=/gpfs/loomis/project/sbsc/ga254/dataproces/HydroBASINS/GEOG
export TIF=/gpfs/loomis/project/sbsc/ga254/dataproces/HydroBASINS/GEOG_ID_TIF

source ~/bin/gdal 

rm -f /gpfs/loomis/project/sbsc/ga254/dataproces/HydroBASINS/GEOG_ID_TIF/*.*

ls  $SHP/hybas_??_lev02_v1c.shp | xargs -n 1 -P 9  bash -c $' 

file=$1
filename=$(basename $file .shp) 
ogrinfo -al -geom=NO  $file | grep " HYBAS_ID " | awk \'{  print $4 }\'   > $TIF/${filename}_ID.txt 


for ID in $( cat $TIF/${filename}_ID.txt   ) ; do 

echo processing $TIF/${filename}_ID$ID.tif 

rm -fr $TIF/${filename}_ID$ID.{shp,shx,prj,dbf} 
ogr2ogr  -overwrite  -f "ESRI Shapefile"  -where  "HYBAS_ID = \'$ID\' " $TIF/${filename}_ID$ID.shp  $file 

gdal_rasterize --config GDAL_CACHEMAX 4000  -burn 255  -tr 0.000833333333333333333 0.000833333333333333333  -ot Byte   -a_srs EPSG:4326 -a_nodata 0   \
-te $(getCornersOgr4Gwarp  $TIF/${filename}_ID$ID.shp   | awk \'{ printf("%3.1f %3.1f %3.1f %3.1f\\n", $1 - 3  , $2  - 3 , $3  + 3 , $4  + 3  ) }\' ) \
-co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co TILED=YES    $TIF/${filename}_ID$ID.shp  $TIF/${filename}_ID$ID.tif 
rm -fr $TIF/${filename}_ID$ID.{shp,shx,prj,dbf}

done  

' _ 



ls  $SHP/hybas_??_lev03_v1c_sel.shp | xargs -n 1 -P 9  bash -c $' 

file=$1
filename=$(basename $file _sel.shp) 
ogrinfo -al -geom=NO  $file | grep " HYBAS_ID " | awk \'{  print $4 }\'   > $TIF/${filename}_ID.txt 


for ID in $( cat $TIF/${filename}_ID.txt   ) ; do 

echo processing $TIF/${filename}_ID$ID.tif 

rm -fr $TIF/${filename}_ID$ID.{shp,shx,prj,dbf} 
ogr2ogr  -overwrite  -f "ESRI Shapefile"  -where  "HYBAS_ID = \'$ID\' " $TIF/${filename}_ID$ID.shp  $file 

gdal_rasterize --config GDAL_CACHEMAX 4000  -burn 255  -tr 0.000833333333333333333 0.000833333333333333333  -ot Byte   -a_srs EPSG:4326 -a_nodata 0  \
-te $(getCornersOgr4Gwarp  $TIF/${filename}_ID$ID.shp   | awk \'{ printf("%3.1f %3.1f %3.1f %3.1f\\n", $1 - 3  , $2  - 3 , $3  + 3 , $4  + 3  ) }\' ) \
-co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -co TILED=YES    $TIF/${filename}_ID$ID.shp  $TIF/${filename}_ID$ID.tif 
rm -fr $TIF/${filename}_ID$ID.{shp,shx,prj,dbf}

done  

' _ 


###  maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
###  hybas_au_lev02_v1c_ID5020049720.tif 52560 42480 2232748800 2.23275
###  hybas_gr_lev02_v1c_ID9020000010.tif 75240 29880 2248171200 2.24817
###  hybas_si_lev02_v1c_ID3020009320.tif 63600 37201 2365983600 2.36598
###  hybas_na_lev02_v1c_ID7020000010.tif 55200 47760 2636352000 2.63635
###  hybas_af_lev02_v1c_ID1020000010.tif 36000 65160 2345760000 2.34576
###  hybas_af_lev02_v1c_ID1020027430.tif 67800 35280 2391984000 2.39198
###  hybas_au_lev02_v1c_ID5020054880.tif 62160 39600 2461536000 2.46154


####  hybas_ar_lev02_v1c.shp     8020020760   -180 eliminato 
####  hybas_si_lev03_v1c_sel.shp 3030011770   +180 eliminato 


cd $TIF 
for file in $( ls *.tif | grep -v hybas_au_lev02_v1c_ID5020049720.tif | grep -v hybas_gr_lev02_v1c_ID9020000010.tif | grep -v hybas_si_lev02_v1c_ID3020009320.tif  | grep -v hybas_na_lev02_v1c_ID7020000010.tif  | grep -v hybas_af_lev02_v1c_ID1020000010.tif | grep -v hybas_af_lev02_v1c_ID1020027430.tif   | grep -v hybas_au_lev02_v1c_ID5020054880.tif | grep -v hybas_au_lev03_v1c_ID5030055130.tif  | grep -v hybas_ar_lev02_v1c_ID8020020760.tif  | grep -v hybas_si_lev03_v1c_ID3030011770.tif | grep -v hybas_si_lev03_v1c_ID3030024180.tif  | grep -v hybas_as_lev02_v1c_ID4020050470.tif | grep -v hybas_si_lev02_v1c_ID3020024310.tif | grep -v hybas_si_lev03_v1c_ID3030022480.tif  | grep -v hybas_af_lev03_v1c_ID1030027430.tif | grep -v hybas_af_lev02_v1c_ID1020034170.tif | grep -v hybas_af_lev02_v1c_ID1020018110.tif | grep -v hybas_af_lev03_v1c_ID1030003990.tif | grep -v hybas_au_lev03_v1c_ID5030087590.tif | grep -v hybas_au_lev03_v1c_ID5030087600.tif  ) ; do echo $file $( gdalinfo $file  | grep "Size is" | \
awk '{ gsub(","," ") ;  print $3 , $4 , $3 * $4 , $3 * $4 / 1000000000 }' )  ; done |  sort -g -k 5,5 > $TIF/tif_size.txt 

exit 

# checking tif extention 
# for file in *.tif ; do  echo $file $(getCorners4Gtranslate $file) ; done
