

gdal3
module load R/3.5.3-foss-2018a-X11-20180131



library(automap)
library(rgdal)
RMSE <- read.csv("~/tmp/tmp/RMSE_map.csv", header=T)
coordinates(RMSE) =~ Long+Lat
proj4string(RMSE) <- CRS("+init=epsg:4326")
RMSE_meter <- spTransform(RMSE,CRS("+proj=eqdc +lat_0=39 +lon_0=-96 +lat_1=33 +lat_2=45 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs"))
  
variogram = autofitVariogram(RMSE~1,RMSE)
plot(variogram)

