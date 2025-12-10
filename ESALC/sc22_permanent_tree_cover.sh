#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc22_permanent_tree_cover.sh.%j.out 
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc22_permanent_tree_cover.sh.%j.err
#SBATCH --job-name=sc22_permanent_tree_cover.sh 
#SBATCH --mem=64G

source ~/bin/gdal3
source ~/bin/pktools

## Set variables
ESALC_CODE="LC12" #Tree or shrub cover
INPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/${ESALC_CODE}"
OUTPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/${ESALC_CODE}_treeperm"
#SCRATCH_DIR="/vast/palmer/scratch/sbsc/sm3665/dataproces/treecover_files"
RAM_DIR="/dev/shm/dataproces"
export GDAL_CACHEMAX=20000
FILE_PATTERN="${ESALC_CODE}_Y????.tif"
YEAR_MIN=$(basename -a $INPUT_DIR/$FILE_PATTERN | sed -n 's/.*Y\([0-9]\{4\}\).tif/\1/p' | sort -n | head -1)
YEAR_MAX=$(basename -a $INPUT_DIR/$FILE_PATTERN | sed -n 's/.*Y\([0-9]\{4\}\).tif/\1/p' | sort -n | tail -1)

## Create scratch working dir if do not exists
#[ -d "$SCRATCH_DIR" ] || mkdir -p "$SCRATCH_DIR"
[ -d "$RAM_DIR" ] || mkdir -p "$RAM_DIR"

## Stacking all yearly global raster (2000-2018)
echo "Creating .vrt stack from $YEAR_MIN to $YEAR_MAX:"
gdalbuildvrt -separate\
	     $INPUT_DIR/${ESALC_CODE}_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	     $INPUT_DIR/$FILE_PATTERN

## Pixel-wise analysis across all years (1 = snow/ice absent in each year)
echo "Calculating global permanent tree and shrub cover from ${YEAR_MIN} and ${YEAR_MAX}:"
pkstatprofile -f min\
	      -i $INPUT_DIR/${ESALC_CODE}_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	      -o $RAM_DIR/${ESALC_CODE}_${YEAR_MIN}-${YEAR_MAX}_permanent_tree_tmp.tif

################À#########################################
############################PASSARE AD ESALC GFC
#########################################review this==================================
echo "Masking out globally permanent cryosphere areas."
pkgetmask -i $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_tmp.tif\
	  -o $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_masked.tif\
	  -max 0 -data 1 -nodata 0\
	  -co COMPRESS=DEFLATE\
	  -co ZLEVEL=9\
	  -co BIGTIFF=YES
#######################################################################################
	  
## Upscale from 300m to 90m (WGS84) resolution using nearest neighbor (for binary mask compatibility)
echo "Upscaling mask from 300m to 90m resolution "
gdal_translate -tr 0.00083333333333 0.00083333333333\
	       -r near\
	       -ot Byte\
	       $RAM_DIR/LC220_${YEAR_MIN}-${YEAR_MAX}_permanent_cryo_masked.tif\
	       $OUTPUT_DIR/permanent_cryosphere_${YEAR_MIN}-${YEAR_MAX}_90m.tif\
	       -co COMPRESS=DEFLATE\
               -co ZLEVEL=9\
               -co BIGTIFF=YES

## Clean up all middle-files created in this job
echo "Cleaning up tmp files:"
rm -rf $RAM_DIR

echo "Script completed. Mask file available in: $OUTPUT_DIR/permanent_cryosphere_${YEAR_MIN}-${YEAR_MAX}_90m.tif "
