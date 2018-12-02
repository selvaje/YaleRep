#  bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc01_bin_1k.sh 
#  bsub -W 24:00 -n 8 -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_bin_1k.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_bin_1k.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc01_bin_1k.sh 

export DIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0

gdalwarp -overwrite -te -180 -60 +180 +80 -tr 0.00833333333333333 0.00833333333333333 -wo NUM_THREADS=8 -wm 4000 -srcnodata -3.4028234663852886e+3 -dstnodata "None"  -t_srs EPSG:4326 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0.tif $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif -msknodata 0 -p '<' -nodata 0 -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_tmp.tif
gdal_edit.py -a_nodata -1   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_tmp.tif
mv  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_tmp.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif


oft-calc -ot Byte $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84.tif $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin.tif <<EOF
1
#1 0.05 + 10 * 1 -
EOF

pkcreatect -min 0 -max 9 > /tmp/color.txt 

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct  /tmp/color.txt -m  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin.tif -msknodata 10 -nodata 9  -i   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin.tif -o   ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif
gdal_edit.py -a_nodata -1   ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif

rm  -f  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin.tif 

echo start the clump operation 

echo  1 2 3 4 5 6 7 8 9  | xargs -n 1 -P 8 bash -c $' 

MIN=$( echo $1 - 0.5 | bc )
BIN=$1

echo masking the bin 

pkgetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -min $MIN  -max 9.5  -data 1 -nodata 0 -ct  /tmp/color.txt  -i ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_ct.tif -o ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin$BIN.tif 
gdal_edit.py -a_nodata 0   ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin$BIN.tif  

rm -fr  ${DIR}_bin/grassdb_1k/loc_clump$BIN                                                                        
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2.sh  ${DIR}_bin/grassdb_1k  loc_clump$BIN ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin$BIN.tif 

r.clump -d  --overwrite    input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin$BIN     output=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump
r.colors -r map=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin$BIN

r.out.gdal nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump  output=${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif 
rm -rf ${DIR}_bin/grassdb_1k/loc_clump$BIN

bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_random_color.txt 

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_random_color.txt  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_ct.tif
gdal_edit.py -a_nodata 0  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_ct.tif

rm -f  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump_random_color.txt ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif.aux.xml

' _  

rm -f /tmp/color.txt 

bsub  -W 08:00  -n 8  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_core.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_core.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc02_core_1k_250.sh 1k
