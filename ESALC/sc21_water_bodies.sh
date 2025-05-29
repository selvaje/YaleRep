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
SCRATCH_DIR="/vast/palmer/scratch/sbsc/sm3665/dataproces"
export GDAL_CACHEMAX=20000
YEARS_N=$(ls $INPUT_DIR/LC210_Y????.tif | wc -l)

## Get minimum and maximum year from file names
YEAR_MIN=$(ls $INPUT_DIR/LC210_Y????.tif | sed 's/.*_Y\([0-9]*\)\.tif/\1/' | sort -n | head -1)
YEAR_MAX=$(ls $INPUT_DIR/LC210_Y????.tif | sed 's/.*_Y\([0-9]*\)\.tif/\1/' | sort -n | tail -1)

## Create scratch working dir if do not exists
[ -d "OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"
[ -d "$SCRATCH_DIR" ] || mkdir -p "$SCRATCH_DIR"
[ -d "$SCRATCH_DIR/LC210_files_edited" ] || mkdir -p "$SCRATCH_DIR/LC210_files_edited"

## Copying original ESALC files into scratch, but changing nodata value from '255' to '0'
echo "Copying ESALC LC210 files:"
for file in $INPUT_DIR/LC210_Y????.tif; do
    echo "- Copying $file [set nodata=0]"
    gdal_translate -a_nodata 0\
		   $file\
		   $SCRATCH_DIR/LC210_files_edited/$(basename $file)
done

## Stacking all yearly global raster (1992-2018)
echo "Creating .vrt stack:"
gdalbuildvrt -separate\
	     $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	     $SCRATCH_DIR/LC210_files_edited/LC210_Y????.tif

## Pixel-wise sum across all years (1 = water body present for each year)
echo "Calculating global permanent water bodies between ${YEAR_MIN} and ${YEAR_MAX}:"
pkstatprofile -f sum -ot Byte\
	      -i $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_stack.vrt\
	      -o $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_sum.tif

## Generate binary mask: 1 only where sum equals number of years (i.e. always snow/ice)
echo "Generating global binary mask:"
pkgetmask -i $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_sum.tif\
	  -o $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_tmp.tif\
	  -data $YEARS_N -f 1 -t 0 -ot Byte

## Upscale from 300m to 90m (WGS84) resolution using nearest neighbor (for binary mask compatibility)
echo "Upscaling mask from 300m to 90m resolution "
gdal_translate -tr 0.000833333333 0.000833333333 -r near -ot Byte\
	       -co COMPRESS=DEFLATE -co ZLEVEL=9\
	       $SCRATCH_DIR/LC210_${YEAR_MIN}-${YEAR_MAX}_permanent_water_tmp.tif\
	       $OUTPUT_DIR/permanent_water_bodies_${YEAR_MIN}-${YEAR_MAX}_90m.tif

## Clean up all middle-files created in this job
echo "Cleaning up tmp files:"
rm -f $SCRATCH_DIR/*
rm -rf $SCRATCH_DIR/LC210_files_edited
echo "Script completed. Mask file available in: $OUTPUT_DIR/permanent_water_bodies_${YEAR_MIN}-${YEAR_MAX}_90m.tif "
