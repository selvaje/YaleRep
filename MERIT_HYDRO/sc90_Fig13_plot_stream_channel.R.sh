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

# rm *_msk.tif
# for file in   channel_{curv,dist,elv,grad}*.tif ; do
#     filename=$(basename $file .tif)
#     pksetmask -m $file   -msknodata -9999999     -nodata -1  -i $file -o ${filename}_msk1.tif
#     pksetmask -m elv.tif -msknodata -9999  -nodata -9999     -i ${filename}_msk1.tif  -o ${filename}_msk.tif
#     rm ${filename}_msk1.tif
# done 

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
"channel_grad_dw_seg",
"channel_grad_up_seg",
"channel_grad_up_cel",
"channel_curv_cel",
"channel_elv_dw_seg",
"channel_elv_up_seg",
"channel_elv_up_cel",
"channel_elv_dw_cel",
"channel_dist_dw_seg",
"channel_dist_up_seg",
"channel_dist_up_cel"
)) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , "_msk.tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}

elv=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/elv.tif")),e)
elv[elv == -9999 ] <- NA

stream=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/stream.tif")),e)
stream[stream == 0 ] <- NA
stream_l=rasterToPolygons(stream)

stream_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/stream_vect.shp"))
lbasin_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/lbasin_shp.shp"))

pdf(paste0(dir2,"/figure/figure_tables/Fig12_plot_stream_channel.pdf") , width=7, height=4.55  )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(3,4) ,  xpd=NA    )

for (var in  c(
"elv",
"channel_grad_dw_seg",
"channel_grad_up_seg",
"channel_grad_up_cel",
"channel_curv_cel",
"channel_elv_dw_seg",
"channel_elv_up_seg",
"channel_elv_up_cel",
"channel_elv_dw_cel",
"channel_dist_dw_seg",
"channel_dist_up_seg",
"channel_dist_up_cel")) {

n=100
if (var == "elv" )  { colF=colorRampPalette(c("darkgreen","yellow", "brown", "maroon","white" )) ; colsF=colF(n)   }
if (var != "elv" )  { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) ; colsF=append ( "antiquewhite1",colF(n)) }
cols_legend=rev(colsF)

print(var)
raster=get(var)

des=print(var)         

channel_grad_dw_seg[ channel_grad_dw_seg > 0.0001 ] <- sqrt(channel_grad_dw_seg )
channel_grad_up_cel[ channel_grad_up_cel > 0.0001 ] <- log(sqrt(channel_grad_up_cel ))

channel_elv_up_cel[channel_elv_up_cel > 150 ] <- 150 

max=raster@data@max ; min=raster@data@min
if(var == "elv"     )             { des="Elevation & stream & basin" ; max=1000 ; min=0 ;  at=c(0,500,1000) ; labels=c("0m","500m","1000m") ; letter="a)" }
if(var == "channel_grad_dw_seg" ) { max=max ; min=1 ;  at=c(1,400,760)          ; labels=c("0","0.16","0.58") ; letter="b)" }    
if(var == "channel_grad_up_seg")  { max=max ; min=1 ;  at=c(1,700000,1300000)   ; labels=c("0","0.7","1.3") ; letter="c)" }    
if(var == "channel_grad_up_cel")  { max=max ; min=1 ;  at=c(0,0.5,1)            ; labels=c("0","0.6","1.21") ; letter="d)" }    
if(var == "channel_curv_cel")     { max=max ; min=1 ;  at=c(10,500000,990000)   ; labels=c(expression(paste("0m"^"-1")),expression(paste("0.5m"^"-1")),expression(paste("1m"^"-1"))); letter="f)"} 
if(var == "channel_elv_dw_seg")   { max=max ; min=1 ;  at=c(10,350,700)     ; labels=c("0m","350m","700m") ; letter="g)" }    
if(var == "channel_elv_up_seg")   { max=max ; min=1 ;  at=c(10,350,700)     ; labels=c("0m","350m","700m") ; letter="h)" }    
if(var == "channel_elv_up_cel")   { max=max ; min=1 ;  at=c(1,70,140)       ; labels=c("0m","70m","140m") ; letter="i)" }    
if(var == "channel_elv_dw_cel")   { max=max ; min=1 ;  at=c(1,60,120)       ; labels=c("0m","60m","120m") ; letter="j)" }    
if(var == "channel_dist_dw_seg")  { max=max ; min=1 ;  at=c(10,1200,2400)   ; labels=c("0m","1200m","2400m") ; letter="k)" }    
if(var == "channel_dist_up_seg")  { max=max ; min=1 ;  at=c(10,1200,2400)      ; labels=c("0m","1200m","2400m") ; letter="l)" }    
if(var == "channel_dist_up_cel")  { max=max ; min=1 ;  at=c(1,55,110)       ; labels=c("0m","55m","110m") ; letter="m)" }    

plot(raster, main=des , col=colsF, tck=-0.05, cex.axis=0.8, yaxt="n", xaxt="n", xlab="", ylab="", colNA="grey30", legend=FALSE, cex.main=0.8, font.main=2, interpolate=FALSE)

plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.56 , lwd = 0  ) ,  smallplot=c(0.86,0.90, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=colsF)

if(var == "elv" ){ lines(stream_l ,  lwd=0.01 , cex=0.01 , col='black')
lines(stream_l ,  lwd=0.01 , cex=0.01 , col='black')
# lines(basin_l  ,  lwd=0.01 , cex=0.01 , col='red')
lines(lbasin_l ,  lwd=0.01 , cex=0.01 , col='purple')
 }

text( 8.64, 44.506 , letter ,  font=2   ,   xpd=TRUE , cex=1 )

if(var == "channel_elv_dw_cel" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "channel_elv_dw_cel" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "channel_elv_dw_cel" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "channel_elv_dw_cel" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/figure_tables/Fig12_plot_stream_channel.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig12_plot_stream_channel.pdf
