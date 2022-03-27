#!/bin/bash
#SBATCH -p day
#SBATCH -J sc72_plot_ws_bin_areaMap.R.sh
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc72_plot_ws_bin_areaMap.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc72_plot_ws_bin_areaMap.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc72_plot_ws_bin_areaMap.R.sh

ulimit

# remove file from yesterday

find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr 

export  FIG=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures
export  SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country

# gdalwarp -tr 0.0833333333333333 0.0833333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area.tif $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area_km10.tif
# gdalwarp -tr 0.0833333333333333 0.0833333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_area.tif   $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_area_km10.tif 

module load Apps/R/3.3.2-generic

# R --vanilla --no-readline   -q  <<'EOF'

# # source ("/gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc72_plot_ws_bin_areaMap.R.sh")
# .libPaths( c( .libPaths(), "/home/fas/sbsc/ga254/R/x86_64-unknown-linux-gnu-library/3.0") )

# library(rgdal)
# library(raster)
# library(lattice)
# library(rasterVis)

# raster=log(raster("/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area_km10.tif"))
# ext <- as.vector(extent(raster))
# print ("load shapefile")

# coast=shapefile("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure/shp/globe_clip.shp" ,  useC=FALSE )
# # coast=crop(coast, extent(ext)) 

# n=100
# min=2       # not in log
# max=1000000 # not in log

# min=0.46
# max=13

# pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area.pdf",width=16 , height=8 )

# at=seq(min,max,length=n)
# colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
 
# cols=colR(n)

# res=1e8 # res=1e4 for testing and res=1e6 for the final product
# greg=list(ylim=c(-60,85),xlim=c(-180,180))

# par(cex.axis=2, cex.lab=2, cex.main=4, cex.sub=2 )

# raster[raster>max] <- max
# raster[raster<min] <- min


# lattice.options(
#   layout.heights=list(bottom.padding=list(x=2), top.padding=list(x=2)),
#   layout.widths=list(left.padding=list(x=4), right.padding=list(x=4))
# )

# print ( levelplot(raster,col.regions=colR(n),   scales=list(cex=1.5) ,   cuts=99,at=at, 
#     colorkey=list(space="bottom",adj=2 , at=at ,   labels=list( at= c(0.46, 2.3,4.6, 6.9,9.9,   12.15) , labels=as.character(c( "2","10","100","1000", "20000",  ">1000000 (km2)"))  ,   cex=1.5) )    , 
#     panel=panel.levelplot.raster, margin=F , maxpixels=res , ylab="" , xlab="" ,useRaster=T ) + layer(sp.polygons(coast ,  fill="white" )  ) )

# dev.off() 

# EOF


# gdal_translate -projwin -78 46  -68 33   -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area.tif $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area_crop.tif

# ogr2ogr -clipsrc -80 30  -65 50  GSHHS_f_L1_clip.shp            GSHHS_f_L1.shp  
# ogr2ogr -clipsrc -80 30  -65 50  GSHHS_f_L1_simpl0.001_clip.shp GSHHS_f_L1_simpl0.001.shp
# ogr2ogr -clipsrc  GSHHS_f_L1_square_clip.shp   GSHHS_f_L1_square_clip_intersect.shp  GSHHS_f_L1_simpl0.001_clip.shp
# inverted by heand in qgis 


R --vanilla --no-readline   -q  <<'EOF'

# source ("/gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc72_plot_ws_bin_areaMap.R.sh")
.libPaths( c( .libPaths(), "/home/fas/sbsc/ga254/R/x86_64-unknown-linux-gnu-library/3.0") )

library(rgdal)
library(raster)
library(lattice)
library(rasterVis)

raster=log(raster("/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_ws_clump_area_crop.tif"))
ext <- extent( -78.6, -69.8, 37, 43.2)
raster=crop(raster,extent(ext))
print ("load shapefile")

coast=shapefile("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/GSHHS_f_L1_square_clip_intersect.shp" ,  useC=FALSE )
# coast=crop(coast, extent(ext)) 
 

n=100
min=0.65       # not in log
max=10000 # not in log

min=3
max=8

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area_zoomNY.pdf" , width=6 , height=6 )

at=seq(min,max,length=n)
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
 
cols=colR(n)

res=1e10  # res=1e4 for testing and res=1e6 for the final product
greg=list(ylim=c(-60,85),xlim=c(-180,180))

par(cex.axis=1, cex.lab=1,  cex.sub=1 )

raster[raster>max] <- max
raster[raster<min] <- min


lattice.options(
  layout.heights=list(bottom.padding=list(x=1), top.padding=list(x=1)),
  layout.widths=list(left.padding=list(x=1), right.padding=list(x=1))
)

print ( levelplot(raster,col.regions=colR(n),   scales=list(cex=1) ,   cuts=99,at=at, 
    colorkey=list(space="bottom",adj=2 , at=at ,   labels=list( at= c(3,3.9,4.6,5.7,6.6,7.6) , labels=as.character(c( "20","50","100","300", "800",  ">3000 (km2)")) ,                      cex=1) )    , 
    panel=panel.levelplot.raster, margin=F , maxpixels=res , ylab="" , xlab="" ,useRaster=T ) + layer(sp.polygons(coast , lwd=0.5 ,  fill="white" )  ) )

dev.off() 

EOF

# gdal_translate -projwin -78 46  -68 33   -co COMPRESS=DEFLATE -co ZLEVEL=9    $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_area.tif   $SCRATCH/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_area_crop.tif

R --vanilla --no-readline   -q  <<'EOF'

# source ("/gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc72_plot_ws_bin_areaMap.R.sh")
.libPaths( c( .libPaths(), "/home/fas/sbsc/ga254/R/x86_64-unknown-linux-gnu-library/3.0") )

library(rgdal)
library(raster)
library(lattice)
library(rasterVis)

raster=(raster("/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin1-9_clump_area_crop.tif"))
ext <- extent( -78.6, -69.8, 37, 43.2)
raster=crop(raster,extent(ext))
print ("load shapefile")

coast=shapefile("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/GSHHS_f_L1_square_clip_intersect.shp" ,  useC=FALSE )
# coast=crop(coast, extent(ext)) 
 

n=100
min=0.65 
max=4000

# min=0.46
# max=5800

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/bin_area_zoomNY.pdf" , width=6 , height=6 )

at=seq(min,max,length=n)
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
 
cols=colR(n)

res=1e10  # res=1e4 for testing and res=1e6 for the final product
greg=list(ylim=c(-60,85),xlim=c(-180,180))

par(cex.axis=1, cex.lab=1,  cex.sub=1 )

raster[raster>max] <- max
raster[raster<min] <- min


lattice.options(
  layout.heights=list(bottom.padding=list(x=1), top.padding=list(x=1)),
  layout.widths=list(left.padding=list(x=1), right.padding=list(x=1))
)

print ( levelplot(raster,col.regions=colR(n),   scales=list(cex=1) ,   cuts=99,at=at, 
    colorkey=list(space="bottom",adj=2 , at=at ,   labels=list(    cex=1) )    , 
    panel=panel.levelplot.raster, margin=F , maxpixels=res , ylab="" , xlab="" ,useRaster=T ) + layer(sp.polygons(coast , lwd=0.5 ,  fill="white" )  ) )

dev.off() 

EOF

