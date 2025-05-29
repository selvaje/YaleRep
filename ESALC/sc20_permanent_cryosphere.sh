#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc20_permanent_cryosphere.sh.%j.out 
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc20_permanent_cryosphere.sh.%j.err
#SBATCH --job-name=sc20_permanent_cryosphere.sh 
#SBATCH --mem=64G

source ~/bin/gdal3
source ~/bin/pktools

## Set variables
INPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC220"
OUTPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC220_snowper"
#SCRATCH_DIR="/vast/palmer/scratch/sbsc/sm3665/dataproces/cryosphere_files"
RAM_DIR="/dev/shm/dataproces"
export GDAL_CACHEMAX=20000
FILE_PATTERN="LC220_Y201?.tif"
YEARS_N=$(ls $INPUT_DIR/$FILE_PATTERN | wc -l)
YEAR_MIN=2000
YEAR_MAX=2018

## Create scratch working dir if do not exists
#[ -d "$SCRATCH_DIR" ] || mkdir -p "$SCRATCH_DIR"
[ -d "$RAM_DIR" ] || mkdir -p "$RAM_DIR"

## Stacking all yearly global raster (2000-2018)
echo "Creating .vrt stack from $YEAR_MIN to $YEAR_MAX:"
gdalbuildvrt -separate\
	     $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	     $INPUT_DIR/$FILE_PATTERN

## Pixel-wise analysis across all years (1 = snow/ice absent in each year)
echo "Calculating global permanent cryosphere from ${YEAR_MIN} and ${YEAR_MAX}:"
pkstatprofile -f sum\
	      -i $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	      -o $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_tmp.tif

echo "Masking out globally permanent cryosphere areas."
pkgetmask -i $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_tmp.tif\
	  -o $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_masked.tif\
	  -min 0 -max $(($YEARS_N-1)) -data 1 -nodata 255\
	  -co COMPRESS=DEFLATE -co ZLEVEL=9
	  
## Upscale from 300m to 90m (WGS84) resolution using nearest neighbor (for binary mask compatibility)
echo "Upscaling mask from 300m to 90m resolution "
gdal_translate -tr 0.00083333333333 0.00083333333333 -r near -ot Byte\
	       -co COMPRESS=DEFLATE -co ZLEVEL=9\
	       $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_masked.tif\
	       $OUTPUT_DIR/permanent_cryosphere_${YEAR_MIN}-${YEAR_MAX}_90m.tif

## Clean up all middle-files created in this job
echo "Cleaning up tmp files:"
rm -rf $RAM_DIR

echo "Script completed. Mask file available in: $OUTPUT_DIR/permanent_cryosphere_${YEAR_MIN}-${YEAR_MAX}_90m.tif "
