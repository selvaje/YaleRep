

# module load Apps/R/3.3.2-generic
# source ("/gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_plotDerv_levelplot.R.sh" ) 

# cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/


rm(list = ls())

library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)

# require(rasterVis)

# 34 spazio sopra e sotto 
# 35 spazio sopra e sotto ancora piu largo del 34
# 33 piccolo spazio a destra e sinitstra 

e=extent( -97.10, -97.00, 42.332, 42.40)

for ( dir in c("input_tif","roughness","tri","tpi","vrm","tci","spi","slope","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) { 
     raster  <- raster(paste0( dir,"/tiles/","/n40w100.tif") ) 
        raster[raster == -9999 ] <- NA
        raster = crop (raster , e)
 	assign(paste0(dir) , raster  )
}

for ( dir in c("Ew","Nw","sin","cos")) { 
        raster  <- raster(paste0("aspect/tiles/n40w100_",dir,".tif") ) 
        raster[raster == -9999 ] <- NA
        raster = crop (raster , e)
 	assign(paste0(dir) , raster  )
 }

elev_M = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n40w100_dem.tif")
elev_M = crop   (elev_M , e)

elev_N = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif/n40w100.tif")
elev_N = crop   (elev_N , e)

elev_dif = raster ("input_tif/tiles/n40w100_dif.tif")
elev_dif = crop   (elev_dif , e)

print("start to plot")

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)

options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

postscript(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/derivative_all_var_plot.ps") ,  paper="special" ,  horizo=F , width=6, height=7.5   )
par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,2) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(6,4) ,  xpd=NA    )

