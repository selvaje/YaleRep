#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 20  -N 1  
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_equi_multiRougDevaggregation4figure.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_equi_multiRougDevaggregation4figure.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc31_equi_multiRougDevaggregation4figure.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc32_equi_multiRougDevaggregation4figure_ploting.R.sh

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT_BK
export RAM=/dev/shm
export KM=5.00

module load Apps/R/3.3.2-generic





R --vanilla --no-readline   -q  <<'EOF'
library(rgdal)
library(raster)
library(lattice)
library(rasterVis)

for ( CT  in c("AF", "AN", "AS", "EU", "NA", "OC", "SA")  ) {

raster =raster(paste0("/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT_BK/deviation/",CT,"_devi_5km.tif"))

pdf(paste("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure/",CT,"_multiroughnes.pdf", sep=""))

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)
res=1e8             # res=1e4 for testing and res=1e6 for the final product

min=-1
max=1

raster[raster>max] <- max
raster[raster<min] <- min

raster
#  axis.line = list(col='transparent') 
lattice.options(
   layout.heights=list(bottom.padding=list(x=2), top.padding=list(x=2)),
   layout.widths=list(left.padding=list(x=4), right.padding=list(x=4)),
   axis.padding=list(factor=0.5) 
)

lattice.options(axis.padding=list(factor=0.5))

at=seq(min,max,length=n) 
print ( levelplot(raster,   col.regions=colR(n),   scales=list(cex=1.5) ,   cuts=99,at=at,colorkey=list(space="bottom",adj=2 , labels=list( cex=1.5)), panel=panel.levelplot.raster, margin=F  , maxpixels=res,ylab="", xlab="" , useRaster=T) )


dev.off() 

}

EOF




