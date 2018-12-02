#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=2000
#SBATCH  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc23_continentisland_merge_GLOBALEUROASIA_oft-calc.sh
#SBATCH  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc23_continentisland_merge_GLOBALEUROASIA_oft-calc.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc23_continentisland_merge_GLOBALEUROASIA_oft-calc.sh

export DIR=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output
export RAM=/dev/shm
# endorheic 

# cleanram 

echo 0         0  21600 34560 1  > $RAM/tiles_xoff_yoff.txt
echo 21600     0  21600 34560 2 >> $RAM/tiles_xoff_yoff.txt
echo 43200     0  21600 34560 3 >> $RAM/tiles_xoff_yoff.txt
echo 64800     0  21600 34560 4 >> $RAM/tiles_xoff_yoff.txt
echo 86400     0  21600 34560 5 >> $RAM/tiles_xoff_yoff.txt
echo 108000    0  21600 34560 6 >> $RAM/tiles_xoff_yoff.txt
echo 129600    0  21600 34560 7 >> $RAM/tiles_xoff_yoff.txt
echo 151200    0  21600 34560 8 >> $RAM/tiles_xoff_yoff.txt
echo 0         34560  21600 34560 9  >> $RAM/tiles_xoff_yoff.txt
echo 21600     34560  21600 34560 10 >> $RAM/tiles_xoff_yoff.txt
echo 43200     34560  21600 34560 11 >> $RAM/tiles_xoff_yoff.txt
echo 64800     34560  21600 34560 12 >> $RAM/tiles_xoff_yoff.txt
echo 86400     34560  21600 34560 13 >> $RAM/tiles_xoff_yoff.txt
echo 108000    34560  21600 34560 14 >> $RAM/tiles_xoff_yoff.txt
echo 129600    34560  21600 34560 15 >> $RAM/tiles_xoff_yoff.txt
echo 151200    34560  21600 34560 16 >> $RAM/tiles_xoff_yoff.txt

gdalbuildvrt -separate    -te -180 -60 180 84   -overwrite   $RAM/stream01_globe.vrt   $DIR/stream_unit/bistream{1,2,3,4,5,6,7,8,9,10,11,12,13,14,154,573,810,1145,2597,3005,3317,3629,3753,4000,4001}*.tif  #   $DIR/stream/stream01_91518_MERGEleft_clip_ct.tif    $DIR/stream/stream01_91518_MERGEright_clip_ct.tif 

export BANDN=$(gdalinfo $RAM/stream01_globe.vrt  | grep Band  | tail -1 | awk '{  print $2  }' )

pkcreatect -min 0 -max 1 > /tmp/color.txt 

cat  $RAM/tiles_xoff_yoff.txt | xargs -n 5 -P 16 bash -c $' 

echo  $RAM/stream01_globe_${5}.vrt
gdal_translate -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES -of VRT  -srcwin $1 $2 $3 $4  $RAM/stream01_globe.vrt  $RAM/stream01_globe_${5}.vrt

echo calculate min and max for each band  $BANDN  $RAM/stream01_globe_${5}.vrt

