#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc04_peatmap_shp2tif.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc04_peatmap_shp2tif.sh.%J.err
#SBATCH --job-name=sc04_peatmap_shp2tif.sh
#SBATCH --mem-per-cpu=30000M
#SBATCH --array=17 ####--array=1-19

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/PEATMAP/sc04_peatmap_shp2tif.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/sc04_peatmap_shp2tif.sh

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP
#DIR=/home/jaime/Data/PEATMAP

SHAPEFILE=$( find $DIR/temp -name '*.shp'  | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
name=$( basename ${SHAPEFILE} .shp )

EXTENSION=$( ogrinfo $SHAPEFILE -so -al | grep Extent | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | awk '{ printf("%.1f\n", $1 , $2 , $3 , $4 ) }' )

echo -------------------
echo rasterizing $SLURM_ARRAY_TASK_ID $name
echo -------------------

gdal_rasterize -tr 0.000833333333333 -0.000833333333333 --config GDAL_CACHEMAX 4000 -te $EXTENSION -a_srs EPSG:4326 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -a diss -l ${name} $SHAPEFILE $DIR/out/${name}.tif

exit
#

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP/out/AF_Peatland_RP.tif /home/jaime/Data/PEATMAP



SHAPEFILE=temp/SEA_Peatland_fixed_RP.shp
name=$( basename ${SHAPEFILE} .shp )

EXTENSION=$( ogrinfo $SHAPEFILE -so -al | grep Extent | grep -Eo '[+-]?[0-9]+([.][0-9]+)?' | awk '{ printf("%.1f\n", $1 , $2 , $3 , $4 ) }' )

echo -------------------
echo rasterizing $SLURM_ARRAY_TASK_ID $name
echo -------------------

gdal_rasterize -tr 0.000833333333333 -0.000833333333333 --config GDAL_CACHEMAX 4000 -te $EXTENSION -a_srs EPSG:4326 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -a diss -l ${name} $SHAPEFILE out/${name}.tif















##############################################################################
##############################################################################
##############################################################################


#export MASKly=$DIR/ElevationLR.tif

MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

gdalbuildvrt  -overwrite   $DIR/out/all_peatmap.vrt  $DIR/out/*.tif

pksetmask -i $DIR/out/all_peatmap.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/PEATMAP.tif -co COMPRESS=DEFLATE -co ZLEVEL=9
