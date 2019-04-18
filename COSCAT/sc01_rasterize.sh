#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_rasterize.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_rasterize.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_rasterize.sh


# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/COSCAT/sc01_rasterize.sh

# Extent: (-180.000000, -55.500000) - (180.000000, 83.500000) 

# publication at https://www.hydrol-earth-syst-sci.net/17/2029/2013/hess-17-2029-2013.html
# file download from https://www.hydrol-earth-syst-sci.net/17/2029/2013/hess-17-2029-2013-supplement.zip  file name Continents.shp chang to COSCAT.shp

gdal_rasterize -ot Int16  -a_nodata 0    -te -180 -56 +180 +84 -tr 0.008333333333333333 0.008333333333333333  -co COMPRESS=DEFLATE -co ZLEVEL=9   -a "SBCODE"  -a_nodata 0  -l "COSCAT"  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/shp/COSCAT.shp  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/COSCAT/tif/COSCAT_1km.tif 



