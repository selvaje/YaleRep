# seq 1 21600 | xargs -n  1 -P 1  bash create_run.sh   

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

