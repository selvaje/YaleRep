#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 10  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc03_GranD_shp2tif.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc03_GranD_shp2tif.sh.%J.err
#SBATCH --job-name=sc03_GranD_shp2tif.sh
#SBATCH --mem-per-cpu=20000M
####SBATCH --array=1958-2017%5
####SBATCH --array=1958
#SBATCH --array=1959-2017

## copy to scripts
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/GranD/sc03_GranD_shp2tif.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GRAND/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GRAND/sc03_GranD_shp2tif.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND
#export DIR=/home/jaime/Data/Grand/

export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

#export YEAR=1958
export YEAR=$SLURM_ARRAY_TASK_ID

ogr2ogr -sql " SELECT CAP_MCM, YEAR, teil_id  FROM Grand_Dams  WHERE ( YEAR  <= $YEAR ) " $DIR/shp/GRanD_dams_v1_3_${YEAR}.shp $DIR/Grand_Dams.shp

#ogr2ogr -sql " SELECT CAP_MCM, YEAR, teil_id  FROM Grand_Dams  WHERE ( YEAR  <= 1958 ) " GRanD_dams_v1_3_1958.shp Grand_Dams.shp

### identify unique teil ids and save to file
export TEILID=$( ogrinfo $DIR/shp/GRanD_dams_v1_3_${YEAR}.shp -sql "SELECT DISTINCT teil_id FROM GRanD_dams_v1_3_${YEAR}" | grep 'teil_id (Integer) =' | cut -d " " -f 6 )

#calculate in paralel the raster of dams for each tile
#cat $DIR/tile_id_${YEAR}.txt  |  xargs  -n 1 -P 10  bash -c $'
echo $TEILID  |  xargs  -n 1 -P 10  bash -c $'

ID=$1

### create each the teil and extract extent
ogr2ogr -sql "SELECT * FROM Grid_Teil WHERE id=\'${ID}\'"  $DIR/shp/teil_${ID}_${YEAR}.shp $DIR/Grid_Teil.shp

EXTENSION=$( ogrinfo $DIR/shp/teil_${ID}_${YEAR}.shp -so -al | grep Extent | grep -Eo \'[+-]?[0-9]+([.][0-9]+)?\' )

### clip the points of that teil
ogr2ogr -sql "SELECT CAP_MCM FROM GRanD_dams_v1_3_${YEAR} WHERE teil_id=\'${ID}\'"  $DIR/shp/dams_teil_${ID}_${YEAR}.shp $DIR/shp/GRanD_dams_v1_3_${YEAR}.shp

### finally rasterize ---  without the following flag:(-a_nodata -9999), to obtain 0 where no dams
### the following line assumes that we will have one point per pixel
gdal_rasterize -tr 0.000833333333333 -0.000833333333333 -te $EXTENSION -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -a CAP_MCM -l dams_teil_${ID}_${YEAR} $DIR/shp/dams_teil_${ID}_${YEAR}.shp $DIR/tif/GRanD_dams_${YEAR}_teil_${ID}.tif

' _


gdalbuildvrt -overwrite  $DIR/tif/GRanD_${YEAR}.vrt   $DIR/tif/GRanD_dams_${YEAR}_teil_*.tif

## extend the extent to the same as MERIT_HYDRO with zeros...
gdalwarp -te -180 -60 180 85 -of VRT $DIR/tif/GRanD_${YEAR}.vrt  $DIR/tif/GRanD_${YEAR}_extended.vrt

## mask the final output to keep continental areas
pksetmask -i $DIR/tif/GRanD_${YEAR}_extended.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/out/GRanD_${YEAR}.tif -co COMPRESS=DEFLATE -co ZLEVEL=9

####  remove temporal files for the particular year
rm -f  $DIR/shp/dams_teil_*_${YEAR}.shp
rm -f  $DIR/shp/teil_*_${YEAR}.shp
rm -f  $DIR/tif/GRanD_dams_${YEAR}_teil_*.tif

exit


## small subset to verify
gdal_translate -projwin -5 54 -2 50  -co COMPRESS=DEFLATE -co ZLEVEL=9 tif/GRanD_1958.vrt out/subsetVRT1958.tif

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND/out/GRanD_1958.tif /home/jaime/Data/Grand

gdal_translate -projwin -5 54 -2 50  -co COMPRESS=DEFLATE -co ZLEVEL=9 out/GRanD_1958.tif  out/subset1958.tif

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND/out/subset1958.tif /home/jaime/Data/Grand

pksetmask -i out/subetGrand1958.tif -m out/subetmask.tif -msknodata=-9999 -nodata=-9999 -o out/GRanD_mask_1958.tif -co COMPRESS=DEFLATE -co ZLEVEL=9

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND/out/GRanD_mask_1958.tif /home/jaime/Data/Grand

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND/tif/GRanD_dams_1958_teil_475.tif /home/jaime/Data/Grand
