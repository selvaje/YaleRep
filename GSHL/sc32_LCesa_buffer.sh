#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc32_LCesa_buffer.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc32_LCesa_buffer.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc32_LCesa_buffer.sh

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc32_LCesa_buffer.sh 

export    BUF=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin/LST_plot_buf
export    LCESA=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/LCESA
export    LST=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin
export    LST_MAX=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/LST_max
export    RAM=/dev/shm


echo Madrid     -3.705310  40.409888 >  $BUF/city.txt
echo London     -0.114860  51.514306 >> $BUF/city.txt
echo Birminghan -1.909066  52.483376 >> $BUF/city.txt
echo Paris       2.311222  48.855701 >> $BUF/city.txt
echo Lyon        4.841879  45.741073 >> $BUF/city.txt
echo Barcelona   2.171079  41.404551 >> $BUF/city.txt
echo Lisbon     -9.142181  38.725270 >> $BUF/city.txt
echo Milan       9.179801  45.463652 >> $BUF/city.txt 
echo Roma       12.496749  41.888596 >> $BUF/city.txt
echo Palermo    13.356540  38.119028 >> $BUF/city.txt
echo Athene     23.725916  37.953777 >> $BUF/city.txt
echo Dusseldorf  6.810924  51.217426 >> $BUF/city.txt
echo Munchen    11.574068  48.137742 >> $BUF/city.txt
echo Amesterdam  4.893276  52.351364 >> $BUF/city.txt


cat   $BUF/city.txt     | xargs -n 3 -P 1  bash -c $' 

echo $1 $( gdallocationinfo  -geoloc -wgs84 -valonly   $LCESA/LC190_Y2014_1km_clump.tif  $2 $3  ) 

' _  > $BUF/city_bin6ID.txt  


cat   $BUF/city.txt     | xargs -n 3 -P 8  bash -c $' 

CLUMPID=$( gdallocationinfo  -geoloc -wgs84 -valonly   $LCESA/LC190_Y2014_1km_clump.tif  $2 $3  ) 


pkgetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $( echo $CLUMPID - 0.5 | bc )  -max $( echo $CLUMPID + 0.5 | bc  ) -data 1 -nodata 0  -i  $LCESA/LC190_Y2014_1km_clump.tif -o  $BUF/LC190_Y2014_1km_clump$CLUMPID.tif 

geo_string=$(oft-bb    $BUF/LC190_Y2014_1km_clump$CLUMPID.tif  1 | grep BB | awk \'{ print $6-100,$7-100,$8-$6+1+200,$9-$7+1+200 }\')
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string   $BUF/LC190_Y2014_1km_clump$CLUMPID.tif    $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop.tif

rm -rf  $BUF/cost1k_clump${CLUMPID}
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh   $BUF  cost1k_clump${CLUMPID}   $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop.tif  r.in.gdal

r.buffer  input=LC190_Y2014_1km_clump${CLUMPID}_crop   output=LC190_Y2014_1km_clump${CLUMPID}_crop_buf   distances=1,2,3,4,5,6 units=kilometers
r.info  LC190_Y2014_1km_clump${CLUMPID}_crop_buf
r.mapcalc  " LC190_Y2014_1km_clump${CLUMPID}_crop_bufEXT  =  ( 7 -  LC190_Y2014_1km_clump${CLUMPID}_crop_buf  ) "  

r.mapcalc  " LC190_Y2014_1km_clump${CLUMPID}_cropINV =  if ( isnull(LC190_Y2014_1km_clump${CLUMPID}_crop), 1 , null() ) "   

r.buffer  input=LC190_Y2014_1km_clump${CLUMPID}_cropINV   output=LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTtmp   distances=1,2,3,4   units=kilometers

r.info LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTtmp

r.mapcalc  " LC190_Y2014_1km_clump${CLUMPID}_crop_bufINT  =    if ( isnull(LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTtmp), 5  , LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTtmp  )  "   

r.recode -d input=LC190_Y2014_1km_clump${CLUMPID}_crop_bufINT   output=LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTrec  rules=- <<EOF
1:1:0:0
2:2:0:0
3:3:1:1
4:4:2:2
5:5:3:3
EOF


r.mapcalc  " LC190_Y2014_1km_clump${CLUMPID}_crop_buf  =  LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTrec  +  LC190_Y2014_1km_clump${CLUMPID}_crop_bufEXT + 1 "   


r.out.gdal -f --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte  format=GTiff nodata=0  input=LC190_Y2014_1km_clump${CLUMPID}_crop_bufEXT    output=$BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_bufEXT.tif
r.out.gdal -f --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte  format=GTiff nodata=0  input=LC190_Y2014_1km_clump${CLUMPID}_crop_bufINTrec    output=$BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_bufINT.tif
r.out.gdal -f --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte  format=GTiff nodata=0  input=LC190_Y2014_1km_clump${CLUMPID}_crop_buf    output=$BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf.tif

pkcreatect   -co COMPRESS=DEFLATE -co ZLEVEL=9    -min 0 -max 9 -i $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf.tif -o $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf_ct.tif

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $(getCorners4Gtranslate $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf_ct.tif) $LST_MAX/LST_MOYDmax_Day_value.tif  $BUF/LST_MOYDmax_Day_value_${CLUMPID}.tif

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m  $BUF/LST_MOYDmax_Day_value_${CLUMPID}.tif -msknodata -9999 -nodata 0 -i $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf_ct.tif -o $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf_ct_msk.tif 

oft-stat -i   $BUF/LST_MOYDmax_Day_value_${CLUMPID}.tif   -o  $BUF/LST_MOYDmax_Day_value_${CLUMPID}.txt   -um $BUF/LC190_Y2014_1km_clump${CLUMPID}_crop_buf_ct_msk.tif   -mm 

awk \'{  print $1 -1 , $2 , int($3) , int($4) , $5 , $6  }\'  $BUF/LST_MOYDmax_Day_value_${CLUMPID}.txt     | sort -k 1,1 -g   >  $BUF/LST_MOYDmax_Day_value_${CLUMPID}_meanLST.txt 
rm  $BUF/LST_MOYDmax_Day_value_${CLUMPID}.txt

' _ 
 
exit 
