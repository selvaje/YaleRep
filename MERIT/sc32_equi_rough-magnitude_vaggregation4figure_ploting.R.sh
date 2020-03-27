#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc32_equi_rough-magnitude_vaggregation4figure_ploting.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc32_equi_rough-magnitude_vaggregation4figure_ploting.R.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc32_equi_rough-magnitude_vaggregation4figure_ploting.R.sh
#SBATCH --mem=80G


# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc32_equi_rough-magnitude_vaggregation4figure_ploting.R.sh 

export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export RAM=/dev/shm
export KM=1.00

source ~/bin/gdal


module load R/3.4.4-foss-2018a-X11-20180131



R --vanilla --no-readline   -q  <<'EOF'
library(rgdal)
library(raster)
library(lattice)
library(rasterVis)

for ( CT  in c("AF", "AN", "AS", "EU", "NA", "OC", "SA")  ) {

raster =raster(paste0("/project/fas/sbsc/ga254/dataproces/MERIT/gdrive100m/rough-magnitude_1km/",CT,"_rough-magnitude_1km.tif"))

pdf(paste("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/figure/",CT,"_rough-magnitude.pdf", sep=""))

n=100
colR=colorRampPalette(c("blue","green","yellow", "orange" , "red", "brown", "black" ))
cols=colR(n)
res=1e7             # res=1e4 for testing and res=1e6 for the final product

min=0
max=20

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
print ( levelplot(raster, col.regions=colR(n), scales=list(cex=1.5), cuts=99,at=at,colorkey=list(space="bottom",adj=2 , labels=list( cex=1.5)), panel=panel.levelplot.raster, margin=F , maxpixels=res,ylab="", xlab="" , useRaster=T) )


dev.off() 

}

EOF




