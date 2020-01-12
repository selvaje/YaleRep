#Goal is to make kernel density map from coordinates, with dimensions below
#extent      : -113.5, -79, 24, 36.5  (xmin, xmax, ymin, ymax)
#dimensions  : 1500, 4140, 6210000  (nrow, ncol, ncell)
#projection : stored in crs.geo
#See GPP or other surface for example

setwd("/Users/owl_esp/Desktop/transfer_to_grace/NAm_RF_3/sc12C/3iterations")
load("LinFSTData_withGeoDistFull_Run1.RData")

#or you can also use the list of points I attached. it also has the lat and long info

#https://www.samuelbosch.com/2014/02/creating-kernel-density-estimate-map-in.html

library("KernSmooth")
library("raster")

# compute the 2D binned kernel density estimate
#ask Giuseppe about gridsize and range.x?
coordinates <- P.table[,3:2]

est <- bkde2D(coordinates, 
              bandwidth=c(2,2), 
              gridsize=c(4140,1500),
              range.x=list(c(-113.5,-79),c(24,36.5)))

#so far I'm skipping this step
#tried with and without this step
est$fhat[est$fhat<0.00001] <- 0 ## ignore very small values

# create raster
est.raster = raster(list(x=est$x1,y=est$x2, z=est$fhat))
projection(est.raster) <- crs.geo
xmin(est.raster) <- -113.5
xmax(est.raster) <- -79
ymin(est.raster) <- 24
ymax(est.raster) <- 36.5
# visually inspect the raster output
plot(est.raster)



