rm  matrix_area.asc 
for n in `seq 1 21600` ; do  
    echo $n `cat area_ID/area_$n.txt` >> matrix_area.asc 
done 

# create asc file 100 pixel large.

echo "ncols        100"                            > GMTED2010_30arc-sec-AreaCol.asc 
echo "nrows        21600"                       >> GMTED2010_30arc-sec-AreaCol.asc 
echo "xllcorner    -180"                        >> GMTED2010_30arc-sec-AreaCol.asc 
echo "yllcorner    -90"                         >> GMTED2010_30arc-sec-AreaCol.asc 
echo "cellsize     0.008333333333333333333"     >> GMTED2010_30arc-sec-AreaCol.asc 

awk '{ if ($2>0) { for (ncols=1 ; ncols<=100 ; ncols++) { printf ("%i ", int($2)) } ; printf ("\n") } }'  matrix_area.asc    >> GMTED2010_30arc-sec-AreaCol.asc 
gdal_translate  -ot UInt32  -a_srs  GMTED2010_30arc-sec.prj  GMTED2010_30arc-sec-AreaCol.asc GMTED2010_30arc-sec-AreaCol.tif 

# shift the GMTED2010_30arc-sec-AreaCol.tif   evry 100 pixel 

seq 1 432 | xargs -n 1 -P 6 bash -c $' 
n=$1
ulx=$(awk -v n=$n  \'BEGIN { print -180 + (0.008333333333333333333 * n * 100)}\')
lrx=$(awk -v n=$n  \'BEGIN { print -180 + (0.008333333333333333333 * (n + 1 ) * 100 )}\')
gdal_translate -ot Float32 -a_ullr $ulx  +90  $lrx -90    GMTED2010_30arc-sec-AreaCol.tif tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif
' _ 


cp  GMTED2010_30arc-sec-AreaCol.tif tif_col/GMTED2010_30arc-sec-AreaCol_shift0.tif


rm  GMTED2010_30arc-sec-AreaCol_merge?.tif  

gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge0.tif $(for n in `seq 0 107`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge1.tif  $(for n in `seq 108 216`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)   
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge2.tif  $(for n in `seq 217 324`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)   
gdal_merge.py -co COMPRESS=LZW  -o  GMTED2010_30arc-sec-AreaCol_merge3.tif  $(for n in `seq 325 431`; do echo tif_col/GMTED2010_30arc-sec-AreaCol_shift$n.tif ; done)    

gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge0.tif  GMTED2010_30arc-sec-AreaCol_merge0c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge1.tif  GMTED2010_30arc-sec-AreaCol_merge1c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge2.tif  GMTED2010_30arc-sec-AreaCol_merge2c.tif
gdal_translate -co COMPRESS=LZW   GMTED2010_30arc-sec-AreaCol_merge3.tif  GMTED2010_30arc-sec-AreaCol_merge3c.tif

gdal_merge.py -co COMPRESS=LZW -o  GMTED2010_30arc-sec-AreaCol_merge.tif      GMTED2010_30arc-sec-AreaCol_merge[0-3]c.tif    





