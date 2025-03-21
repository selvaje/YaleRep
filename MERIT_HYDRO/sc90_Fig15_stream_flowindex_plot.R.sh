#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_stream_var_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_stream_var_plot.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc90_stream_var_plot.R.sh.%J.out

# bash  /project/fas/sbsc/hydro/scripts/MERIT_HYDRO/sc90_stream_flowindex_plot.R.sh

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
"spi",
"sti",
"cti"
)) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}

elv=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/elv.tif")),e)
elv[elv == -9999 ] <- NA

spi=sqrt(spi)
sti=sqrt(sti)

stream=crop(raster(paste0(dir2,"/figure/data_stream_var_plot/stream.tif")),e)
stream[stream == 0 ] <- NA
stream_l=rasterToPolygons(stream)

stream_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/stream_vect.shp"))
lbasin_l=readOGR(paste0(dir2,"/figure/data_stream_var_plot/lbasin_shp.shp"))

pdf(paste0(dir2,"/figure/figure_tables/Fig14_plot_stream_flowindex.pdf") , width=5.6, height=1.87  )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(1,3) ,  xpd=NA    )

for (var in  c(
"spi",
"sti",
"cti"
)) {

n=100
if (var == "elv" )  { colF=colorRampPalette(c("darkgreen","yellow", "brown", "maroon","white" )) ; colsF=colF(n)   }
if (var != "elv" )  { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) ; colsF=colF(n) }
cols_legend=rev(colsF)

print(var)
raster=get(var)

des=print(var)         


max=raster@data@max ; min=raster@data@min
if(var == "spi" )  { max=max ; min=0 ;  at=c(0,50,87)          ; labels=c("0","2500","7600") ; letter="a)" }    
if(var == "sti")   { max=max ; min=0 ;  at=c(0,40,95)            ; labels=c("0","2000","900") ; letter="b)" }    
if(var == "cti")   { max=max ; min=0 ;  at=c(0,340000000,740000000) ; labels=c("0",  expression(paste("35*10"^"7")) ,    expression(paste("74*10"^"7"))  ) ; letter="c)" }    

plot(raster, main=des , col=colsF, tck=-0.05, cex.axis=0.8, yaxt="n", xaxt="n", xlab="", ylab="", colNA="grey30", legend=FALSE, cex.main=0.8, font.main=2, interpolate=FALSE)
plot(raster, axis.args=list(at=at,labels=labels,line=-0.85,tck=0,cex.axis=0.56,lwd = 0),smallplot=c(0.86,0.90, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75,col=colsF)


text( 8.64, 44.506 , letter ,  font=2   ,   xpd=TRUE , cex=1 )

if(var == "spi" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "spi" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "spi" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "spi" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/figure_tables/Fig14_plot_stream_flowindex.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig14_plot_stream_flowindex.pdf
