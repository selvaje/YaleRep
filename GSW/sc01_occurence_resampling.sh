# bsub -W 24:00 -M 30000 -R "rusage[mem=30000]" -R "span[hosts=1]" -n 10  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_occurence_resampling.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_occurence_resampling.sh.%J.err   bash  /gpfs/home/fas/sbsc/ga254/scripts/GSW/sc01_occurence_resampling.sh


# Size is 40000, 40000
# pixel size GWS  0.000250000000000 
#
#   0.002083333333333     = 7.5 arc sec   = 250m
#   0.002083333333333 / 8 =   0.000260417  # this allow the aggregation at 8 * 8 and rich the 250 
# 504 file 

export OCC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSW/input/occurrence
export RAM=/dev/shm

cleanram 

ls $OCC/occurrence_*_*.tif    | xargs -n 1  -P 10 bash -c $'  
file=$1
filename=$(basename $file .tif )
gdalbuildvrt -overwrite -te  $(getCorners4Gwarp  $file  | awk \'{  print $1 - 1 , $2 - 1 , $3 + 1 , $4 + 1   }\'  )  $RAM/$filename.vrt $OCC/occurrence_*_*.tif
gdalwarp -overwrite -srcnodata 255 -dstnodata  255 -of GTiff  -overwrite   -te  $(getCorners4Gwarp  $file ) -co COMPRESS=DEFLATE -co ZLEVEL=9  -tr 0.0020833333333333333333  0.0020833333333333333333  -r bilinear  $RAM/$filename.vrt  $RAM/$filename.tif 
gdalwarp -overwrite -co COMPRESS=DEFLATE -co ZLEVEL=9   -of GTiff -srcnodata 0 -dstalpha  $RAM/$filename.tif  $RAM/${filename}_tr.tif  
rm -f  $RAM/$filename.vrt 
' _ 

echo start to merege the 250 file 

gdalbuildvrt -overwrite  -te -180 -60 180 84     $RAM/occurrence_250.vrt    $RAM/occurrence_*_*{N,S}.tif 
gdal_translate -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/occurrence_250.vrt   $OCC/../occurrence_250m.tif

rm   $RAM/occurrence_*_*{N,S}.tif 

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 0.5  -max 110    -data 1 -nodata  0  -i  $OCC/../occurrence_250m.tif -o  $OCC/../occurrence_250m_mksk0-1.tif
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -min -1  -max 110     -data 0 -nodata  255  -i  $OCC/../occurrence_250m.tif -o  $OCC/../occurrence_250m_mksk0-255.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m  $OCC/../occurrence_250m.tif  -msknodata  255  -nodata 255   -i $OCC/../occurrence_250m_mksk0-1.tif  -o  $OCC/../occurrence_250m_mksk0-1-255.tif  # da controllare il 255 non appare.

gdalbuildvrt -overwrite  -te -180 -60 180 84     $RAM/occurrence_250.vrt    $RAM/occurrence_*_*{N,S}_tr.tif  
gdal_translate -of GTiff   -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/occurrence_250.vrt   $OCC/../occurrence_250m_tr.tif

cleanram 