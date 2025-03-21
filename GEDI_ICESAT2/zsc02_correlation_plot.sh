#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc02_correlation_plot.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc02_correlation_plot.sh.%J.err
#SBATCH --job-name=sc02_correlation_plot.sh
#SBATCH --mem=2G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc02_correlation_plot.sh

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export RAM=/dev/shm
export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/txt

# cat $TXT/gedi_icesat2_???????.txt >  $TXT/gedi_icesat2_4cor.txt

module load R/3.4.4-foss-2018a-X11-20180131 
R  --vanilla --no-readline   -q  <<EOF
library(ggplot2) 
## some pretty colors
library(RColorBrewer)
library(viridis)

k <- 10
# my.cols <- rev(brewer.pal(k, "RdYlBu"))
# Lab.palette <- colorRampPalette(c("blue", "orange", "red"), space = "Lab")

gedi_icesat = read.table ("/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/txt/gedi_icesat2_4cor.txt")
names(gedi_icesat) = c("gedi","icesat")

maxlim <- 50
pdf( "/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/txt/gedi_icesat2_4cor22.pdf" , width=5, height=5 )
par(mar=c(5,5,1,1))
smoothScatter(gedi_icesat, nrpoints=0, xlim = c(0, maxlim), ylim = c(0, maxlim),
              xlab = 'GEDI tree height (m)', ylab = 'ICESat-2 tree height (m)', pch=19, cex=.60,
              cex.lab=1.5, cex.axis = 1.5, colramp = colorRampPalette(c('white', viridis(5, direction = -1, option = 'A'))), 
              transformation = function(x) x^0.88 )

dev.off()

EOF
