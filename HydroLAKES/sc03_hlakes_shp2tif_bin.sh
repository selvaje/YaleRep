#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_hlakes_shp2tif_bin.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_hlakes_shp2tif_bin.sh.%J.err
#SBATCH --job-name=sc03_hlakes_shp2tif_bin.sh
#SBATCH --mem-per-cpu=20000M
#SBATCH --array=1   ###  each run represents a lake type (--array=1-3)

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/HydroLAKES/sc03_hlakes_shp2tif_bin.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc03_hlakes_shp2tif_bin.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

# The HydroLAKES dataset has a column "Lake_type": 1. Lake, 2. Reservoir
# (mostly based on information from the GRanD database), and 3. Lake
# control (i.e. natural lake with regulation structure). Do we want three
# raster files each for each of these three categories?. The value of the
# pixels will be extracted based on the column "Vol_total" (Total lake or
# reservoir volume, in million cubic meters).
#
##################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Yes create the 3 classes as binary files 0/1.
##################!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

####   TILES

# generate the file tile.txt before running the script
#    xmin ymin xmax ymax
# echo -180 10  -60 85 a >  $DIR/tile.txt
# echo  -60 10    0 85 b >> $DIR/tile.txt
# echo    0 10   85 85 c >> $DIR/tile.txt
# echo   85 10  180 85 d >> $DIR/tile.txt
#
# echo -180 -60  -60 10 e >> $DIR/tile.txt
# echo  -60 -60    0 10 f >> $DIR/tile.txt
# echo    0 -60   85 10 g >> $DIR/tile.txt
# echo   85 -60  180 10 h >> $DIR/tile.txt


### extract only the polygons of each category: 1. Lake, 2. Reservoir
# (mostly based on information from the GRanD database), and 3. Lake
# control (i.e. natural lake with regulation structure).

ogr2ogr -sql "SELECT diss,Lake_type FROM HydroLAKES_polys_v10 WHERE Lake_type=$SLURM_ARRAY_TASK_ID"  $DIR/shp/LakeType_${SLURM_ARRAY_TASK_ID}.shp $DIR/HydroLAKES_polys_v10_shp/HydroLAKES_polys_v10.shp

cat  $DIR/tile.txt | xargs -n 5 -P 8 bash -c $'

gdal_rasterize -tr 0.000833333333333 -0.000833333333333 -te $1 $2 $3 $4 -ot Int16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a diss -l LakeType_${SLURM_ARRAY_TASK_ID} $DIR/shp/LakeType_${SLURM_ARRAY_TASK_ID}.shp $DIR/tif_bin/LakeType_${SLURM_ARRAY_TASK_ID}_tile_$5.tif

' _

gdalbuildvrt  -overwrite   $DIR/out/LakeType_${SLURM_ARRAY_TASK_ID}.vrt  $DIR/tif_bin/LakeType_${SLURM_ARRAY_TASK_ID}_tile_{a,b,c,d,e,f,g,h}.tif

pksetmask -i $DIR/out/LakeType_${SLURM_ARRAY_TASK_ID}.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/out/LakeType_${SLURM_ARRAY_TASK_ID}.tif -co COMPRESS=DEFLATE -co ZLEVEL=9


exit


gdal_translate -projwin -5 52 -3 50  -co COMPRESS=DEFLATE -co ZLEVEL=9 /gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES/out/LakeType_2.tif   out/ss_t2.tif

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES/out/LakeType_2.tif  /home/jaime/data/
