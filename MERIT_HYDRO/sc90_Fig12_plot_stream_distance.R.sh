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
"stream_dist_up_near",
"stream_dist_up_farth",
"stream_dist_dw_near",
"outlet_dist_dw_basin",
"outlet_dist_dw_scatch", 
"stream_dist_proximity",
"stream_diff_up_near",
"stream_diff_up_farth", 
"stream_diff_dw_near", 
"outlet_diff_dw_basin",
"outlet_diff_dw_scatch" 
)) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}

outlet_dist_dw_basin = log(outlet_dist_dw_basin) 

elv=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/elv.tif")),e)
elv[elv == -9999 ] <- NA

stream=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/stream.tif")),e)
stream[stream == 0 ] <- NA
stream_l=rasterToPolygons(stream)

stream_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/stream_vect.shp"))
basin_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/basin_shp.shp"))
lbasin_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/lbasin_shp.shp"))


pdf(paste0(dir2,"/figure/figure_tables/Fig11_plot_stream_distance.pdf") , width=7, height=4.55  )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(3,4) ,  xpd=NA    )

for (var in  c( 
"elv",
"stream_dist_up_near",
"stream_dist_up_farth",
"stream_dist_dw_near",
"outlet_dist_dw_basin",  
"outlet_dist_dw_scatch",  
"stream_dist_proximity", 
"stream_diff_up_near",   
"stream_diff_up_farth",  
"stream_diff_dw_near",
"outlet_diff_dw_basin",
"outlet_diff_dw_scatch"
)) {

n=100
if (var == "elv" )  { colF=colorRampPalette(c("darkgreen","yellow", "brown", "maroon","white" )) }
if (var != "elv" )  { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) }
colsF=colF(n)
cols_legend=rev(colsF)

options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

colsR = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]

print(var)
raster=get(var)

des=print(var)         

max=raster@data@max ; min=raster@data@min

if(var == "elv"     )             { des="Elevation & stream & basin"  ; max=1000  ; min=0 ;  at=c(0,500,1000)    ; labels=c("0m","500m","1000m") ; letter="a)" } 
if(var == "stream_dist_up_near" )  { max=450   ; min=min ;  at=c(min,250,max) ; labels=c("0m","250m",paste0(max,"m")) ; letter="b)" }    
if(var == "stream_dist_up_farth")  { max=12000 ; min=min ;  at=c(0,6000,11800) ; labels=c(paste0(min,"m"),"6000m","11000m") ; letter="c)" }    
if(var == "stream_dist_dw_near")  { max=800   ;   min=min ;  at=c(0,400,800)      ; labels=c("0m","400m","800m") ; letter="d)" }    
if(var == "outlet_dist_dw_basin")  { max=13   ;   min=0 ;  at=c(0,6.9,13)          ; labels=c("0m","1000m","550000m")     ; letter="f)" }    
if(var == "outlet_dist_dw_scatch") { max=max  ;   min=min ;  at=c(0,1300,2700)     ; labels=c("0m","1300m","2700m") ; letter="g)" }    
if(var == "stream_dist_proximity") { max=max  ;   min=min ;  at=c(0,250,497)       ; labels=c("0m","250m","500m") ; letter="h)" }    
if(var == "stream_diff_up_near")   { max=max  ;   min=min ;  at=c(0,130,270)       ; labels=c("0m","130m","270m") ; letter="i)" }    
if(var == "stream_diff_up_farth")  { max=max  ;   min=min ;  at=c(0,550,1160)      ; labels=c("0m","550m","1160m") ; letter="j)" }    
if(var == "stream_diff_dw_near")  { max=max  ;   min=min ;  at=c(-70,0,170,340)   ; labels=c("-70m","0m","170m","340m") ; letter="k)" }    
if(var == "outlet_diff_dw_basin")  { max=max  ;   min=min ;  at=c(0,600,1170)   ; labels=c("0m","600m","1200m") ; letter="l)" }    
if(var == "outlet_diff_dw_scatch") { max=max  ;   min=min ;  at=c(0,400,800)   ; labels=c("0m","400m","800m") ; letter="m)" }    

plot(raster, main=des , col=colsF, tck=-0.05, cex.axis=0.8, yaxt="n", xaxt="n", xlab="", ylab="", colNA="grey30", legend=FALSE, cex.main=0.8, font.main=2, interpolate=FALSE)

plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.56 , lwd = 0  ) ,  smallplot=c(0.86,0.90, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=colsF)

if(var == "elv" ){ lines(stream_l ,  lwd=0.01 , cex=0.01 , col='black')
lines(stream_l ,  lwd=0.01 , cex=0.01 , col='black')
# lines(basin_l  ,  lwd=0.01 , cex=0.01 , col='red')
lines(lbasin_l ,  lwd=0.01 , cex=0.01 , col='purple')
 }

text( 8.64, 44.506 , letter ,  font=2   ,   xpd=TRUE , cex=1 )

if(var == "stream_diff_up_farth" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "stream_diff_up_farth" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "stream_diff_up_farth" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "stream_diff_up_farth" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/figure_tables/Fig11_plot_stream_distance.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig11_plot_stream_distance.pdf
