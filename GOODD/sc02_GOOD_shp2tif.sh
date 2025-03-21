#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_GOOD_shp2tif.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_GOOD_shp2tif.sh.%J.err
#SBATCH --job-name=sc02_GOOD_shp2tif.sh
#SBATCH --mem-per-cpu=20000M

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GOODD/sc02_GOOD_shp2tif.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GOODD
#export DIR=/data/shared/GOOD

## MASK
#gdal_translate -tr 0.000833333333333 -0.000833333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 /data/shared/MERIT/elev/Elevation.tif $DIR/ElevationLR.tif

#export MASKly=$DIR/ElevationLR.tif
export MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

####   TILES
#    xmin ymin xmax ymax
echo -180 10  -60 84 a >  $DIR/tile.txt
echo  -60 10    0 84 b >> $DIR/tile.txt
echo    0 10   85 84 c >> $DIR/tile.txt
echo   85 10  180 84 d >> $DIR/tile.txt

echo -180 -56  -60 10 e >> $DIR/tile.txt
echo  -60 -56    0 10 f >> $DIR/tile.txt
echo    0 -56   85 10 g >> $DIR/tile.txt
echo   85 -56  180 10 h >> $DIR/tile.txt

cat  $DIR/tile.txt | xargs -n 5 -P 8 bash -c $'

gdal_rasterize -tap -tr 0.000833333333333 -0.000833333333333 -te $1 $2 $3 $4 -ot Int16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a diss -l GOOD2_dams $DIR/GOOD2_dams.shp $DIR/tile_$5.tif

' _

gdalbuildvrt  -overwrite   $DIR/all_dams.vrt  $DIR/tile_{a,b,c,d,e,f,g,h}.tif

pksetmask -i $DIR/all_dams.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/GOOD2_dams.tif -co COMPRESS=DEFLATE -co ZLEVEL=9

#gdal_translate  -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/all_dams.vrt $DIR/GOOD2_dams.tif
rm tile*
rm all_dams.vrt

exit


## small subset to verify
gdal_translate -projwin -5 54 -2 50  -co COMPRESS=DEFLATE -co ZLEVEL=9 GOOD2_dams.tif subetGOOD.tif
