#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_dif_normalized_stats.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_dif_normalized_stats.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc02_derivative_stats.sh 

# sbatch /home/fas/sbsc/ga254/scripts/NED_MERIT/sc02_elevation_deviation_index.R.sh
# module load Apps/R/3.0.3  
# module load Apps/R/3.1.1-generic

gdal
module load R/3.4.4-foss-2018a-X11-20180131

cd /project/fas/sbsc/ga254/dataproces/NED_MERIT

R  --vanilla --no-readline   -q  <<'EOF'
library(ggplot2) 
library(rgdal)
library(raster)
library(gridExtra)   
  
rm(list = ls()) 

elev_M = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/NA/NA_066_048.tif") 
elev_N = raster ("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_066_048.tif") 
e = extent ( 6880000 , 6920000 ,  5190000 , 5228400 ) 
elev_M = crop ( elev_M  , e )
elev_N = crop ( elev_N  , e )

make_circ_filter<-function(radius, res){
  circ_filter<-matrix(NA, nrow=1+(2*radius/res), ncol=1+(2*radius/res))
  dimnames(circ_filter)[[1]]<-seq(-radius, radius, by=res)
  dimnames(circ_filter)[[2]]<-seq(-radius, radius, by=res)
  sweeper<-function(mat){
    for(row in 1:nrow(mat)){
      for(col in 1:ncol(mat)){
        dist<-sqrt((as.numeric(dimnames(mat)[[1]])[row])^2 +
                     (as.numeric(dimnames(mat)[[1]])[col])^2)
        if(dist<=radius) {mat[row, col]<-1}
      }
    }
    return(mat)
  }
  out<-sweeper(circ_filter)
  return(out)
}

cf<-make_circ_filter(11, 1) # 5  = radius 
cf

e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 ) 
elev_dif = crop ( elev_N - elev_M  , e )
elev_std = crop (raster::focal ( elev_N , w=cf  , fun=sd , na.rm=T ) , e )
slope = crop ( terrain(elev_N, opt='slope' , unit="degrees" ) , e ) 
str(slope)

# Elevation Deviation Index
edi    = elev_dif  /  elev_std   

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)

pdf( "/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/sc02_elevation_deviation_index_11x11.pdf"  , width=8, height=2.66 )
par (oma=c(2,2,2,1) , mar=c(0.4,0.5,1,1.9) , cex.lab=0.5 , cex=0.6 , cex.axis=0.4  ,   mfrow=c(1,3) ,  xpd=NA    )

max=elev_dif@data@max ; min=elev_dif@data@min 
at=c(round(min) + 5 , 0  ,  round(max) - 5 )
labels=c(round(min), 0  , round(max))

plot(elev_dif  , col=cols ,   yaxp=c(5201000, 5217400,1) , xaxp=c(6891000, 6909000,1) , cex.axis=1 ,  tck=-0.05,  main="Elevation diff. 3DEP - MERIT" , legend=FALSE , cex.main=1.2 , font.main=2  )
plot(elev_dif, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.9 , lwd = 0  ) ,  smallplot=c(0.88,0.92, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)
text(6912000 , 5219400  ,  font=2   ,   xpd=TRUE , cex=2 )


# max=slope@data@max ; min=slope@data@min 

# at=c( round (min) + 3   , round (max)  - 3  )
# labels=c( round(min)   , round (max)  )

# plot(slope  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main="Slope"  , legend=FALSE  , cex.main=1.2 , font.main=2 )
# plot(slope, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.9 , lwd = 0  ) ,  smallplot=c(0.88,0.92, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)

max=elev_std@data@max ; min=elev_std@data@min 
at=c(round(min) + 3 , 100 , round(max) - 3)
labels=c(round(min),  100 , round(max))

plot(elev_std  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main="Standard Deviation 3DEP"  , legend=FALSE  , cex.main=1.2 , font.main=2 )
plot(elev_std, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.8 , lwd = 0  ) ,  smallplot=c(0.88,0.92, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)

max=edi@data@max ; min=edi@data@min 
at=c( round ( min , digits = 2 ) + 0.2 , 0    , round ( max , digits = 2 ) - 0.2 )
labels=c( round ( min , digits = 2 )  , 0    , round ( max , digits = 2 ) )

plot(edi  , col=cols , yaxt="n" , xaxt="n" , xlab="" , ylab="" , main="Elevation Deviation Index"  , legend=FALSE  , cex.main=1.2 , font.main=2 )
plot(edi, axis.args=list( at=at , labels=labels , line=-0.85, tck=0 , cex.axis=0.9 , lwd = 0  ) ,  smallplot=c(0.88,0.92, 0.1,0.8), zlim=c( min, max ) , legend.only=TRUE , legend.width=1, legend.shrink=0.75 , col=cols)


dev.off()

EOF
