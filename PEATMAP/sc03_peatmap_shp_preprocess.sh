#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1
#SBATCH -t 15:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_peatmap_shp_preprocess.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_peatmap_shp_preprocess.sh.%J.err
#SBATCH --job-name=sc03_peatmap_shp_preprocess.sh
#SBATCH --mem-per-cpu=20000M

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/PEATMAP/sc03_peatmap_shp_preprocess.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/sc03_peatmap_shp_preprocess.sh

module load R
source ~/bin/gdal

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP
cd $DIR

####    Chunk of R code to add column to dbf files  #################

###  not run in the sbatch

# R --vanilla --no-readline -q  << "EOF"
#
#   library(foreign)
#
#   lf = list.files("SHP", ".dbf", full.names = TRUE, recursive = TRUE)
#
#   for (i in 1:length(lf)){
#     tb = read.dbf(lf[[i]])
#     tb$diss = 1
#     tb$diss = as.integer(tb$diss)
#     write.dbf(tb, lf[[i]])
#   }
#
# EOF
#####################################################################

# Spatial reference system: Geographic coordinate system
# Datum: WGS84
# Projected Coordinate System: World Cylindrical Equal Area
# ESRI:54034 - World_Cylindrical_Equal_Area - Projected
# EPSG:3410???
# EPSG:9834???

###   REPROJECT

echo $( find SHP -name '*.shp' )  | xargs -n 1 -P 8 bash -c $'

SHAPEFILE=$1
name=$( basename ${SHAPEFILE} .shp )

echo #-----
echo reprojecting $name
echo #-----

ogr2ogr -t_srs EPSG:4326 temp/${name}_RP.shp ${SHAPEFILE}

_ '

exit

## same chunk as above but in a for loop

for SHAPEFILE in $( find $DIR/SHP -name '*.shp' ); do

  # if [[ "${SHAPEFILE}" ==  '/home/marquez/Data/PEATMAP/SHP/South_America/SA_Peatland.shp' ]]; then
  #  continue
  # fi

  name=$( basename ${SHAPEFILE} .shp )

  echo reprojecting $name
  # ESRI:54034 - World_Cylindrical_Equal_Area - Projected
  # EPSG:3410???
  # EPSG:9834???
  ogr2ogr -t_srs EPSG:4326 temp/${name}_RP.shp ${SHAPEFILE}

done
