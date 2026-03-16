# Create an header with the geographic extend and the pixel resolution
# pixel value = 1
# ncols  43200  *  nrows 21600 

# Create Quarter tif  NW NE SW SE

echo "ncols        21600"                         >  geo_reference_NW.asc 
echo "nrows        10800"                         >> geo_reference_NW.asc 
echo "xllcorner    -180"                          >> geo_reference_NW.asc 
echo "yllcorner    0"                             >> geo_reference_NW.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_NW.asc 


echo "ncols        21600"                         >  geo_reference_NE.asc 
echo "nrows        10800"                         >> geo_reference_NE.asc 
echo "xllcorner    0"                             >> geo_reference_NE.asc 
echo "yllcorner    0"                             >> geo_reference_NE.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_NE.asc 

echo "ncols        21600"                         >  geo_reference_SW.asc 
echo "nrows        10800"                         >> geo_reference_SW.asc 
echo "xllcorner    -180"                          >> geo_reference_SW.asc 
echo "yllcorner    -90"                           >> geo_reference_SW.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_SW.asc 


echo "ncols        21600"                         >  geo_reference_SE.asc 
echo "nrows        10800"                         >> geo_reference_SE.asc 
echo "xllcorner    0"                             >> geo_reference_SE.asc 
echo "yllcorner    -90"                           >> geo_reference_SE.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_SE.asc 


# Attach to the same file a matrix with id increasing number starting from 1 in Upper Left corner.

for quorter in NW NE SW SE ; do 
awk ' BEGIN {  
 for (row=1 ; row<=10800 ; row++)  { 
      for (col=1 ; col<=21600 ; col++) { 
          printf ("%i " ,  "1"  ) } ; printf ("\n")  }}' >> geo_reference_$quorter.asc 
# transform the created arcinfo ascii grid in a tif.
gdal_translate -ot Byte  -a_srs EPSG:4326   -co "COMPRESS=LZW"  -co ZLEVEL=9   geo_reference_$quorter.asc  geo_reference_$quorter.tif
done 

# Merge the tif 
rm -f geo_reference.tif
gdal_merge.py  -ot Byte -co "COMPRESS=LZW"  -co ZLEVEL=9   -o  geo_reference_tmp.tif  geo_reference_??.tif  
gdal_translate -ot Byte -co "COMPRESS=LZW"   -co ZLEVEL=9     geo_reference_tmp.tif  geo_reference.tif  
rm geo_reference_tmp.tif




