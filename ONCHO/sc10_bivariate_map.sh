#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_bivariate_map.sh.%j.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_bivariate_map.sh.%j.err
#SBATCH --job-name=sc10_bivariate_map.sh
#SBATCH --mem=100G

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc10_bivariate_map.sh

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO
cd $ONCHO/vector

source ~/bin/gdal3
module load R/4.1.0-foss-2020b

gdal_translate  -tr 0.008333333333333 0.008333333333333 -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/input/population/NGA_population_v2_0_gridded.tif /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/input/population/NGA_population_v2_0_gridded_1km.tif 

gdal_translate  -tr 0.008333333333333 0.008333333333333 -r average  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/input/population/NGA_population_v2_0_gridded_1km.tif   ) /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_all.tif /gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_all_1km.tif 

# che; un errore fatto in locale 


Rscript --vanilla  -e '

library(Rgadgets) 
library(ggplot2)
library(raster)
library(rgdal)
library(cowplot)

print("legend")

breaks <- 10
cmat <- rg_biv_cmat(breaks, style = 6)
legend <- rg_biv_get_legend(cmat, xlab="Population" , ylab="Suitability")
print("load raster")
x=raster("/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/input/population/NGA_population_v2_0_gridded_1km.tif")
y=raster("/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/prediction_all_1km.tif")
print("combine raster")
x
y
xy <- rg_biv_create_raster(x, y, breaks)
print("create map")
map <- rg_biv_plot_raster(xy, cmat=cmat, xlab="Population", ylab="Suitability")
ggsave2("/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO/prediction/bivariate_Population_Suitability.png", map)
' 

rm /tmp/prediction_all_crop.tif
