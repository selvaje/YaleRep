#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_plotDerv_levelplot_equi7_for_annex2.R.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_plotDerv_levelplot_equi7_for_annex2.R.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc10_plotDerv_levelplot_equi7_for_annex2.R.sh

# bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_plotDerv_levelplot_equi7_for_annex2.R.sh

module load Apps/R/3.3.2-generic

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
#  MERIT minus NED  ... positive values are due to not pefect correction of the tree hight 
elev_dif = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/input_tif/tiles/NA_066_048_dif.tif")  
elev_dif = crop   (elev_dif , e)


for ( dir in c("input_tif","roughness","tri","tpi","vrm","tci","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) { 
     raster  <- raster(paste0( dir,"/tiles/","/NA_066_048.tif") ) 
        raster = crop (raster , e)
        raster[raster == -9999 ] <- NA
 	assign(paste0(dir) , raster  )
}

for ( dir in c("Ew","Nw","sin","cos")) { 
        raster  <- raster(paste0("aspect/tiles/NA_066_048_",dir,".tif") ) 
        raster = crop (raster , e)        
        raster[raster == -9999 ] <- NA
 	assign(paste0(dir) , raster  )
}


print("start to plot")

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)

options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/derivative_all_var_plot_equi7_for_annex2.pdf") , width=6, height=7.5   )
par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(6,4) ,  xpd=NA    )

