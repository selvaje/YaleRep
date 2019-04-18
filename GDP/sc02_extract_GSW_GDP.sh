

export GDP=/project/fas/sbsc/ga254/dataproces/GDP/input

for YEAR in 1998 1999 2000 2001  $(seq 2004 2014 )    ; do
export YEAR
export YEARB=$( expr $YEAR + 1 ) 
echo  1 2 3 4 5 6 7 8   | xargs -n 1 -P 4 bash -c $'
BUF=$1 
geo_string=$( oft-bb /gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp/buffer_point_tif_crop.tif $BUF  | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\')

echo $geo_string

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string /gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp/buffer_point_tif_crop.tif $GDP/buffer${BUF}_point_tif_crop.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $GDP/buffer${BUF}_point_tif_crop.tif) /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSW/brahmaputra/brahmaputra${YEARB}_ct.tif  $GDP/brahmaputra${YEAR}_buf$BUF.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $GDP/buffer${BUF}_point_tif_crop.tif) $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000.tif  $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf$BUF.tif

pksetmask -m /gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp/buffer_point_tif_crop.tif -msknodata $BUF -p ! -nodata 0 \
-i $GDP/brahmaputra${YEAR}_buf$BUF.tif  -o $GDP/brahmaputra${YEAR}_buf${BUF}msk.tif

oft-stat-sum  -i   $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf$BUF.tif  -o   $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${BUF}_year${YEAR}.txt  -um $GDP/brahmaputra${YEAR}_buf${BUF}msk.tif 

awk -v YEAR=$YEAR \'{ if ($1==1 ) print YEAR ,  $2, int($3)   }\'  $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${BUF}_year${YEAR}.txt  >  $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${BUF}_year${YEAR}_exp1.txt  

rm  -f $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${BUF}_year${YEAR}.txt   $GDP/buffer${BUF}_point_tif_crop.tif $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf$BUF.tif $GDP/brahmaputra${YEAR}_buf${BUF}msk.tif  $GDP/brahmaputra${YEAR}_buf$BUF.tif

' _
done

echo  1 2 3 4 5 6 7 8   | xargs -n 1 -P 4 bash -c $'
cat   $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${1}_year????_exp1.txt >   $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${1}_year_exp1.txt 
' _ 



for P in 1 2 3 4 5 6 7 8 ; do 
join -1 1 -2 1    /project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/extract_flo1k/point${P}_year_flo1k_oc0_oc1_oc2_oc3.txt $GDP/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000_buf${P}_year_exp1.txt | awk '{ print $1 "," $2 ","    $7 * ( 0.768844 / 900)  "," $8  }'  > $GDP/point${P}_year_flo1k_ocKM2_GDP.txt 
done 




