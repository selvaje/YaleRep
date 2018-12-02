#!/bin/bash
#SBATCH -p day
#SBATCH -J sc06_maxComposite.sh
#SBATCH -n 1 -c 16 -N 1  
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_maxComposite.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_maxComposite.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch    /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc06_maxComposite.sh

# bsub -n 16  -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_maxComposite.sh.%J.out -o /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_maxComposite.sh.%J.err bash   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc06_maxComposite.sh

export RAM=/dev/shm    
cleanram

echo 0          0 5401 10800 a  >  $RAM/tiles_xoff_yoff.txt
echo 5400       0 5401 10800 b  >> $RAM/tiles_xoff_yoff.txt
echo 10800      0 5401 10800 c  >> $RAM/tiles_xoff_yoff.txt
echo 16200      0 5401 10800 d  >> $RAM/tiles_xoff_yoff.txt
echo 21600      0 5401 10800 e  >> $RAM/tiles_xoff_yoff.txt
echo 27000      0 5401 10800 z  >> $RAM/tiles_xoff_yoff.txt
echo 32400      0 5401 10800 g  >> $RAM/tiles_xoff_yoff.txt
echo 37800      0 5401 10800 h  >> $RAM/tiles_xoff_yoff.txt
echo 0      10800 5401 10800 i  >> $RAM/tiles_xoff_yoff.txt
echo 5400   10800 5401 10800 l  >> $RAM/tiles_xoff_yoff.txt
echo 10800  10800 5401 10800 m  >> $RAM/tiles_xoff_yoff.txt
echo 16200  10800 5401 10800 n  >> $RAM/tiles_xoff_yoff.txt
echo 21600  10800 5401 10800 o  >> $RAM/tiles_xoff_yoff.txt
echo 27000  10800 5401 10800 k  >> $RAM/tiles_xoff_yoff.txt
echo 32400  10800 5401 10800 q  >> $RAM/tiles_xoff_yoff.txt
echo 37800  10800 5401 10800 r  >> $RAM/tiles_xoff_yoff.txt

export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MYOD11A2_celsiusmean
export OUT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/LST_max

cat  $RAM/tiles_xoff_yoff.txt  | xargs -n 5 -P 16 bash -c $' 

xoff=$1
yoff=$2
xsize=$3
ysize=$4
tile=$5

for file in $DIR/LST_MOYDmax_Day_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}.tif  ; do 
filename=$(basename $file .tif)
gdal_translate -ot Float32   -co  COMPRESS=DEFLATE  -co ZLEVEL=9   -srcwin  $xoff $yoff $xsize $ysize   $file   $OUT/tmp/${filename}_${tile}.tif
done 

echo start the pkcomposite Day

pkcomposite -ot Float32 -msknodata -9999   -srcnodata -9999  -dstnodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -cr maxband -file 2  $(ls $OUT/tmp/LST_MOYDmax_Day_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}_${tile}.tif  | xargs -n 1 echo -i )  -o $OUT/tmp/LST_MOYDmax_Day_${tile}.tif
gdal_translate -ot Float32   -co  COMPRESS=DEFLATE  -co ZLEVEL=9   -srcwin 0 0  5400 10800  $OUT/tmp/LST_MOYDmax_Day_${tile}.tif  $OUT/tmp/LST_MOYDmax_Day_${tile}_tmp.tif ; 
mv $OUT/tmp/LST_MOYDmax_Day_${tile}_tmp.tif $OUT/tmp/LST_MOYDmax_Day_${tile}.tif

rm  -f   $OUT/tmp/LST_MOYDmax_Day_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}_${tile}.tif 

' _ 

echo start the merging operation DAY

gdalbuildvrt   $OUT/tmp/LST_MOYDmax_Day.vrt    $OUT/tmp/LST_MOYDmax_Day_*.tif 

gdal_translate       -ot Float32     -a_nodata -9999  -b 1 -co  COMPRESS=DEFLATE   -co ZLEVEL=9     $OUT/tmp/LST_MOYDmax_Day.vrt  $OUT/LST_MOYDmax_Day_value_tmp.tif
pksetmask -ot Float32  -m  $DIR/LST_MOYDmax_Day_spline_month1.tif  -msknodata -9999 -nodata -9999 -co  COMPRESS=DEFLATE   -co ZLEVEL=9  -i    $OUT/LST_MOYDmax_Day_value_tmp.tif  -o  $OUT/LST_MOYDmax_Day_value.tif
rm  $OUT/LST_MOYDmax_Day_value_tmp.tif 

