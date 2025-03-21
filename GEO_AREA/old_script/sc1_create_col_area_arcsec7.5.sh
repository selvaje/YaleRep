cd  /home/selv/geo_area 
# create a tif whith one column 

# una colonna di numeri 
echo "ncols        1"                   > asc/GMTED2010_75arc-sec-IDcol.asc
echo "nrows        86400"              >> asc/GMTED2010_75arc-sec-IDcol.asc
echo "xllcorner    -180"               >> asc/GMTED2010_75arc-sec-IDcol.asc
echo "yllcorner    -90"                 >> asc/GMTED2010_75arc-sec-IDcol.asc
echo "cellsize     0.00208333333333333333333"     >> asc/GMTED2010_75arc-sec-IDcol.asc

awk ' BEGIN {  
for (row=1 ; row<=86400 ; row++)  { 
     for (col=1 ; col<=1 ; col++) { 
         printf ("%i " ,  col+(row-1)*1  ) } ; printf ("\n")  }}' >> asc/GMTED2010_75arc-sec-IDcol.asc

gdal_translate -ot UInt16   asc/GMTED2010_75arc-sec-IDcol.asc    tif_col/GMTED2010_75arc-sec-IDcol.tif 
gdalwarp -overwrite -t_srs prj/GMTED2010_30arc-sec.prj  tif_col/GMTED2010_75arc-sec-IDcol.tif tif_col/GMTED2010_75arc-sec-IDcol-proj.tif

rm shp/GMTED2010_75arc-sec-IDcol-proj.{shp,dbf,prj,shx}
gdal_polygonize.py   -f  "ESRI Shapefile" tif_col/GMTED2010_75arc-sec-IDcol-proj.tif  shp/GMTED2010_75arc-sec-IDcol-proj.shp


seq 1 21600 | xargs -n  1 -P 6  bash  sc2_create_poly_area.sh

exit

# questo sistema sotto non importa la variabile n dentro r pertanto si fa correre il seq 1 21600 | xargs -n  1 -P 4  bash  sc2_create_poly_area.sh

seq 1 4 | xargs -n  1 -P 1  bash -c ' 

n=$1
echo  "################# poly $n ################# "

pkgetmask  -ot  Byte -min $n  -max $n -t 1   -f  0     -i  GMTED2010_30arc-sec-IDcol-proj.tif  -o  GMTED2010_30arc-sec-IDcol-proj_$n.tif
rm  -f GMTED2010_30arc-sec-IDcol-proj_$n.{shp,dbf,prj,shx}
gdal_polygonize.py   -f  "ESRI Shapefile"  GMTED2010_30arc-sec-IDcol-proj_$n.tif  GMTED2010_30arc-sec-IDcol-proj_$n.shp
rm -f poly_$n.*
ogr2ogr  -where "DN = 1"  poly_$n.shp   GMTED2010_30arc-sec-IDcol-proj_$n.shp  
rm -f GMTED2010_30arc-sec-IDcol-proj_$n.shp

export n=$1

R --no-save  --slave  -q <<EOF

library (geosphere)
library (rgdal)
n=Sys.getenv('n')

library(geosphere)

poly =  readOGR(paste("poly_",n,".shp",sep="") , paste("poly_",n,sep="")  )
areaPolygon(poly)
write.table (areaPolygon(poly)[1] ,paste("area_ID/area_",n,".txt",sep="" ) ,row.names = F , col.names = F)

EOF
rm   poly_$n.*   GMTED2010_30arc-sec-IDcol-proj_$n.*
' _

