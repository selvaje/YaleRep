
# script che funziona deve essere un po miglirato per tenerlo in stand alone. 
# converte una striscia shp in determinata projection e calcola l'area e riproduce la colonna n volte. 
 
#    SR-ORG:28: lambert azimutha equal area
#     SR-ORG:6842: MODIS Sinusoidal
#     SR-ORG:6965: MODIS Sinusoidal
#     SR-ORG:6974: MODIS Sinusoidal


# create a tif whith one column 
# una colonna di numeri 

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Tools/PKTOOLS/2.4.2
module load Libraries/OSGEO/1.10.0


export INDIR=/home2/ga254/scratch/dem_bj/GEO_AREA

echo "ncols        1"                              > $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc
echo "nrows        86400"                         >> $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc
echo "xllcorner    -180"                          >> $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc
echo "yllcorner    -90"                           >> $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc
echo "cellsize     0.00208333333333333333333"     >> $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc

awk ' BEGIN {  
for (row=1 ; row<=86400 ; row++)  { 
     for (col=1 ; col<=1 ; col++) { 
         printf ("%i " ,  col+(row-1)*1  ) } ; printf ("\n")  }}' >> $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc

gdal_translate -ot UInt32  -a_srs $INDIR/prj/GMTED2010_30arc-sec.prj $INDIR/asc/GMTED2010_75arc-sec-IDcol.asc    $INDIR/tif_col/GMTED2010_75arc-sec-IDcol.tif 



# transform to shp and calculate the area

rm $INDIR/shp/GMTED2010_75arc-sec-IDcol.{shp,dbf,prj,shx}
gdal_polygonize.py   -f  "ESRI Shapefile" $INDIR/tif_col/GMTED2010_75arc-sec-IDcol.tif  $INDIR/shp/GMTED2010_75arc-sec-IDcol.shp


# change projection and calculate the area

rm $INDIR/shp/GMTED2010_75arc-sec-IDcol-proj[1-9]*.*

echo  28 6842 6965 6974 | xargs -n 1 -P 4 bash -c $' 
    prj=$1 
    echo change proj wgs84 to $prj
    ogr2ogr -t_srs $INDIR/prj/$prj.prj $INDIR/shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp $INDIR/shp/GMTED2010_75arc-sec-IDcol.shp  
    $INDIR/scripts/addattr-area.py  $INDIR/shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp Area
    ogrinfo -al  $INDIR/shp/GMTED2010_75arc-sec-IDcol-proj$prj.shp | grep Area | awk \'{ if (NF==4) print $4 }\'  > $INDIR/asc/matrix_area_prj$prj.asc
' _ 



# use the column matrix to create asi file and shift it 
# final tif 172800 *  86400 

echo  28 6842 6965 6974 | xargs -n 1 -P 4 bash -c $' 

prj=$1

# create asc file 100 pixel large.

echo "ncols        8640"                         > $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 
echo "nrows        86400"                       >> $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 
echo "xllcorner    -180"                        >> $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 
echo "yllcorner    -90"                         >> $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 
echo "cellsize     0.00208333333333333333333"     >> $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 

awk \'{if($1>0){for(ncols=1;ncols<=8640;ncols++) {printf("%i ",int($1))}; printf ("\\n")}}\' asc/matrix_area_prj$prj.asc  >> $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc 

gdal_translate -ot UInt32 -co COMPRESS=LZW  -a_srs  $INDIR/prj/GMTED2010_30arc-sec.prj   $INDIR/asc/GMTED2010_75arc-sec-AreaCol_prj$prj.asc $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_prj$prj.tif 

' _ 



# shift the GMTED2010_75arc-sec-AreaCol.tif   evry 8640  pixel 

for prj in  28 6842 6965 6974 ; do 

prj=28
cp   $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_prj$prj.tif    $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_prj.tif 

seq 1 20 | xargs -n 1 -P 20 bash -c $' 
n=$1
ulx=$(awk -v n=$n  \'BEGIN { print -180 + (0.00208333333333333333333 * n * 8640)}\')
lrx=$(awk -v n=$n  \'BEGIN { print -180 + (0.00208333333333333333333 * (n + 1 ) * 8640 )}\')
gdal_translate  -co COMPRESS=LZW -ot UInt32 -a_ullr $ulx +90 $lrx -90  $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_prj.tif  $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_shift$n.tif

' _  

echo merging $prj

cp  $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_prj.tif   $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_shift0.tif

rm  -f  $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_merge?.tif  

gdal_merge_bylines.py -co COMPRESS=LZW  -o $INDIR/area_tif/75arc-sec-Area_prj28.tif  $(for n in `seq 0 20`; do echo $INDIR/tif_col/GMTED2010_75arc-sec-AreaCol_shift$n.tif ; done)

done 



mv GMTED2010_75arc-sec-AreaCol_merge_prj28.tif    75arc-sec-Area_prj28.tif
mv GMTED2010_75arc-sec-AreaCol_merge_prj6842.tif  75arc-sec-Area_prj6842.tif
mv GMTED2010_75arc-sec-AreaCol_merge_prj6965.tif  75arc-sec-Area_prj6965.tif
mv GMTED2010_75arc-sec-AreaCol_merge_prj6974.tif  75arc-sec-Area_prj6974.tif
mv GMTED2010_75arc-sec-AreaCol_merge.tif          75arc-sec-Area_prjR.tif
