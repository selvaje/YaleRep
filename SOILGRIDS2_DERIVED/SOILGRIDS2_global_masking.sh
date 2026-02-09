#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4
#SBATCH -t 12:00:00
#SBATCH -J SOILGRIDS2_global_masking
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/SOILGRIDS2_global_masking.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/SOILGRIDS2_global_masking.%J.err
#SBATCH --mem=64G
###===============================================
module load StdEnv
module load foss/2022b
module load GDAL/3.6.2
###===============================================
# -------------------------------------------------------------------
# Paths
# -------------------------------------------------------------------
#OUT="/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2_DERIVED"
INPUT="/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2"
MASK_1KM="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk/all_tif_dis.vrt"
OUT="/vast/palmer/scratch/sbsc/sm3665/dataproces/big_files" #temporary, for testing
TMP_MASK="${OUT}/tmp_msk_land_250m.tif"
TMP_VRT="${OUT}/tmp_mask_template.vrt"

# Create output directory if needed
#mkdir -p "$OUT"

# -------------------------------------------------------------------
# 1) Resample mask MERIT to SoilGrids 250m grid using gdal_translate
# -------------------------------------------------------------------
echo "=============================================="
echo "Step 1: Resampling MERIT mask to SoilGrids grid"
echo "=============================================="

REF="${INPUT}/clay/wgs84_250m_grow/clay_0-200cm.vrt"

echo "Using reference file: $REF"

# Get reference dimensions
REF_INFO=$(gdalinfo "$REF")
REF_SIZE=$(echo "$REF_INFO" | grep "Size is" | awk '{print $3, $4}' | tr -d ',')
REF_XSIZE=$(echo $REF_SIZE | cut -d' ' -f1)
REF_YSIZE=$(echo $REF_SIZE | cut -d' ' -f2)

echo "Reference dimensions: ${REF_XSIZE} x ${REF_YSIZE}"

# Extract extent from reference
EXTENT=$(echo "$REF_INFO" | grep -E "Upper Left|Lower Right" | \
         sed 's/Upper Left  //;s/Lower Right //;s/).*//;s/.*(//;s/,/ /' | \
         awk 'NR==1{xmin=$1; ymax=$2} NR==2{xmax=$1; ymin=$2} END{print xmin, ymin, xmax, ymax}')

echo "Reference extent: $EXTENT"

# Extract resolution from reference
RESOLUTION=$(echo "$REF_INFO" | grep "Pixel Size" | \
             sed 's/Pixel Size = (//' | sed 's/).*//' | \
             awk -F',' '{x=$1; y=$2; if(x<0) x=-x; if(y<0) y=-y; print x, y}')

echo "Reference resolution: $RESOLUTION"

# Method 1: Direct gdal_translate with projwin and outsize
# This is the most reliable method to match exact dimensions
echo ""
echo "Creating resampled mask using gdal_translate..."

# Extract individual extent values
XMIN=$(echo $EXTENT | cut -d' ' -f1)
YMIN=$(echo $EXTENT | cut -d' ' -f2)
XMAX=$(echo $EXTENT | cut -d' ' -f3)
YMAX=$(echo $EXTENT | cut -d' ' -f4)

gdal_translate \
  -projwin $XMIN $YMAX $XMAX $YMIN \
  -outsize $REF_XSIZE $REF_YSIZE \
  -r near \
  -a_nodata 0 \
  -co BIGTIFF=YES \
  -co COMPRESS=LZW \
  -co TILED=YES \
  -co BLOCKXSIZE=256 \
  -co BLOCKYSIZE=256 \
  "$MASK_1KM" \
  "$TMP_MASK"

if [ $? -ne 0 ]; then
    echo "ERROR: gdal_translate failed!"
    exit 1
fi

echo "Mask resampling completed successfully."
echo ""
echo "Verifying dimensions match:"
echo "Reference file:"
gdalinfo "$REF" | grep -E "Size is"
echo "Resampled mask:"
gdalinfo "$TMP_MASK" | grep -E "Size is"
echo ""

# Double-check dimensions match
MASK_SIZE=$(gdalinfo "$TMP_MASK" | grep "Size is" | awk '{print $3, $4}' | tr -d ',')

if [ "$REF_SIZE" != "$MASK_SIZE" ]; then
    echo "ERROR: Dimension mismatch!"
    echo "Reference: $REF_SIZE"
    echo "Mask: $MASK_SIZE"
    exit 1
fi

echo "✓ Dimensions verified: $REF_SIZE = $MASK_SIZE"

# -------------------------------------------------------------------
# 2) Apply mask to all SoilGrids derived rasters
# -------------------------------------------------------------------
echo ""
echo "=============================================="
echo "Step 2: Applying land mask to rasters"
echo "=============================================="

# Define input files
FILES=(
    "${INPUT}/clay/wgs84_250m_grow/clay_0-200cm.vrt"
    "${INPUT}/sand/wgs84_250m_grow/sand_0-200cm.vrt"
    "${INPUT}/silt/wgs84_250m_grow/silt_0-200cm.vrt"
)

# Process each file
for F in "${FILES[@]}"; do
    if [ ! -f "$F" ]; then
        echo "WARNING: Input file not found: $F"
        continue
    fi
    
    # Extract basename and directory structure
    BASENAME=$(basename "$F" .vrt)    
    OUTFILE="${OUT}/${BASENAME}_masked.tif"
    
    echo "  → Masking $F"
    echo "     Output: $OUTFILE"
    
    gdal_calc.py \
      -A "$F" \
      -B "$TMP_MASK" \
      --outfile="$OUTFILE" \
      --calc="A*(B==1)" \
      --type=Float32 \
      --NoDataValue=-9999 \
      --co BIGTIFF=YES \
      --co COMPRESS=DEFLATE \
      --co PREDICTOR=3 \
      --co ZLEVEL=6 \
      --co TILED=YES \
      --co BLOCKXSIZE=256 \
      --co BLOCKYSIZE=256 \
      --quiet
done

# Wait for all background processes to complete
wait

RETVAL=$?

# -------------------------------------------------------------------
# 3) Check results and cleanup
# -------------------------------------------------------------------
echo ""
echo "=============================================="
echo "Step 3: Verification and Cleanup"
echo "=============================================="

# Check if all output files were created successfully
ALL_SUCCESS=true
for F in "${FILES[@]}"; do
    BASENAME=$(basename "$F" .vrt)
    DIRNAME=$(basename $(dirname "$F"))
    PARENTDIR=$(basename $(dirname $(dirname "$F")))
    OUTFILE="${OUT}/${PARENTDIR}/${DIRNAME}/${BASENAME}_masked.tif"
    
    if [ -f "$OUTFILE" ]; then
        SIZE=$(du -h "$OUTFILE" | cut -f1)
        echo "  ✓ $OUTFILE ($SIZE)"
    else
        echo "  ✗ FAILED: $OUTFILE"
        ALL_SUCCESS=false
    fi
done

echo ""
if [ "$ALL_SUCCESS" = true ]; then
    echo "All masking operations completed successfully."
else
    echo "WARNING: Some masking operations failed!"
fi

echo ""
echo "Removing temporary files..."
rm -f "$TMP_MASK"

echo ""
echo "=============================================="
echo "Processing completed!"
echo "=============================================="
echo "Output files located in: $OUT"
