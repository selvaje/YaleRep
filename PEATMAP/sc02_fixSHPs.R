##### Fixing South America shapefiles

library(sf)

setwd("/home/jaime/Data/PEATMAP/SHP/South_America")

### run in server3
sa = st_read("SA_Peatland.shp")

# identify the largest (multi)polygons giving trouble
# head(sort(ss$AREA, decreasing=T), 10)
# which.max(ss$AREA)

##  create new shape removing the trouble makers
ss = sa[-c(3113,3112,3111),]
st_write(ss, "SA_Peatland_01.shp")

## Promote from multi to Polygon and save
s1 = sa[3113,]
# dim(s1)
ncmp = st_cast(s1,"POLYGON")
# dim(ncmp)
# calculate area again to fix old value
ncmp$AREA = st_area(ncmp)
st_write(ncmp, "SA_Peatland_02.shp")

s2 = sa[3112,]
ncmp = st_cast(s2,"POLYGON")
ncmp$AREA = st_area(ncmp)
st_write(ncmp, "SA_Peatland_03.shp")

s3 = sa[3111,]
ncmp = st_cast(s3,"POLYGON")
ncmp$AREA = st_area(ncmp)
st_write(ncmp, "SA_Peatland_04.shp")


## FInally remove the original file
system("rm SA_Peatland.*")

################################################################
##### Fixing Asia shapefile

setwd("/home/jaime/Data/PEATMAP/SHP/Asia")


sa = st_read("SEA_Peatland.shp")
ncmp = st_cast(sa,"POLYGON")
ncmp$AREA = st_area(ncmp)
saf = st_zm(ncmp, what='ZM')
##ogr2ogr -f "ESRI Shapefile" SEA_Peatland_2d.shp SEA_Peatland.shp -dim 2
##ogr2ogr -nlt MULTIPOLYGON SEA_Peatland_2d_multi.shp SEA_Peatland_2d.shp
##ogr2ogr -t_srs EPSG:4326 ../../temp/SEA_Peatland_fixed_RP.shp SEA_Peatland_fixed.shp

st_write(saf, "SEA_Peatland_fixed.shp")

## FInally remove the original file
system("rm SEA_Peatland.*")

################################################################

zip -r South_America.zip South_America

###  copy to grace
scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Data/PEATMAP/SHP/South_America.zip jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP/SHP

scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Data/PEATMAP/temp/SEA_Peatland_fixed_RP* jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP/temp

#
# ogrinfo -so -al SHP/South_America/SA_Peatland.shp
#
# ogr2ogr -nlt POLYGON SHP/South_America/SA_Peatland_POLY.shp SHP/South_America/SA_Peatland.shp
#
# ogr2ogr -f "ESRI Shapefile" -dialect sqlite -sql "SELECT * FROM SA_Peatland ORDER BY Area ASC LIMIT 5 OFFSET 0" batch_1.shp SA_Peatland.shp
#
# ogr2ogr -f "ESRI Shapefile" -dialect sqlite -sql "select * from my_shape limit 10000 offset 10000" batch_2.shp my_shape.shp
#
# ogr2ogr -f "ESRI Shapefile" -dialect sqlite -sql "select * from my_shape limit 10000 offset 20000" batch_3.shp my_shape.shp
