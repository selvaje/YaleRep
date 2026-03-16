

library(sp)
library(raster)
library(maptools)
shp=readShapePoly("/home/selv/geo_area/poly_10800.shp") 
rast=raster("GMTED2010_30arc-sec-IDcol-proj_10800clip1.tif")