for ( dir in c("elev_M","elev_N","elev_cor","elev_dif","input_tif","roughness","tri","tpi","vrm","tci","spi","cos","sin","slope","Ew","Nw","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")){

if ( dir != "elev_cor" ) { 
raster=get(dir)
max=get(dir)@data@max ; min=get(dir)@data@min 

if(dir == "elev_M"   ) { des="Elevation MERIT"           ; max=max ; min=min ; at=c( round(min)+1 , round(max) ) ; labels=c( round(min) , round(max) ) ; letter="a" }
if(dir == "elev_M"   ) { des="Elevation MERIT"           ; maxM=max ; minM=min } 
if(dir == "elev_N"   ) { des="Elevation 3DEP"                ; max=max ; min=min ; at=c( round(min)+20 , round(max)-5 ) ; labels=c( round(min) , round(max) ) ; letter="b" }
if(dir == "elev_N"   ) { des="Elevation 3DEP"                ; maxN=max ; minN=min  }
if(dir == "elev_dif" ) { des="Elevation diff.  MERIT - 3DEP" ; max=max ; min=min ; at=c( round(min)+1 ,0 ,  round(max) ) ; labels=c( round(min) ,0 ,  round(max) ) ; letter="d" }
# derivatives 
if(dir == "input_tif" )  { des="Elevation"               ; max=max ; min=min ; at=c( 0.000001 , 0.0005 ) ; labels=c( 0 ,  formatC(max , format = "e", digits = 1 ) ) ; letter="e" }
if(dir == "roughness" )  { des="Roughness"               ; max=max ; min=min ; at=c( 0.1 , round(max )-2) ; labels=c( 0  , round(max)  ) ; letter="f" }
if(dir == "tri" )      { des="Terrain roughness index"    ; max=max ; min=min ; at=c( 0.1 , round(max) ) ; labels=c( 0 , round(max) ) ; letter="g" }
if(dir == "tpi" )      { des="Topographic position index" ; max=max ; min=min ; at=c( 0.1 , round(max)-1 ) ; labels=c( 0 , round(max) ) ; letter="h" }
if(dir == "vrm" )      { des="Vector ruggedness measure"  ; max=max ; min=min ; at=c( 0.0005 , 0.06  ) ; labels=c( 0 , 0.6 )  ; letter="i" }
if(dir == "tci" )      { des="Compound topographic index" ; max=max ; min=min ; at=c(0.01,0.9)    ; labels=c(0,0.9) ; letter="j" }
if(dir == "spi" )      { des="Stream power index"         ; max=max ; min=min ; at=c( 0.1 , round(max)-1 ) ;  labels=c( 0 , round(max)  ) ; letter="k" }
if(dir == "cos" )      { des="Aspect cosine"                 ; max=max ; min=min ; at=c( 0.01 , 0.9 ) ; labels=c( 0 , 0.9 ) ; letter="l" } 
if(dir == "sin" )      { des="Aspect sine"                   ; max=max ; min=min ; at=c( 0.01 , 1 ) ; labels=c( 0 , 1 ) ; letter="m" }
if(dir == "slope" )    { des="Slope"                         ; max=max ; min=min ; at=c( 0.01 , round(max)-0.5 ) ; labels=c( 0 , round(max)) ; letter="n" }
if(dir == "Ew" )       { des="Eastness"                      ; max=max  ; min=min ; at=c( 0.0001 , 0.27 ) ; labels=c( 0 , 0.27 ) ; letter="o" }
if(dir == "Nw" )       { des="Northness"                      ; max=max ; min=min ; at=c( 0.0001 , 0.195 ) ; labels=c( 0 , 0.19 ) ; letter="p" }
if(dir == "pcurv" )    { des="Profile curvature"         ; max=max ; min=min ; at=c(0.00001, 0.0037) ; labels=c(0,formatC(max , format = "e", digits = 1 )) ; letter="q" }
if(dir == "tcurv" )    { des="Tangential curvature"      ; max=max ; min=min ; at=c(0.00001, 0.0036) ; labels=c(0,formatC(max , format = "e", digits = 1 )) ; letter="r" } 
if(dir == "dx" )       { des="1st partial derivative (E-W slope)"     ; max=max ; min=min ; at=c(0.001, 0.47) ; labels=c(0,0.47) ; letter="s" }
if(dir == "dy" )       { des="1st partial derivative (N-S slope)"     ; max=max ; min=min ; at=c(0.001, 0.29) ; labels=c(0,0.29) ; letter="t" } 
if(dir == "dxx" )      { des="2nd partial derivative (E-W slope)"     ; max=max ; min=min ; at=c(0.0001, 0.0072) ; labels=c(0,0.007) ; letter="u" }
if(dir == "dyy" )      { des="2nd partial derivative (N-S slope)"     ; max=max ; min=min ; at=c(0.0001, 0.0046) ; labels=c(0,0.004) ; letter="v" }
if(dir == "dxy" )      { des="2nd partial derivative"  ; max=max ; min=min ; at=c(0.00001,0.0022) ; labels=c(0,0.0022)  ; letter="w" }
if(dir == "convergence" ) { des="Convergence"     ; max=max ; min=min ; at=c(1,39) ; labels=c(0,39)   ; letter="x" }

raster[raster > max] <- max
raster[raster < min] <- min

print(dir)
print (min) ; print (max)

}

# mgp The margin line (in ‘mex’ units) for the axis title, axis
#           labels and axis line.  Note that ‘mgp[1]’ affects ‘title’
#           whereas ‘mgp[2:3]’ affect ‘axis’.  The default is ‘c(3, 1,
#           0)’.



if ( dir == "elev_cor" ) {
plot( elev_M, elev_N, pch = 16, cex = .1 , xaxt = "n" , yaxt = "n" , main="Elevation 3DEP vs MERIT", cex.main=0.65 , font.main=2 )
abline(0, 1 , col="red")
fit = lm ( elev_N@data@values ~ elev_M@data@values  ) 
abline(fit, col = "blue")
axis(side = 1, mgp=c(3,-0.35,0),        , cex.axis=0.56 , at =c(round(minM),round(maxM)), labels =c(round(minM),round(maxM))  , tck=0)  # x axis  
axis(side = 2, mgp=c(3,0.2,0)  ,  las=2 , cex.axis=0.56 , at =c(round(minN)-20, round(maxN)), labels =c(round(minN),round(maxN))  , tck=0)  # y axis 
text( 2940 , 2870  , "c" ,  font=2   ,   xpd=TRUE , cex=1 )
text( 1200 , 2420 , "3DEP (m)"    , font=2 ,  srt=90 ,  xpd=TRUE , cex=0.6 )
text( 2470 , 1220 , "MERIT (m)"   , font=2 ,  srt=0  ,  xpd=TRUE , cex=0.6 )

}

if (( dir != "elev_cor" ) &&  (  dir != "dxx"   )     ) { 
plot(raster  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.56 , lwd = 0  ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(6912000 , 5219400 , letter ,  font=2   ,   xpd=TRUE , cex=1 )
}

# lwd = 0 toglie la righa affianco alla legend 

# e = extent ( 7500000 , 7520000 ,  5081600 , 5100000 )
# e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 )  

if ( dir == "dxx"   ) { 
plot(raster  , col=cols ,  yaxp=c(5201000, 5217400 ,1) , xaxp=c(6891000, 6909000,1) , tck=-0.05, cex.axis=0.8 , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0  , cex.axis=0.56 ,  lwd = 0 ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(6912000 , 5219400  , letter ,  font=2   ,   xpd=TRUE , cex=1 )
}
}

dev.off()

q()
EOF



