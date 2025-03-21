#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc90_stream_var_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc90_stream_var_plot.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc90_stream_var_plot.R.sh.%J.out

# bash  /project/fas/sbsc/hydro/scripts/MERIT_HYDRO/sc90_stream_var_plot.R.sh

source ~/bin/gdal3
module load R/3.5.3-foss-2018a-X11-20180131

OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/figure/data_stream_var_plot
 MHSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
 MHPR=/gpfs/loomis/project/sbsc/hydro/dataproces/MERIT_HYDRO

cd /home/selv/tmp/figure_hydrography90m/figure/data_stream_var_plot

pkstat --hist  -src_min 523273176 -src_max  523342623 -i stream.tif  | grep -v " 0" | awk '{print $1}'  > stream.hist

echo "0 0" > stream.rec
paste stream.hist  <(shuf -i 1-683 -n 683  -r ) >> stream.rec

pkreclass -ot Int16  -code stream.rec   -i stream.tif  -o   stream_rec.tif 
pksetmask -m elv.tif -msknodata -9999   -nodata -9999  -i stream_rec.tif -o stream_NA.tif 

pkstat --hist  -src_min   523273166 -src_max  523342613   -i basin.tif  | grep -v " 0" | awk '{print $1}'  > basin.hist
                          
echo "0 0" > basin.rec
paste basin.hist  <(shuf -i 1-708 -n 708  -r ) >> basin.rec
pkreclass -ot Int16  -code basin.rec   -i basin.tif  -o   basin_rec.tif 

gdaldem hillshade  -s 57103   -multidirectional   -alg Horn  elv.tif shade.tif

R  --vanilla --no-readline   -q  <<'EOF'

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

e = extent (8.64, 8.8, 44.4, 44.5 ) 

dir1="/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_HYDRO"
dir2="/home/selv/tmp/figure_hydrography90m/"

   EU_elv  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/EU_elv.tif")) ,c(-10, 44, 35, 65.5))
   EU_elv[EU_elv == -9999 ] <- NA

for (var in  c("elv","shade","stream_NA")) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif")) ,e)
   raster[raster == -9999 ] <- NA
   assign(paste0(var) , raster )
}

