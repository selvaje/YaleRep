#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_plotNormDif_levelplot_equi7_for_annex2.R.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_plotNormDif_levelplot_equi7_for_annex2.R.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc10_plotDerv_levelplot_equi7_for_annex2.R.sh

# bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_plotNormDif_levelplot_equi7_for_annex2.R.sh

# module load Apps/R/3.3.2-generic
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
 assign(paste0(dir) , raster  )
}

print("start to plot")

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)

options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/NormDif_all_var_plot_equi7_for_annex2.pdf") , width=6, height=7.5   )
par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(6,4) ,  xpd=NA    )


for ( dir in c("elev_N","elev_M","elev_cor","elev_dif","elevation","roughness","tri","tpi","vrm","cti","spi","aspectcosine","aspectsine","slope","eastness","northness","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) { 
if ( dir != "elev_cor" ) { 
raster=get(dir)


if(dir == "elev_N"   ) { des="Elevation 3DEP"  ;  max=elev_N@data@max ; min=elev_N@data@min ; at=c( round(min)+10, round(max)-10);labels=c( round(min),round(max) ) ; letter="b" }
if(dir == "elev_N"   ) { des="Elevation 3DEP"  ; maxN=elev_N@data@max ; minN=elev_N@data@min    }
if(dir == "elev_M"   ) { des="Elevation MERIT" ; max=elev_M@data@max ; min=elev_M@data@min ; at=c( round(min)+10, round(max)-10);labels=c( round(min),round(max) ) ; letter="a" }
if(dir == "elev_M"   ) { des="Elevation MERIT" ; maxM=elev_M@data@max ; minM=elev_M@data@min  }
if(dir == "elev_dif" ) { des="Elevation diff.  3DEP - MERIT" ; max=round(elev_dif@data@max) ; min=round(elev_dif@data@min) ; at=c( min,0,max); labels=c(min,0 ,  max ) ; letter="d" }

# normalized  
if(dir == "elevation" )  { des="Elevation"                ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="e" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6 }
if(dir == "roughness" )  { des="Roughness"                ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="f" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "tri" )      { des="Terrain roughness index"    ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="g" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "tpi" )      { des="Topographic position index" ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="h" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "vrm" )      { des="Vector ruggedness measure"  ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="i" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "cti" )      { des="Compound topographic index" ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="j" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "spi" )      { des="Stream power index"         ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="k" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "aspectcosine" )    { des="Aspect cosine"       ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="l" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   } 
if(dir == "aspectsine" )      { des="Aspect sine"         ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="m" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "slope" )           { des="Slope"               ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="n" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "eastness")         { des="Eastness"            ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="o" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "northness" )       { des="Northness"           ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="p" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6    }
if(dir == "pcurv" )    { des="Profile curvature"          ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="q" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "tcurv" )    { des="Tangential curvature"       ; max=1 ; min=-1 ;  at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="r" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   } 
if(dir == "dx" )       { des="1st partial derivative (E-W slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="s" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "dy" )       { des="1st partial derivative (N-S slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="t" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   } 
if(dir == "dxx" )      { des="2nd partial derivative (E-W slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="u" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "dyy" )      { des="2nd partial derivative (N-S slope)" ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="v" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "dxy" )      { des="2nd partial derivative"             ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="w" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
if(dir == "convergence" ) { des="Convergence"                     ; max=1 ; min=-1 ; at=c( -1,-0.5,0,+0.5,+1 ) ; labels=c(-1,-0.5,0,+0.5,+1) ; letter="x" ; raster[raster >  0.6 ] <-  0.6 ; raster[raster < -0.6 ] <- -0.6   }
print(dir)
print(max)
print(min)

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