gdal_translate -ot Byte   -a_nodata   255  -b 2 -co  COMPRESS=DEFLATE   -co ZLEVEL=9     $OUT/tmp/LST_MOYDmax_Day.vrt  $OUT/LST_MOYDmax_Day_month_tmp.tif

oft-calc  $OUT/LST_MOYDmax_Day_month_tmp.tif $OUT/LST_MOYDmax_Day_month_tmp2.tif <<EOF
1
#1 1 + 
EOF

pkcreatect -min  0 -max     12  > /tmp/color.txt
pksetmask -ct /tmp/color.txt  -m  $DIR/LST_MOYDmax_Day_spline_month1.tif  -msknodata -9999 -nodata 0 -ot Byte  -co  COMPRESS=DEFLATE   -co ZLEVEL=9  -i   $OUT/LST_MOYDmax_Day_month_tmp2.tif -o   $OUT/LST_MOYDmax_Day_month.tif

rm -f $OUT/tmp/*   $OUT/LST_MOYDmax_Day_month_tmp2.tif  $OUT/LST_MOYDmax_Day_month_tmp.tif
  


cat  $RAM/tiles_xoff_yoff.txt   | xargs -n 5 -P 16 bash -c $' 

xoff=$1
yoff=$2
xsize=$3
ysize=$4
tile=$5

for file in $DIR/LST_MOYDmax_Nig_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}.tif  ; do 
filename=$(basename $file .tif)
gdal_translate  -ot Float32   -co  COMPRESS=DEFLATE  -co ZLEVEL=9   -srcwin  $xoff $yoff $xsize $ysize   $file   $OUT/tmp/${filename}_${tile}.tif
done 

echo start the pkcomposite Nig

pkcomposite -ot Float32   -msknodata -9999  -srcnodata -9999  -dstnodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -cr maxband -file 2 $(ls $OUT/tmp/LST_MOYDmax_Nig_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}_${tile}.tif | xargs -n 1 echo -i )  -o $OUT/tmp/LST_MOYDmax_Nig_${tile}.tif 


gdal_translate  -ot Float32  -co  COMPRESS=DEFLATE  -co ZLEVEL=9   -srcwin 0 0  5400 10800  $OUT/tmp/LST_MOYDmax_Nig_${tile}.tif  $OUT/tmp/LST_MOYDmax_Nig_${tile}_tmp.tif ; 
mv $OUT/tmp/LST_MOYDmax_Nig_${tile}_tmp.tif $OUT/tmp/LST_MOYDmax_Nig_${tile}.tif


rm  -f   $OUT/tmp/LST_MOYDmax_Nig_spline_month{1,2,3,4,5,6,7,8,9,10,11,12}_${tile}.tif 

' _ 

echo start the merging operation NIG

gdalbuildvrt   $OUT/tmp/LST_MOYDmax_Nig.vrt    $OUT/tmp/LST_MOYDmax_Nig_*.tif 

gdal_translate -ot Float32       -a_nodata -9999  -b 1 -co  COMPRESS=DEFLATE   -co ZLEVEL=9     $OUT/tmp/LST_MOYDmax_Nig.vrt  $OUT/LST_MOYDmax_Nig_value_tmp.tif
pksetmask -ot Float32 -m  $DIR/LST_MOYDmax_Nig_spline_month1.tif  -msknodata -9999 -nodata -9999 -co  COMPRESS=DEFLATE   -co ZLEVEL=9  -i    $OUT/LST_MOYDmax_Nig_value_tmp.tif  -o  $OUT/LST_MOYDmax_Nig_value.tif
rm  $OUT/LST_MOYDmax_Nig_value_tmp.tif 

gdal_translate  -ot Byte   -a_nodata   255  -b 2 -co  COMPRESS=DEFLATE   -co ZLEVEL=9     $OUT/tmp/LST_MOYDmax_Nig.vrt  $OUT/LST_MOYDmax_Nig_month_tmp.tif

oft-calc  $OUT/LST_MOYDmax_Nig_month_tmp.tif $OUT/LST_MOYDmax_Nig_month_tmp2.tif <<EOF
1
#1 1 + 
EOF

pkcreatect -min  0 -max     12  > /tmp/color.txt
pksetmask -ct /tmp/color.txt  -m  $DIR/LST_MOYDmax_Nig_spline_month1.tif  -msknodata -9999 -nodata 0 -ot Byte  -co  COMPRESS=DEFLATE   -co ZLEVEL=9  -i   $OUT/LST_MOYDmax_Nig_month_tmp2.tif -o   $OUT/LST_MOYDmax_Nig_month.tif

rm -f $OUT/tmp/*   $OUT/LST_MOYDmax_Nig_month_tmp2.tif  $OUT/LST_MOYDmax_Nig_month_tmp.tif
  