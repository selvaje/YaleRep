#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc21_water_bodies.sh.%j.out 
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc21_water_bodies.sh.%j.err
#SBATCH --job-name=sc21_water_bodies.sh 
#SBATCH --mem=40G

source ~/bin/gdal3
source ~/bin/pktools

## Set variables
INPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC210"
OUTPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC210_waterper"
RAM_DIR="/dev/shm/dataproces"
export GDAL_CACHEMAX=20000
FILE_PATTERN="LC210_Y????_dis1km.tif"
YEAR_MIN=$(basename -a $INPUT_DIR/$FILE_PATTERN | sed -n 's/.*Y\([0-9]\{4\}\)_dis1km.tif/\1/p' | sort -n | head -1)
YEAR_MAX=$(basename -a $INPUT_DIR/$FILE_PATTERN | sed -n 's/.*Y\([0-9]\{4\}\)_dis1km.tif/\1/p' | sort -n | tail -1)

## Create scratch working dir if do not exists
[ -d "$RAM_DIR" ] || mkdir -p "$RAM_DIR"

## Stacking all yearly global raster (2000-2018)
echo "Creating .vrt stack from $YEAR_MIN to $YEAR_MAX:"
gdalbuildvrt -separate\
	     $INPUT_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	     $INPUT_DIR/$FILE_PATTERN

## Pixel-wise analysis across all years (1 = inland water present in every year)
echo "Calculating global permanent water bodies from ${YEAR_MIN} and ${YEAR_MAX}:"
pkstatprofile -f min\
	      -i $INPUT_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	      -o $RAM_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_tmp.tif

echo "Masking out globally permanent inland water bodies."
pkgetmask -i $RAM_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_tmp.tif\
	  -o $RAM_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_masked.tif\
	  -max 0 -data 1 -nodata 0\
	  -co COMPRESS=DEFLATE\
	  -co ZLEVEL=9\
	  -co BIGTIFF=YES
	  
## Upscale from 300m to 90m (WGS84) resolution using nearest neighbor (for binary mask compatibility)
echo "Upscaling mask from 300m to 90m resolution "
gdal_translate -tr 0.00083333333333 0.00083333333333\
	       -r near\
	       -ot Byte\
	       $RAM_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_masked.tif\
	       $OUTPUT_DIR/permanent_water_bodies_${YEAR_MIN}-${YEAR_MAX}_90m.tif\
	       -co COMPRESS=DEFLATE\
               -co ZLEVEL=9\
               -co BIGTIFF=YES

## Clean up all middle-files created in this job
echo "Cleaning up tmp files:"
rm -rf $RAM_DIR

echo "Script completed. Mask file available in: $OUTPUT_DIR/permanent_water_bodies_${YEAR_MIN}-${YEAR_MAX}_90m.tif "
