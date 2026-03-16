# Create W E  geo referenced tif with ID value.
# Uper Left corner id = 1 Lower Right  43200  *  21600  =   933120000 
# Merge action not performed due to huge size of the generated tif.

echo "ncols        21600"                         >  geo_reference_W.asc 
echo "nrows        21600"                         >> geo_reference_W.asc 
echo "xllcorner    -180"                          >> geo_reference_W.asc 
echo "yllcorner    -90"                             >> geo_reference_W.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_W.asc 


awk ' BEGIN {  
 for (row=1 ; row<=21600 ; row++)  { 
      for (col=1 ; col<=21600 ; col++) { 
          printf ("%i " ,   (21600*(row-1))+col+((row-1)*21600)   ) } ; printf ("\n")  }}' >> geo_reference_W.asc 
gdal_translate -ot UInt32  -a_srs EPSG:4326   -co "COMPRESS=LZW"  -co ZLEVEL=9    geo_reference_W.asc  geo_reference_W.tif



echo "ncols        21600"                         >  geo_reference_E.asc 
echo "nrows        21600"                         >> geo_reference_E.asc 
echo "xllcorner    0"                             >> geo_reference_E.asc 
echo "yllcorner    -90"                           >> geo_reference_E.asc 
echo "cellsize     0.008333333333333333333"       >> geo_reference_E.asc 

awk ' BEGIN {  
 for (row=1 ; row<=21600 ; row++)  { 
      for (col=1 ; col<=21600 ; col++) { 
          printf ("%i " , (21600*row)+col+((row-1)*21600)   ) } ; printf ("\n")  }}' >> geo_reference_E.asc 
gdal_translate -ot UInt32  -a_srs EPSG:4326   -co "COMPRESS=LZW"  -co ZLEVEL=9    geo_reference_E.asc  geo_reference_E.tif

