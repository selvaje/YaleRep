# /lustre/scratch/client/fas/sbsc/ga254/dataproces/GEO_AREA/tif_ID

echo "ncols        43200"       >  raster_north.asc 
echo "nrows        10800"       >> raster_north.asc 
echo "xllcorner    -180"         >> raster_north.asc 
echo "yllcorner    0"         >> raster_north.asc 
echo "cellsize     0.00833333333333333"      >> raster_north.asc 


awk ' BEGIN {  
for (row=1 ; row<=10800 ; row++)  { 
     for (col=1 ; col<=43200 ; col++) { 
         printf ("%i " ,  col+(row-1)*43200  ) } ; printf ("\n")  }}' >> raster_north.asc 

gdal_translate  -ot  UInt32 -co  COMPRESS=LZW -co ZLEVEL=9  raster_north.asc raster_north.tif



echo "ncols        43200"       >  raster_south.asc 
echo "nrows        10800"       >> raster_south.asc 
echo "xllcorner    -180"         >> raster_south.asc 
echo "yllcorner    -90"         >> raster_south.asc 
echo "cellsize     0.00833333333333333"      >> raster_south.asc 

awk ' BEGIN {  
for (row=1 ; row<=10800 ; row++)  { 
     for (col=1 ; col<=43200 ; col++) { 
         printf ("%i " ,  466560000  +  (col+(row-1)*43200)  ) } ; printf ("\n")  }}' >> raster_south.asc 


# transform the created arcinfo ascii grid in a tif.
 
gdal_translate  -ot  UInt32 -co  COMPRESS=LZW -co ZLEVEL=9  raster_south.asc   raster_south.tif

gdalbuildvrt      -te -180  -90  180 90       -overwrite  glob_ID_rast.vrt    raster_north.tif   raster_south.tif
gdal_translate  -co  COMPRESS=LZW -co ZLEVEL=9   glob_ID_rast.vrt   glob_ID_rast.tif 

gdal_translate        -co PREDICTOR=2  -co  COMPRESS=LZW -co ZLEVEL=9     glob_ID_rast.tif      glob_ID_rast_super_compres.tif

# create 50x50 constant 1km  and so on for 100 and 10 

echo  10 50 100  |  xargs -n 1 -P 3 bash -c $' 
SIZE=$1
# pkfilter -ot UInt32 -co COMPRESS=DEFLATE  -co ZLEVEL=9 -dx ${SIZE} -dy ${SIZE} -f min -d ${SIZE} -i /lustre/scratch/client/fas/sbsc/ga254/dataproces/GEO_AREA/tif_ID/glob_ID_rast_super_compres.tif -o /lustre/scratch/client/fas/sbsc/ga254/dataproces/GEO_AREA/tif_ID/glob_ID${SIZE}x_rast.tif
gdalwarp -tr 0.00833333333333333 0.00833333333333333 -r near -co COMPRESS=DEFLATE -co ZLEVEL=9 /lustre/scratch/client/fas/sbsc/ga254/dataproces/GEO_AREA/tif_ID/glob_ID${SIZE}x_rast.tif /lustre/scratch/client/fas/sbsc/ga254/dataproces/GEO_AREA/tif_ID/glob_ID${SIZE}x_rast_1km.tif

' _ 

