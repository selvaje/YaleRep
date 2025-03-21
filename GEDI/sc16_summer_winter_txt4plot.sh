#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc16_summer_winter_txt4plot.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc16_summer_winter_txt4plot.sh.%J.err
#SBATCH --job-name=sc16_summer_winter_txt4plot.sh
#SBATCH --mem=2G
##x_y_sensitivity 

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc16_summer_winter_txt4plot.sh

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export RAM=/dev/shm
export string=$string

labely=Degrade

export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/summer_winter_broadleaved_overlap_txt

cat $TXT/filter_*.txt >  $TXT/summer_winter_4plot.txt

cd $TXT

module load R/3.4.4-foss-2018a-X11-20180131 

R  --vanilla --no-readline   -q  <<'EOF'
library(ggplot2) 
## some pretty colors
library(RColorBrewer)
library(viridisLite)
library(viridis)

label = Sys.getenv('labely')
label = 'Variables'

k <- 10
# my.cols <- rev(brewer.pal(k, "RdYlBu"))
# Lab.palette <- colorRampPalette(c("blue", "orange", "red"), space = "Lab")

plot_file <- list.files(, pattern = '4plot.txt')
plot_table <- read.table(plot_file)

# names(plot_table) = c("All filtered", substr(plot_file, 4, 5) )
names(plot_table) = c("All filtered", label  )

maxlim <- 10
pdf( 'Variable_all_filtered.pdf', width=5, height=5 )
par(mar=c(5,5,1,1))
smoothScatter(plot_table, nrpoints=0, xlim = c(0, maxlim), ylim = c(0, maxlim),
              xlab = 'GEDI tree height (m)', ylab = label , pch=19, cex=.60,
              cex.lab=1.5, cex.axis = 1.5, colramp = colorRampPalette(c('white', viridis(5, direction = -1, option = 'A'))), 
              transformation = function(x) x^0.88 )

dev.off()

EOF