for B in $(seq 0  $(expr $BANDN  \-  1 )) ; do echo  $(expr $B + 1 )  $( pkstat -max -b $B -i  $RAM/stream01_globe_${5}.vrt | awk \'{ print $2  }\' ) ; done >  /tmp/stream01_globe_${5}.txt

echo  select only bands that have max = 1 
gdal_translate -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  $(grep -v " 0" /tmp/stream01_globe_${5}.txt | awk \'{  printf("-b %s "  , $1 )  }\' )     $RAM/stream01_globe_${5}.vrt  $RAM/stream01_globe_${5}_lessb.tif 

rm -f   $RAM/stream01_globe_${5}.vrt  /tmp/stream01_globe_${5}.txt

BANDN=$( gdalinfo  $RAM/stream01_globe_${5}_lessb.tif  | grep Band  | tail -1 | awk \'{ print $2 }\' )

echo fot-calc on $RAM/stream01_globe_${5}_lessb.tif that has $BANDN band

EQUATION=$(for band in $(seq 1 $BANDN); do echo -ne "#$band " ; done ; for band in $(seq 1 $(expr $BANDN  \-  1 )) ; do echo -ne   " +"  ; done )

echo $EQUATION 

oft-calc -ot Byte  $RAM/stream01_globe_${5}_lessb.tif     $DIR/stream/tmp/stream01_globe_${5}-oft.tif <<EOF
1
$EQUATION
EOF

rm -f  $RAM/stream01_globe_${5}_lessb.tif /tmp/stream01_globe_${5}.txt 

pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct /tmp/color.txt -min 0.5 -max 9999 -data 1 -nodata 0 -i  $DIR/stream/tmp/stream01_globe_${5}-oft.tif -o $RAM/stream01_globe_${5}-oft_ct.tif
gdal_edit.py -a_nodata 0 $RAM/stream01_globe_${5}-oft_ct.tif 
rm  $DIR/stream/tmp/stream01_globe_${5}-oft.tif

gdalwarp -overwrite   -co COMPRESS=DEFLATE -co ZLEVEL=9   -of GTiff -srcnodata 0 -dstalpha  $RAM/stream01_globe_${5}-oft_ct.tif  $RAM/stream01_globe_${5}_tr.tif 
gdal_edit.py -a_nodata 0 $RAM/stream01_globe_${5}_tr.tif 
' _ 

gdalbuildvrt  -te -180 -60 180 84   -overwrite     $RAM/stream01_globe.vrt  $RAM/stream01_globe_?-oft_ct.tif $RAM/stream01_globe_??-oft_ct.tif
pkcreatect -ot Byte   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct  /tmp/color.txt    -i  $RAM/stream01_globe.vrt   -o   $DIR/stream/stream01_globe01_ct.tif 
gdal_edit.py -a_nodata 0  $DIR/stream/stream01_globe01_ct.tif  
rm -f   $RAM/stream01_globe.vrt  $RAM/stream01_globe_?-oft_ct.tif $RAM/stream01_globe_??-oft_ct.tif

gdalbuildvrt  -te -180 -60 180 84   -overwrite     $RAM/stream01_globe.vrt  $RAM/stream01_globe_?_tr.tif    $RAM/stream01_globe_??_tr.tif 
gdal_translate -ot Byte  -ot Byte   -co COMPRESS=DEFLATE -co ZLEVEL=9    $RAM/stream01_globe.vrt $DIR/stream/stream01_globe01_tr.tif 
gdal_edit.py -a_nodata 0 $DIR/stream/stream01_globe01_tr.tif 
cleanram 
rm -f rm  /tmp/color.txt 

exit 



# controllare il sottostante 
cat  $RAM/tiles_xoff_yoff.txt | xargs -n 5 -P 16 bash -c $'

gdal_translate -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES   -srcwin $1 $2 $3 $4  $DIR/stream/stream01_globe01_trh${TRH}_ct.tif $RAM/stream01_globe_${5}_trh${TRH}-oft_ct.tif
gdal_edit.py -a_nodata 0 $RAM/stream01_globe_${5}_trh${TRH}-oft_ct.tif 

gdalwarp -overwrite   -co COMPRESS=DEFLATE -co ZLEVEL=9   -of GTiff -srcnodata 0 -dstalpha  $RAM/stream01_globe_${5}_trh${TRH}-oft_ct.tif  $RAM/stream01_globe_${5}_trh${TRH}_tr.tif 
gdal_edit.py -a_nodata 0  $RAM/stream01_globe_${5}_trh${TRH}_tr.tif  
rm   $RAM/stream01_globe_${5}_trh${TRH}-oft_ct.tif 

' _ 



gdalbuildvrt  -te -180 -60 180 84   -overwrite     $RAM/stream01_globe_trh${TRH}.vrt  $RAM/stream01_globe_?_trh${TRH}_tr.tif    $RAM/stream01_globe_??_trh${TRH}_tr.tif 
gdal_translate -ot Byte  -ot Byte   -co COMPRESS=DEFLATE -co ZLEVEL=9    $RAM/stream01_globe_trh${TRH}.vrt $DIR/stream/stream01_globe01_trh${TRH}_tr.tif 

cleanram 
rm -f rm  /tmp/color.txt 