for ( dir in c("elev_M","elev_N","elev_cor","elev_dif","input_tif","roughness","tri","tpi","vrm","tci","spi","cos","sin","slope","Ew","Nw","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")){

if ( dir != "elev_cor" ) { 
raster=get(dir)
max=get(dir)@data@max ; min=get(dir)@data@min

if(dir == "elev_M"   ) { des="Elevation MERIT"        ; max=497 ; min=435 ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="a" }
if(dir == "elev_N"   ) { des="Elevation NED"          ; max=497 ; min=435 ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="b" }
if(dir == "elev_dif" ) { des="Elevation Difference (MERIT-NED)"   ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="d" }
# derivatives 
if(dir == "input_tif" ) { des="Elevation"                ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="e" }
if(dir == "roughness" )  { des="Roughness"               ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="f" }
if(dir == "tri" )     { des="Terrain Roughness Index"    ; max=max ; min=min ; at=c(min,0.5,1,1.5)    ; labels=c(0,0.5,1,1.5) ; letter="g" }
if(dir == "tpi" )     { des="Topographic Position Index" ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="h" }
if(dir == "vrm" )     { des="Vector Ruggedness Measure"  ; max=max ; min=min ; at=c(min,0.0001,0.0002,0.0003,0.0004,0.0005) ; labels=c(0,0.0001,0.0002,0.0003,0.0004,0.0005) ; letter="i" }
if(dir == "tci" )     { des="Topographic Cumulative Index" ;max=max; min=min ; at=seq(min,max,0.1)   ; labels=seq(0,0.6,0.1 ) ; letter="j" }
if(dir == "spi" )     { des="Stream Power Index"         ; max=0.1   ; min=min ; at=c(min,0.02,0.04,0.06,0.08,0.1 ) ; labels=seq(0,0.1,0.02 ) ; letter="k" }
if(dir == "cos" )  { des="Aspect Cosine"                 ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="l" } 
if(dir == "sin" )  { des="Aspect Sine"                   ; max=max ; min=min ; at=pretty( min : max ) ; labels=pretty( min : max ) ; letter="m" }
if(dir == "slope" )    { des="Slope"                     ; max=max ; min=min ; at=c(min,0.4,0.8,1.2,1.6 ) ; labels=c(0,0.4,0.8,1.2,1.6 )   ; letter="n" }
if(dir == "Ew" )   { des="Eastness"                      ; max=max ; min=min ; at=c(min,0.01,0.02,0.03 )  ; labels=c(0,0.01,0.02,0.03 )    ; letter="o" }
if(dir == "Nw" )  { des="Northness"                      ; max=max ; min=min ; at=c(min,0.01,0.02,0.03 )  ; labels=c(0,0.01,0.02,0.03 ) ; letter="p" }
if(dir == "pcurv" )    { des="Profile curvature"         ; max=max ; min=min ; at=c(min,0.0002,0.0004,0.0006,0.0008) ; labels=c(0,0.0002,0.0004,0.0006,0.0008); letter="q" }
if(dir == "tcurv" )    { des="Tangential curvature"      ; max=max ; min=min ; at=c(min,0.0002,0.0004,0.0006,0.0008,0.001) ; labels=c(0,0.0002,0.0004,0.0006,0.0008,0.001)  ; letter="r" } 
if(dir == "dx" )      { des="1st partial derivative (E-W slope)" ; max=max ; min=min ; at=c(min,0.01,0.02,0.03,0.04) ; labels=c(0,0.01,0.02,0.03,0.04)  ; letter="s" }
if(dir == "dy" )  { des="1st partial derivative (N-S slope)"     ; max=max ; min=min ; at=c(min,0.01,0.02,0.03) ; labels=c(0,0.01,0.02,0.03)   ; letter="t" } 
if(dir == "dxx" ) { des="2nd partial derivative (E-W slope)"     ; max=max ; min=min ; at=c(min,0.0002,0.0004,0.0006,0.0008,0.001) ; labels=c(0,0.0002,0.0004,0.0006,0.0008,0.001)  ; letter="u" }
if(dir == "dyy" ) { des="2nd partial derivative (N-S slope)" ; max=max ; min=min ; at=c(min,0.0002,0.0004,0.0006,max) ; labels=c(0,0.0002,0.0004,0.0006,0.0008) ; letter="v" }
if(dir == "dxy" ) { des="2nd partial derivative"  ; max=max ; min=min ; at=c(min,0.0001,0.0002,0.0003,0.0004) ; labels=c(0,0.0001,0.0002,0.0003,0.0004)  ; letter="w" }
if(dir == "convergence" ) { des="Convergence"     ; max=max ; min=min ; at=pretty( min : max )  ; labels=pretty( min : max )   ; letter="x" }

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
plot( elev_M, elev_N, pch = 16, cex = .1 , xaxt = "n" , yaxt = "n" , main="Elevation NED vs MERIT", cex.main=0.65 , font.main=2 )
text( 493 , 427 , "MERIT (m)" , font=2 ,   xpd=TRUE , cex=0.5 )
axis(side = 1, mgp=c(3,-0.35,0),        , cex.axis=0.56 , at =c(440,460,480), labels =c(440,460,480)  , tck=0)
axis(side = 4, mgp=c(3,0.2,0)  ,  las=2 , cex.axis=0.56 , at =c(440,460,480), labels =c(440,460,480)  , tck=0)
text( 505 , 508 , "c" ,  font=2   ,   xpd=TRUE , cex=1.4 )
text( 504 , 492 , "NED (m)"   , font=2 ,  srt=90 ,  xpd=TRUE , cex=0.5 )


}

if (( dir != "elev_cor" ) &&  (  dir != "dxx"   )     ) { 
plot(raster  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.68, tck=0 , cex.axis=0.56   ) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(-96.99 , 42.405, letter ,  font=2   ,   xpd=TRUE , cex=1.2 )
}

if ( dir == "dxx"   ) { 
plot(raster  , col=cols ,  yaxp=c( 42.30, 42.40 , 4 ) , xaxp=c(-97.10 , -97 , 4 ) , tck=-0.05, cex.axis=0.8 , main=des  , legend=FALSE  , cex.main=0.65 , font.main=2 )
plot(raster, axis.args=list( at=at , labels=labels , line=-0.68, tck=0  , cex.axis=0.56) ,  smallplot=c(0.83,0.87, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(-96.99 , 42.405, letter ,  font=2   ,   xpd=TRUE , cex=1.2 )
}
}

dev.off()


system("ps2epsi /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/derivative_all_var_plot.ps /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/derivative_all_var_plot.eps")

