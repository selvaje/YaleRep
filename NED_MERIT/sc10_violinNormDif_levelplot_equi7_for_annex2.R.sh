#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_plotNormDif_levelplot_equi7_for_annex2.R.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_plotNormDif_levelplot_equi7_for_annex2.R.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc10_plotDerv_levelplot_equi7_for_annex2.R.sh


# bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_violinNormDif_levelplot_equi7_for_annex2.R.sh

# module load Apps/R/3.3.2-generic

gdal
module load R/3.4.4-foss-2018a-X11-20180131  # new path 

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/

# e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 ) 
# gdal_translate -projwin  6890000 5218400   6910000 5200000    /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_066_048.tif /tmp/test.tif 
# gdalwarp -r bilinear -srcnodata -9999 -dstnodata -9999  -overwrite  -tr 0.00208333333333333333333333333 0.00208333333333333333333333333   -s_srs   $PR/EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj    -t_srs EPSG:4326    -co COMPRESS=DEFLATE -co ZLEVEL=9  /tmp/test.tif  /tmp/test_wgs84.tif

R  --vanilla --no-readline   -q  <<EOF

rm(list = ls())

library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)

# require(rasterVis)

# 34 spazio sopra e sotto 
# 35 spazio sopra e sotto ancora piu largo del 34
# 33 piccolo spazio a destra e sinitstra 

#  x pixel number 120
#  y pixel number 81

e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 ) 

elev_M = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_066_048.tif") 
elev_M = crop   (elev_M , e)

elev_M

elev_N = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_066_048.tif") 
elev_N = crop   (elev_N , e)

elev_N

#  MERIT minus NED  ... positive values are due to not pefect correction of the tree hight 
# elev_dif = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/elevation/tiles/NA_066_048_dif.tif")  
# merit - ned 

elev_dif = elev_N - elev_M

for ( dir in c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspectcosine","aspectsine","eastness","northness")) { 
     raster  <- raster(paste0( dir,"/tiles/","/NA_066_048_dif_norm.tif") ) 
     raster = crop (raster , e)
     raster[raster == -9999 ] <- NA
     value=raster@data@values
     assign(paste0(dir) , raster  )
     assign(paste0("val.",dir) , value  )
}

  dat1 = data.frame(val.elevation)
  dat1$val.roughness = val.roughness
  dat1$val.tri = val.tri
  dat1$val.tpi = val.tpi 
  dat1$val.vrm = val.vrm
  dat1$val.cti = val.cti
  dat1$val.spi = val.spi
  dat1$val.slope = val.slope
  dat1$val.pcurv = val.pcurv
  dat1$val.tcurv = val.tcurv

  dat2 = data.frame(val.dx)
  dat2$val.dy = val.dy
  dat2$val.dxx = val.dxx 
  dat2$val.dyy = val.dyy
  dat2$val.dxy = val.dxy 
  dat2$val.convergence = val.convergence
  dat2$val.aspectcosine =  val.aspectcosine
  dat2$val.aspectsine = val.aspectsine 
  dat2$val.eastness =  val.eastness
  dat2$val.northness = val.northness

mat1 <- reshape2::melt(data.frame(dat1), id.vars = NULL)
mat2 <- reshape2::melt(data.frame(dat2), id.vars = NULL)

data_summary <- function(x) {
   m <- mean(x)
   ymin <- m-sd(x)
   ymax <- m+sd(x)
   return(c(y=m,ymin=ymin,ymax=ymax))
}

p.mat1 = ggplot(mat1, aes(x = variable, y = value)) + geom_violin() + stat_summary(fun.data=data_summary) + scale_y_continuous(limits = c(-0.50, 0.50))
p.mat2 = ggplot(mat2, aes(x = variable, y = value)) + geom_violin() + stat_summary(fun.data=data_summary) + scale_y_continuous(limits = c(-0.50, 0.50))

pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/sc10_violinNormDif_levelplot_equi7_for_annex2.pdf") , width=6, height=10   )
grid.arrange( p.mat1 , p.mat2 ,  nrow=2, ncol=10 )  

dev.off()

q()
EOF



