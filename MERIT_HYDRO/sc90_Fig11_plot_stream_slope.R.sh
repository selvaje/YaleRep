#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_stream_var_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_stream_var_plot.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc90_stream_var_plot.R.sh.%J.out

# bash  /project/fas/sbsc/hydro/scripts/MERIT_HYDRO/sc90_stream_distance_plot.R.sh

source ~/bin/gdal3
module load R/3.5.3-foss-2018a-X11-20180131

OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/figure/data_stream_var_plot
 MHSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
 MHPR=/gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO

cd /home/selv/tmp/figure_hydrography90m/figure/data_stream_var_plot

R  --vanilla --no-readline   -q  <<'EOF'

rm(list = ls())

library(rgdal)
library(raster)
library(ggplot2)
library(gridExtra)

# require(rasterVis)

e = extent (8.64, 8.8, 44.4, 44.5 )

dir1="/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO"
dir2="/home/selv/tmp/figure_hydrography90m/"

for (var in  c( 
"slope_curv_max_dw_cel",
"slope_curv_min_dw_cel",
"slope_elv_dw_cel",
"slope_grad_dw_cel"
)) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}


pdf(paste0(dir2,"/figure/Fig10_plot_stream_slope.pdf") , width=7, height=1.87 )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(1,4) ,  xpd=NA    )

for (var in  c( 
"slope_curv_max_dw_cel",
"slope_curv_min_dw_cel",
"slope_elv_dw_cel",
"slope_grad_dw_cel"
)) {

n=100
colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
colsF=colF(n)
cols_legend=rev(colsF)

options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

colsR = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]

print(var)
raster=get(var)

des=print(var)         

max=raster@data@max ; min=raster@data@min 
if(var == "slope_curv_max_dw_cel" )  { max=max; min=min; at=c(-384900,0,384890); labels=c("-0.3849" , expression(paste("0m"^"-1")),"0.3849") ; letter="a)" } 
if(var == "slope_curv_min_dw_cel" )  { max=max ;  min=min; at=c(-384900,0,384890); labels=c("-0.3849", expression(paste("0m"^"-1")),"0.3849") ; letter="b)" } 
if(var == "slope_elv_dw_cel"      )  { max=max ; min=min ;  at=c(0,100,185) ; labels=c("0m","100m","190m") ; letter="c)" }    
if(var == "slope_grad_dw_cel"     )  { max=max ; min=min; at=c(0,1200000,2440000); labels=c("0","1.2200","2.4435" ) ; letter="b)" } 

plot(raster, main=des , col=colsF, tck=-0.05, cex.axis=0.8, yaxt="n", xaxt="n", xlab="", ylab="", colNA="grey30", legend=FALSE, cex.main=0.8, font.main=2, interpolate=FALSE)

plot(raster, axis.args=list(at=at, labels=labels, line=-0.85, tck=0, cex.axis=0.56, lwd=0), smallplot=c(0.86,0.90, 0.1,0.8), zlim=c(min,max),legend.only=TRUE,legend.width=1, legend.shrink=0.75 , col=colsF)

text( 8.64, 44.506 , letter ,  font=2   ,   xpd=TRUE , cex=1 )

if(var == "slope_curv_max_dw_cel" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "slope_curv_max_dw_cel" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "slope_curv_max_dw_cel" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "slope_curv_max_dw_cel" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/Fig10_plot_stream_slope.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig10_plot_stream_slope.pdf