for (var in  c("flow")){
   print(var)
   raster  <- log(crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif"))  ,e))
   raster[raster == -9999999 ] <- NA
   assign(paste0(var) , raster )
}

for (var in  c( "basin_rec", "lbasin", "outlet")) { 
   print(var)
   raster  <- crop(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif"))  ,e)
   raster[raster == 0 ] <- NA
   assign(paste0(var) , raster )
}

outlet_p = rasterToPoints(outlet)
outlet_p

for (var in  c("dir")) { 
   print(var)
   raster  <- crop(abs(raster(paste0(dir2,"/figure/data_stream_var_plot/", var , ".tif")) ) ,e)
   raster[raster == -10 ] <- NA
   assign(paste0(var) , raster )
}

dir

print("start to plot")

colsR = grDevices::colors()[grep('gr(a|e)y', grDevices::colors(), invert = T)]
colsR
pdf(paste0(dir2,"/figure/figure_tables/Fig6_plot_main_hydrog.pdf") , width=7, height=3.2  )

set.seed(3)

par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(2,4) ,  xpd=NA    )

for (var in c("EU_elv","elv","shade","flow","dir", "lbasin", "stream_NA", "basin_rec" )) { 

print(var)
raster=get(var)

n=100
if (var == "elv" || var == "EU_elv"  )  { colF=colorRampPalette(c("darkgreen","yellow", "brown", "maroon","white" )) }
if (var != "elv" && var != "EU_elv" )  { colF=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" )) }
colsF=colF(n)
cols_legend=rev(colsF)
options(scipen=10)
trunc <- function(x, ..., prec = 0) base::trunc(x * 10^prec, ...) / 10^prec

if(var == "EU_elv"    )   { des="Europe elevation (MERIT Hydro)"  ; cols=colsF ; max=4000 ; min=0 ;  at=c(0,2000,4000 ) ; labels=c("0m","2000m","4000m") ; letter="a)" }    
if(var == "elv"       )   { des="Elevation (MERIT Hydro)"         ; cols=colsF ; max=1000 ; min=0 ;  at=c(0,500,1000 )  ; labels=c("0m","500m","1000m")  ; letter="b)" }    
if(var == "shade"     )   { des="Shaded relief"                   ; cols=colsF ; max=237  ; min=1 ;  at=c(1,110,237)    ; labels=c("0°","110°","237°")   ; letter="c)" }    

if(var == "flow") {des="Flow accumulation"; cols=colsF; max=27; min=0 ;  at=c(0,15,27) ; labels=c(expression(paste("0km"^"2")),expression(paste("15km"^"2")),expression(paste("30km"^"2"))) ; letter="d)" }    
if(var == "dir" ) { des="Flow direction"  ; cols=c("red", "blue","yellow","green","orange","magenta","brown","black"); max=8; min=1; at=c(1,2,3,4,5,6,7,8) ; labels=c("NE","N","NW","W","SW","S","SE","E"); letter="f)"}

pal=append ( "antiquewhite1" ,  colsR)
if(var == "basin_rec"                             )   { des="Sub-catchment"      ; cols=pal[-1]    ; letter="i)" }    
if(var == "stream_NA"                    )   { des="Stream segment & outlet"     ; cols=pal    ; letter="h)" }    
if(var == "lbasin"                    )   { des="Drainage basin"        ; cols=sample(colsR, 25)      ; letter="g)" }    

plot(raster, main=des , col=cols, tck=-0.05, cex.axis=0.8 , yaxt="n" , xaxt="n" , xlab="" , ylab="" , colNA = "grey30" ,  legend=FALSE  , cex.main=0.8 , font.main=2 , interpolate=FALSE )

if(var == "EU_elv" ||   var == "elv" ||   var == "shade" ||   var == "flow" || var == "dir") {
plot(raster, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.56 , lwd = 0  ) ,  smallplot=c(0.86,0.90, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)}

if( var == "elv" || var == "shade" || var == "flow" || var == "dir" || var == "lbasin" || var == "stream_N" || var == "lbasin" || var == "stream_NA" || var == "basin_rec" ) {
text( 8.64, 44.506 , letter ,  font=2   ,   xpd=NA , cex=1 )
}

if(var == "EU_elv" ){text( -11.5, 67.5 , letter ,  font=2   ,   xpd=NA , cex=1 )}

if(var == "EU_elv" ){ points(8.7, 44.42 , pch=0 , cex=1.2 , col='red') }

if(var == "stream_NA" ){ points(outlet_p , pch=16 , cex=0.8 , col='red') }

if(var == "dir" )   { text(8.65, 44.395, "8.64°", font=2,  srt=0,  xpd=NA, cex=0.8)}
if(var == "dir" )   { text(8.79, 44.395, "8.80°", font=2,  srt=0,  xpd=NA, cex=0.8)}

if(var == "dir" )   { text(8.634, 44.492, "44.5°", font=2,  srt=90,  xpd=NA, cex=0.8)}
if(var == "dir" )   { text(8.634, 44.41,  "44.4°", font=2,  srt=90,  xpd=NA, cex=0.8)}

if(var == "basin_rec" ||   var == "stream_NA" ||   var == "lbasin" ){
text(  8.815, 44.450 ,   "Random colour for unit ID"   , font=2 ,  srt=90  ,  xpd=TRUE , cex=0.6 )
}

if( var == "stream_NA" ){
text(  8.825, 44.450 ,   "Outlet in red point"   , font=2 ,  srt=90  ,  xpd=TRUE , cex=0.6 )
}
}

dev.off()
q()
EOF

cp /home/selv/tmp/figure_hydrography90m/figure/figure_tables/Fig6_plot_main_hydrog.pdf ~/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure/Fig6_plot_main_hydrog.pdf
