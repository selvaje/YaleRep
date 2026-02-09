#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2
#SBATCH -t 06:00:00
#SBATCH -J SOILGRIDS2_downscale
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/SOILGRIDS2_downscale.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/SOILGRIDS2_downscale.%J.err
#SBATCH --mem=16G

###===============================================
module load StdEnv
module load foss/2022b
module load GDAL/3.6.2
###===============================================

gdal_translate -tr 0.083333333333 0.0833333333333 \
	       -co COMPRESS=LZW \
	       -r nearest \
	       -co ZLEVEL=9 \
	       /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/clay/wgs84_250m_grow/clay_0-200cm.vrt \
	       /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2_DERIVED/clay_10km.tif
