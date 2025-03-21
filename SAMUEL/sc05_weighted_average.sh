#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 11 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/%x.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/%x.%J.err
#SBATCH --job-name=weighted_avg
#SBATCH --mem-per-cpu=15000M
#SBATCH --array=1-116  # Adjust based on number of tiles

# Load necessary modules
module purge
source ~/bin/gdal3
# Load necessary modules
module purge
source ~/bin/gdal3

# Input parameters
export VAR=cec  ##$var
export DIR=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess
VAR_DIR="${DIR}/${VAR}/wgs84_250m_grow"
OUT_DIR="${DIR}/${VAR}_WeAv"
LOG_DIR="${OUT_DIR}/logs"
mkdir -p $OUT_DIR $LOG_DIR
export RAM=/tmp
export DEPTHS=("0-5cm" "5-15cm" "15-30cm" "30-60cm" "60-100cm" "100-200cm")
declare -A WEIGHTS=( 
    ["0-5cm"]=0.1
    ["5-15cm"]=0.2
    ["15-30cm"]=0.3
    ["30-60cm"]=0.2
    ["60-100cm"]=0.15
    ["100-200cm"]=0.05
)

# Directory containing stream tile files
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/
export file=$(ls $SC/stream_tiles_final20d_1p/stream_h??v??.tif | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)
export filename=$(basename $file .tif)
export tile=$(echo $filename | awk '{ gsub("stream_", ""); print }')

# Log file for this tile
TILE_LOG="${LOG_DIR}/${tile}_log.txt"
echo "Processing tile: $tile for variable: $VAR" | tee -a "$TILE_LOG"

# Ensure all depth files are present and list them explicitly
FILE_LIST="${OUT_DIR}/${VAR}_${tile}_file_list.txt"
echo "Generating file list for tile ${tile}..." | tee -a "$TILE_LOG"
> "$FILE_LIST"  # Clear the file list

for DEPTH in "${DEPTHS[@]}"; do
    INPUT_FILE="${VAR_DIR}/${VAR}_${DEPTH}_${tile}.tif"
    if [[ -f $INPUT_FILE ]]; then
        echo "$INPUT_FILE" >> "$FILE_LIST"
    else
        echo "ERROR: Missing file for depth: $DEPTH in tile: $tile" | tee -a "$TILE_LOG"
    fi
done

# Verify the file list contains all expected depths
FILE_COUNT=$(wc -l < "$FILE_LIST")
EXPECTED_COUNT=${#DEPTHS[@]}

if [[ $FILE_COUNT -ne $EXPECTED_COUNT ]]; then
    echo "ERROR: Tile ${tile} is missing some depth files. Found $FILE_COUNT, expected $EXPECTED_COUNT." | tee -a "$TILE_LOG"
    cat "$FILE_LIST" | tee -a "$TILE_LOG"  # Log the current list of found files
    exit 1
fi

# Build Multi-Band VRT
VRT_FILE="${OUT_DIR}/${VAR}_multi_band_${tile}.vrt"
echo "Building multi-band VRT for ${VAR} in tile ${tile} using file list:" | tee -a "$TILE_LOG"
cat "$FILE_LIST" | tee -a "$TILE_LOG"
gdalbuildvrt -overwrite -separate "$VRT_FILE" -input_file_list "$FILE_LIST" | tee -a "$TILE_LOG"

# Clean up file list
rm -f "$FILE_LIST"

# Calculate Weighted Average
OUTPUT_FILE="${OUT_DIR}/${VAR}_WeAv_${tile}.tif"
echo "Calculating weighted average for ${VAR}" | tee -a "$TILE_LOG"
if [[ -f "$OUTPUT_FILE" ]]; then
    echo "Output file already exists: $OUTPUT_FILE. Skipping calculation." | tee -a "$TILE_LOG"
else
    gdal_calc.py \
        -A "${VRT_FILE}" --A_band=1 \
        -B "${VRT_FILE}" --B_band=2 \
        -C "${VRT_FILE}" --C_band=3 \
        -D "${VRT_FILE}" --D_band=4 \
        -E "${VRT_FILE}" --E_band=5 \
        -F "${VRT_FILE}" --F_band=6 \
        --calc="A*0.1 + B*0.2 + C*0.3 + D*0.2 + E*0.15 + F*0.05" \
        --outfile="$OUTPUT_FILE" \
        --NoDataValue=-32768 \
        --overwrite >>"$TILE_LOG" 2>&1

    if [[ $? -ne 0 ]]; then
        echo "ERROR: Failed to calculate weighted average for tile: $tile" | tee -a "$TILE_LOG"
        exit 1
    else
        echo "Weighted average calculated: $OUTPUT_FILE" | tee -a "$TILE_LOG"
    fi
fi

# Cleanup
if [[ -f "$VRT_FILE" ]]; then
    echo "Removing intermediary VRT file for tile ${tile}." | tee -a "$TILE_LOG"
    rm -f "$VRT_FILE"
fi

echo "Finished processing tile: $tile" | tee -a "$TILE_LOG"
