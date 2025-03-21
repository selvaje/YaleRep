#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_stream_var_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_stream_var_plot.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc90_stream_var_plot.R.sh.%J.out

# bash  /project/fas/sbsc/hydro/scripts/MERIT_HYDRO/sc90_stream_distance_plot.R.sh

# source ~/bin/gdal3
# module load R/3.5.3-foss-2018a-X11-20180131

# OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/figure/data_stream_var_plot
#   MHSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
#   MHPR=/gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO

cd /home/selv/tmp/figure_hydrography90m/figure/data_stream_var_plot


# for file in order_hack.tif  order_horton.tif  order_shreve.tif  order_strahler.tif  order_topo.tif  ; do
#      filename=$(basename $file .tif)
#      pksetmask -ot Int16 -m elv.tif -msknodata -9999  -nodata -1     -i ${file}  -o ${filename}_msk.tif
# done 

# pksetmask -ot Int16 -m  order_hack_msk.tif  -msknodata 0.9 -p '>'  -nodata   0 -i   order_hack_msk.tif   -i  -o base.tif



R  --vanilla --no-readline   -q  <<'EOF'

rm(list = ls())

library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)
library(sp)

# require(rasterVis)

e = extent (8.64, 8.8, 44.4, 44.5 )

dir1="/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO"
dir2="/home/selv/tmp/figure_hydrography90m/"

for (var in  c( 
"order_hack",
"order_horton",
"order_shreve",
"order_strahler",
"order_topo"
)) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , "_msk.tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}

base=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/elv.tif")),e)
base[base == -1 ] <- NA
order_topo[ order_topo  > 50 ] <- 50

stream_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/stream_vect.shp"))
stream_p=readOGR(paste0(dir2,"/figure/data_stream_var_plot/stream_vect_point.shp"))

pdf(paste0(dir2,"/figure/figure_tables/Fig13_plot_stream_order.pdf") , width=5.6, height=3.2  )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(2,3) ,  xpd=NA   )

for (var in  c(
"order_hack",
"order_horton",
"order_shreve",
"order_strahler",
"order_topo",
"base"
)) {

n=100 
if (var == "order_hack" )     { colsF=c( "antiquewhite1","red","grey","blue","yellow","green","orange","magenta","brown","black")   }
if (var == "order_horton" )   { colsF=c( "antiquewhite1","red","blue","yellow","green","orange","magenta")   }
if (var == "order_strahler" ) { colsF=c( "antiquewhite1","red","blue","orange","green")   }

if (var == "order_shreve" )  { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) ; colsF=append ( "antiquewhite1" , colF(n)) }
if (var == "order_topo" )    { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) ; colsF=append ( "antiquewhite1" , colF(n)) }
if (var == "base" )    {  colsF=c( "antiquewhite1") }

cols_legend=rev(colsF)

print(var)
raster=get(var)

des=print(var)         

max=raster@data@max ; min=raster@data@min

if(var == "order_hack" )    { max=max ; min=1 ;  at=c(2,2.8,3.7,4.5,5.6,6.4,7.2,8,8.8)  ; labels=c("1","2","3","4","5","6","7","8","9") ; letter="a)" }    
if(var == "order_horton")   { max=max ; min=1 ;  at=c(1.9,2.6,3.7,4.3,5.2,6)  ; labels=c("1","2","3","4","5","6")  ; letter="b)" }    
if(var == "order_shreve")   { max=max ; min=1 ;  at=c(1,40,80)        ; labels=c("1","40","80") ; letter="c)" }    
if(var == "order_strahler") { max=5   ; min=1 ;  at=c(2,3,4,5)        ; labels=c("1","2","3","4")   ; letter="d)" }    
if(var == "order_topo")     { max=50  ; min=1 ;  at=c(1,15,37,47)     ; labels=c("1","15","30",">1000") ; letter="f)" }    
if(var == "base" )    { max=0 ; min=0 ;  at=c(0)  ; labels=c("Land") ; letter="g)" ; des="vect" }    

plot(raster, main=des , col=colsF, tck=-0.05, cex.axis=0.8, yaxt="n", xaxt="n", xlab="", ylab="", colNA="grey30", legend=FALSE, cex.main=0.8, font.main=2, interpolate=FALSE)
if(var != "base" ){ 
plot(raster, axis.args=list(at=at,labels=labels,line=-0.85,tck=0,cex.axis=0.56,lwd = 0),smallplot=c(0.86,0.90, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75,col=colsF)
}

colsR = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]
colsV=(append(colsR, colsR[1:253]))[as.factor(stream_l$cat)]

if(var == "base" ){ plot(stream_l, col = c("blue"), lwd=0.2 , add=TRUE ,  legend=FALSE  ) 
                    plot(stream_p, col = c("black"), lwd=0.01 , pwd=0.01   , add=TRUE , pch=20 ,  legend=FALSE  ) 
                    legend(8.803,44.49 , pch=c(20,NA,NA,NA,NA), lty=c(NA,NA,NA,1,NA)  , col = c("black","blue"), lwd=0.4  , xpd=NA ,  legend=c("initialisation","node","outlet","stream","segment") ,  bty="n" , cex=0.5 )
                      }

text( 8.64, 44.506 , letter ,  font=2   ,   xpd=TRUE , cex=1 )

if(var == "order_strahler" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "order_strahler" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "order_strahler" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "order_strahler" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/figure_tables/Fig13_plot_stream_order.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig13_plot_stream_order.pdf
