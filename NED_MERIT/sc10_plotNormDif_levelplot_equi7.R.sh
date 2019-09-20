#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_plotNormDif_levelplot_equi7.R.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_plotNormDif_levelplot_equi7.R.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc10_plotDerv_levelplot_equi7.R.sh

# bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_plotNormDif_levelplot_equi7.R.sh

module load Apps/R/3.3.2-generic

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/

# gdal_translate -projwin  7500000 5100000 7520000 5081600   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_072_048.tif /tmp/test.tif 
#  ( 7500000 , 7520000 , 5081600 , 5100000 ) 

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

e = extent ( 7500000 , 7520000 , 5081600 , 5100000 ) 

elev_M = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_072_048.tif") 
elev_M = crop   (elev_M , e)

elev_N = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_072_048.tif") 
elev_N = crop   (elev_N , e)
#  MERIT minus NED  ... positive values are due to not pefect correction of the tree hight 
elev_dif = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/input_tif/tiles/NA_072_048_dif.tif")  
elev_dif = crop   (elev_dif , e)

for ( dir in c("elevation","roughness","tri","tpi","vrm","cti","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence","aspectcosine","aspectsine","eastness","northness")) { 
     raster  <- raster(paste0( dir,"/tiles/","/NA_072_048_dif_norm.tif") ) 
        # raster = crop (raster , e)
        raster[raster == -9999 ] <- NA
 	assign(paste0(dir) , raster  )
}

print("start to plot")

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)
cols_legend=rev(cols)
options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/NormDif_all_var_plot_equi7.pdf") , width=6, height=7.5   )
par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(6,4) ,  xpd=NA    )

for ( dir in c("elev_M","elev_N","elev_cor","elev_dif","elevation","roughness","tri","tpi","vrm","cti","spi","aspectcosine","aspectsine","slope","eastness","northness","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) { 
if ( dir != "elev_cor" ) { 
raster=get(dir)

if(dir == "elev_M"   ) { des="Elevation MERIT"    ; max=1093.959 ; min=347.962 ; at=c( round(min)+18, round(max)-10);labels=c( round(min),round(max) ) ; letter="a" }
if(dir == "elev_M"   ) { des="Elevation MERIT"    ; maxM=1093.959 ; minM=347.962  }
if(dir == "elev_N"   ) { des="Elevation 3DEP"     ; max=1089.463 ; min=344.906 ; at=c( round(min)+18, round(max)-10);labels=c( round(min),round(max) ) ; letter="b" }
if(dir == "elev_N"   ) { des="Elevation 3DEP"     ; maxN=1089.463 ; minN=344.906    }
if(dir == "elev_dif" ) { des="Elevation diff.  MERIT - 3DEP" ; max=124.0928 ; min=-49.65186 ; at=c( -48  ,0 , 123 ); labels=c( -49 ,0 ,  124 ) ; letter="d" }

# normalized     
if(dir == "elevation" )  { des="Elevation"                ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="e" }
if(dir == "roughness" )  { des="Roughness"                ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="f" }
if(dir == "tri" )      { des="Terrain roughness index"    ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="g" }
if(dir == "tpi" )      { des="Topographic position index" ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="h" }
if(dir == "vrm" )      { des="Vector ruggedness measure"  ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="i" }
if(dir == "cti" )      { des="Compound topographic index" ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="j" }
if(dir == "spi" )      { des="Stream power index"         ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="k" }
if(dir == "aspectcosine" )    { des="Aspect cosine"       ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="l" } 
if(dir == "aspectsine" )      { des="Aspect sine"         ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="m" }
if(dir == "slope" )           { des="Slope"               ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="n" }
if(dir == "eastness")         { des="Eastness"            ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="o" }
if(dir == "northness" )       { des="Northness"           ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="p" }
if(dir == "pcurv" )    { des="Profile curvature"          ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="q" }
if(dir == "tcurv" )    { des="Tangential curvature"       ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="r" } 
if(dir == "dx" )       { des="1st partial derivative (E-W slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="s" }
if(dir == "dy" )       { des="1st partial derivative (N-S slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="t" } 
if(dir == "dxx" )      { des="2nd partial derivative (E-W slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="u" }
if(dir == "dyy" )      { des="2nd partial derivative (N-S slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="v" }
if(dir == "dxy" )      { des="2nd partial derivative"             ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="w" }
if(dir == "convergence" ) { des="Convergence"                     ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="x" }

}

# mgp The margin line (in ‘mex’ units) for the axis title, axis
#           labels and axis line.  Note that ‘mgp[1]’ affects ‘title’
#           whereas ‘mgp[2:3]’ affect ‘axis’.  The default is ‘c(3, 1,0)’.

print(paste("plotting",dir))

if ( dir == "elev_cor" ) {
plot( elev_M, elev_N, pch = 16, cex = .1 , xaxt = "n" , yaxt = "n" , main="Elevation 3DEP vs MERIT", cex.main=0.65 , font.main=2 )
abline(0, 1 , col="red")
fit = lm ( elev_N@data@values ~ elev_M@data@values  ) 
abline(fit, col = "blue")
text( 493 , 427 , "MERIT (m)" , font=2 ,   xpd=TRUE , cex=0.5 )

text( 720 , 720  , "c" ,  font=2   ,   xpd=TRUE , cex=1 )

text( 579 , 682 , "3DEP (m)"    , font=2 ,  srt=90 ,  xpd=TRUE , cex=0.6 )
text( 561 , 702 , "1089"  ,  srt=0  ,  xpd=NA , cex=0.47 )
text( 563 , 572 , "345"   ,  srt=0  ,  xpd=NA , cex=0.47 )

text( 683 , 575 , "MERIT (m)"   , font=2 ,  srt=0  ,  xpd=TRUE , cex=0.6 )
text( 694 , 562 , "1094"  ,  srt=0  ,  xpd=NA , cex=0.47 )
text( 584 , 562 , "348"  ,  srt=0  ,  xpd=NA , cex=0.47 )

}

if (( dir != "elev_cor" ) &&  (  dir != "dxx"   )     ) { 
print(dir) 
print(min) ; print (max)
plot(raster  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.56 , lwd = 0  ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(7522000 ,5101000, letter ,  font=2   ,   xpd=TRUE , cex=1 )
}

# lwd = 0 toglie la righa affianco alla legend 
# e = extent ( 7500000 , 7520000 , 5081600 , 5100000 ) 

if ( dir == "dxx"   ) { 
plot(raster, col=cols, yaxp=c(5082600, 5099000  ,1) , xaxp=c(7501000, 7519000,1) , tck=-0.05, cex.axis=0.8 , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0  , cex.axis=0.56 ,  lwd = 0 ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(7522000 ,5101000 , letter ,  font=2   ,   xpd=TRUE , cex=1 )
}
}

dev.off()

q()
EOF
