
# script che funziona deve essere un po miglirato per tenerlo in stand alone. 
# converte una striscia shp in determinata projection e calcola l'area e riproduce la colonna n volte. 
 
#    SR-ORG:28: lambert azimutha equal area
#     SR-ORG:6842: MODIS Sinusoidal
#     SR-ORG:6965: MODIS Sinusoidal
#     SR-ORG:6974: MODIS Sinusoidal



for prj in 28 6842 6965 6974 ; do

# create asc file 100 pixel large.

echo "ncols        100"                          > GMTED2010_30arc-sec-AreaCol_prj$prj.asc 
echo "nrows        21600"                       >> GMTED2010_30arc-sec-AreaCol_prj$prj.asc 
echo "xllcorner    -180"                        >> GMTED2010_30arc-sec-AreaCol_prj$prj.asc 
echo "yllcorner    -90"                         >> GMTED2010_30arc-sec-AreaCol_prj$prj.asc 
echo "cellsize     0.008333333333333333333"     >> GMTED2010_30arc-sec-AreaCol_prj$prj.asc 

awk '{ if ($1>0) {for (ncols=1 ; ncols<=100 ; ncols++) { printf ("%i ",int($1)) } ; printf ("\n") } }'  matrix_area_prj$prj.asc  >> GMTED2010_30arc-sec-AreaCol_prj$prj.asc 
gdal_translate -ot UInt32 -co COMPRESS=LZW  -a_srs  GMTED2010_30arc-sec.prj  GMTED2010_30arc-sec-AreaCol_prj$prj.asc GMTED2010_30arc-sec-AreaCol_prj$prj.tif 

# shift the GMTED2010_30arc-sec-AreaCol.tif   evry 100 pixel 

done 



for prj in 28 6842 6965 6974 ; do
mv  GMTED2010_30arc-sec-AreaCol_prj$prj.tif   GMTED2010_30arc-sec-AreaCol_prj.tif 

seq 1 432 | xargs -n 1 -P 2 bash -c $' 
n=$1
ulx=$(awk -v n=$n  \'BEGIN { print -180 + (0.008333333333333333333 * n * 100)}\')
lrx=$(awk -v n=$n  \'BEGIN { print -180 + (0.008333333333333333333 * (n + 1 ) * 100 )}\')
gdal_translate -ot UInt32 -a_ullr $ulx +90 $lrx -90 GMTED2010_30arc-sec-AreaCol_prj.tif tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif
' _ 

echo merging $prj

cp  GMTED2010_30arc-sec-AreaCol_prj.tif   tif_col/GMTED2010_30arc-sec-AreaCol_shift0.tif


rm  GMTED2010_30arc-sec-AreaCol_merge?.tif  

gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge0.tif $(for n in `seq 0 107`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge1.tif  $(for n in `seq 108 216`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)   
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge2.tif  $(for n in `seq 217 324`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)   
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge3.tif  $(for n in `seq 325 431`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)    

gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge0.tif  GMTED2010_30arc-sec-AreaCol_merge0c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge1.tif  GMTED2010_30arc-sec-AreaCol_merge1c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge2.tif  GMTED2010_30arc-sec-AreaCol_merge2c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge3.tif  GMTED2010_30arc-sec-AreaCol_merge3c.tif

gdal_merge.py -co COMPRESS=LZW -o  GMTED2010_30arc-sec-AreaCol_merge_prj$prj.tif      GMTED2010_30arc-sec-AreaCol_merge[0-3]c.tif    

done 



mv GMTED2010_30arc-sec-AreaCol_merge_prj28.tif    30arc-sec-Area_prj28.tif
mv GMTED2010_30arc-sec-AreaCol_merge_prj6842.tif  30arc-sec-Area_prj6842.tif
mv GMTED2010_30arc-sec-AreaCol_merge_prj6965.tif  30arc-sec-Area_prj6965.tif
mv GMTED2010_30arc-sec-AreaCol_merge_prj6974.tif  30arc-sec-Area_prj6974.tif
mv GMTED2010_30arc-sec-AreaCol_merge.tif          30arc-sec-Area_prjR.tif