#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc08_rnd_absence_points.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc08_rnd_absence_points.sh.%A_%a.err
#SBATCH --job-name=sc08_rnd_absence_points
#SBATCH --mem=128G
#SBATCH --array=1-116

### ==================- PARAMETERS ==================
export DATASET_FOLDER="/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS"
export INPUT_TXT="$DATASET_FOLDER/UGLC/UGLC_presence_points.txt"
export SCRATCH="/vast/palmer/scratch/sbsc/sm3665/dataproces/big_files"
export MASK_DIR="$SCRATCH/global_absence_mask"
export RANDOMPTS_DIR="$SCRATCH/absence_points"
mkdir -p $RANDOMPTS_DIR

export VRT="$MASK_DIR/absence_mask.vrt"

## points distance (360m in WGS84 degrees)
export PXDIST_WGS=0.003333333333
## mask resolution (90m in WGS84 degrees)
export PXRES_WGS=0.000833333333 

### ================== MODULES LOAD ==================
ulimit -c 0
source ~/bin/gdal3 &> /dev/null

### ================== EXTRACT TILE INFO FROM VRT ==================
export TILE_MASK=$(gdalinfo $VRT | grep -o "/.*/absence_mask_h..v..\.tif" | sort | uniq | sed -n "${SLURM_ARRAY_TASK_ID}p")
export TILE=$(basename $TILE_MASK .tif | sed 's/absence_mask_//')
export N_TILES=$(gdalinfo $VRT | grep -o "/.*/absence_mask_h..v..\.tif" | sort | uniq | wc -l)
export TILE_JOB_NAME="sc08_absence_${TILE}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
scontrol update JobName=$TILE_JOB_NAME JobId=${SLURM_JOB_ID}

echo "=========================================="
echo "$(date +'%Y-%m-%d %H:%M:%S') - WORKING TILE: $TILE"
echo "$(date +'%Y-%m-%d %H:%M:%S') - MASK FILE: $TILE_MASK"
echo "=========================================="
~/bin/echoerr "WORKING TILE: $TILE"

## Clean files from previous run
rm -f $RANDOMPTS_DIR/random_points_${TILE}.txt
rm -f $RANDOMPTS_DIR/absence_points_${TILE}.txt

### ================== EXTRACT TILE EXTENT ==================
export corners=$(gdalinfo $TILE_MASK | grep -E "Upper Left|Lower Left|Upper Right|Lower Right")
export W=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $2}' | sed 's/ //g')
export N=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export S=$(echo "$corners" | grep "Lower Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export E=$(echo "$corners" | grep "Upper Right" | awk -F'[(),]' '{print $2}' | sed 's/ //g')

echo "$(date +'%Y-%m-%d %H:%M:%S') - TILE EXTENT: W=$W, S=$S, E=$E, N=$N"

## 360m cropped extent (to avoid edge effects in random sampling)
export Ncrop=$(echo "$N - $PXDIST_WGS" | bc | awk '{printf "%.7f", $0}')
export Scrop=$(echo "$S + $PXDIST_WGS" | bc | awk '{printf "%.7f", $0}')
export Ecrop=$(echo "$E - $PXDIST_WGS" | bc | awk '{printf "%.7f", $0}')
export Wcrop=$(echo "$W + $PXDIST_WGS" | bc | awk '{printf "%.7f", $0}')

echo "$(date +'%Y-%m-%d %H:%M:%S') - CROPPED EXTENT: W=$Wcrop, S=$Scrop, E=$Ecrop, N=$Ncrop"

### ================== COUNT VALID PIXELS ==================
## Count pixels with value=1 (valid areas for absence sampling)
export valid_pixels=$(gdalinfo -hist $TILE_MASK | grep "  0 " | awk '{print $2}')

if [[ "$valid_pixels" =~ ^[0-9]+$ ]]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS: $valid_pixels"
else
    ## set valid pixel count to 0 for empty tiles
    valid_pixels=0
    echo "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS: $valid_pixels [EMPTY TILE]"
fi

## Calculate the cells ratio for 90m pix res (mask resolution), considering the 360m distance between them: ( 360m / 90m ) ^2 in wgs84 should be: 16
pixels_per_area=$(awk -v a="$PXDIST_WGS" -v b="$PXRES_WGS" 'BEGIN {printf "%.6f", ((a*a)/(b*b))}')
echo "$(date +'%Y-%m-%d %H:%M:%S') - Pixels for 360m²: $pixels_per_area"

export max_random_cells=$(awk "BEGIN {printf \"%d\", $valid_pixels/$pixels_per_area}")

## Count total presence points in dataset
export presence_points=$(awk 'NR>1' "$INPUT_TXT" | wc -l)
echo "$(date +'%Y-%m-%d %H:%M:%S') - TOTAL PRESENCE POINTS: $presence_points"

## Cap per tile (2x to ensure enough points globally)
export cap_random_cells=$(awk "BEGIN {printf \"%d\", ($presence_points/$N_TILES)*2 }")

if [ "$max_random_cells" -gt "$cap_random_cells" ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS CAPPED: $max_random_cells → $cap_random_cells"
    max_random_cells=$cap_random_cells
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS FOR TILE: $max_random_cells"
fi

echo "--------- GRASS COMPUTATION ---------"

### ================== GRASS RANDOM SAMPLING ==================
if [ "$max_random_cells" -gt 0 ]; then
    module load GRASS/8.2.0-foss-2022b
    
    grass -f --text --tmp-location $TILE_MASK <<'EOF'
## Ingest mask raster
r.external input=$TILE_MASK output=mask_tile --overwrite

## Set cropped region (avoid edge effects)
g.region n=$Ncrop s=$Scrop e=$Ecrop w=$Wcrop

## Apply mask (only sample where value=1)
r.mask raster=mask_tile

## Generate random cells at 1km spacing
r.random.cells output=randcells_${TILE} distance=${PXDIST_WGS} ncells=${max_random_cells} seed=42 --overwrite

## Convert to vector points
r.to.vect input=randcells_${TILE} output=random_points_${TILE} type=point --overwrite

## Export as text (lon lat)
v.out.ascii input=random_points_${TILE} output=$RANDOMPTS_DIR/random_points_${TILE}.txt format=point separator=space --overwrite
EOF

    ### ================== FORMAT OUTPUT ==================
    if [ ! -f "$RANDOMPTS_DIR/random_points_${TILE}.txt" ]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: GRASS computation failed"
        ~/bin/echoerr "ERROR: GRASS failed for $TILE"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Formatting output..."
        
        ## Format: ID lon lat pa(0) + matching structure of INPUT_TXT
        ## All fields set to 0 except: pa=0 (absence), and maintain same column count
        awk 'BEGIN {OFS=" "} {print NR, $1, $2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1}' \
            "$RANDOMPTS_DIR/random_points_${TILE}.txt" > "$RANDOMPTS_DIR/absence_points_${TILE}.txt"
        
        if [ -f "$RANDOMPTS_DIR/absence_points_${TILE}.txt" ]; then
            NUM_ABSENCE=$(wc -l < "$RANDOMPTS_DIR/absence_points_${TILE}.txt")
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ABSENCE POINTS GENERATED: $NUM_ABSENCE"
            ~/bin/echoerr "SUCCESS: $NUM_ABSENCE absence points for $TILE"
        else
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: Formatting failed"
            ~/bin/echoerr "ERROR: Formatting failed for $TILE"
        fi
    fi
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Not enough valid pixels, skipping tile"
    ~/bin/echoerr "SKIPPED: $TILE (no valid pixels)"
fi

### ====================== AGGREGATE RESULTS =======================
## Last task aggregates all tiles
if [ "$SLURM_ARRAY_TASK_ID" -eq "$N_TILES" ]; then
    sleep 300  ## Wait 5m for other tasks to finish
    
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Aggregating all absence points..."
    ~/bin/echoerr "Aggregating absence points..."
    
    if ls $RANDOMPTS_DIR/absence_points_h*.txt 1> /dev/null 2>&1; then
        ## Concatenate all tile files
        cat $RANDOMPTS_DIR/absence_points_h*.txt > $RANDOMPTS_DIR/absence_points_ALL.txt
        
        TOTAL_ABSENCE=$(wc -l < $RANDOMPTS_DIR/absence_points_ALL.txt)
        echo "$(date +'%Y-%m-%d %H:%M:%S') - TOTAL ABSENCE POINTS: $TOTAL_ABSENCE"
        
        ## Downsample to match presence count if needed
        if [ "$TOTAL_ABSENCE" -gt "$presence_points" ]; then
            shuf $RANDOMPTS_DIR/absence_points_ALL.txt | head -n $presence_points > $RANDOMPTS_DIR/absence_points.txt
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Downsampled: $TOTAL_ABSENCE → $presence_points"
            ~/bin/echoerr "Downsampled to $presence_points absence points"
        else
            cp $RANDOMPTS_DIR/absence_points_ALL.txt $RANDOMPTS_DIR/absence_points.txt
            echo "$(date +'%Y-%m-%d %H:%M:%S') - No downsampling needed"
            ~/bin/echoerr "No downsampling needed"
        fi
        
        echo "$(date +'%Y-%m-%d %H:%M:%S') - FINAL FILE: $RANDOMPTS_DIR/absence_points.txt"
        ~/bin/echoerr "COMPLETE: $RANDOMPTS_DIR/absence_points.txt"
        
        ## Cleanup intermediate files
        rm -f $RANDOMPTS_DIR/absence_points_h*.txt
        rm -f $RANDOMPTS_DIR/random_points_h*.txt
        rm -f $RANDOMPTS_DIR/absence_points_ALL.txt
        
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Cleanup complete"
    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: No absence point files found"
        ~/bin/echoerr "ERROR: No absence files to aggregate"
    fi
fi

echo "=========================================="
echo "$(date +'%Y-%m-%d %H:%M:%S') - JOB COMPLETED: $TILE"
echo "=========================================="


exit
############################################################
DA IMPLòEMENATRE AL POSTO DELLA FINE CON SLEEP

### ====================== AGGREGATE RESULTS =======================

## Only last array task performs aggregation
if [ "$SLURM_ARRAY_TASK_ID" -eq "$SLURM_ARRAY_TASK_MAX" ]; then

    echo "$(date +'%Y-%m-%d %H:%M:%S') - Last array task detected"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Waiting for other tasks to finish..."

    ## Wait until all other array jobs are done
    while squeue -h -j "$SLURM_ARRAY_JOB_ID" | grep -v "${SLURM_ARRAY_TASK_ID}" > /dev/null; do
        sleep 10
    done

    echo "$(date +'%Y-%m-%d %H:%M:%S') - All tasks completed"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Aggregating all absence points..."
    ~/bin/echoerr "Aggregating absence points..."

    if ls $RANDOMPTS_DIR/absence_points_h*.txt 1> /dev/null 2>&1; then

        cat $RANDOMPTS_DIR/absence_points_h*.txt > $RANDOMPTS_DIR/absence_points_ALL.txt

        TOTAL_ABSENCE=$(wc -l < $RANDOMPTS_DIR/absence_points_ALL.txt)
        echo "$(date +'%Y-%m-%d %H:%M:%S') - TOTAL ABSENCE POINTS: $TOTAL_ABSENCE"

        ## Downsample if needed
        if [ "$TOTAL_ABSENCE" -gt "$presence_points" ]; then
            shuf $RANDOMPTS_DIR/absence_points_ALL.txt | head -n $presence_points > $RANDOMPTS_DIR/absence_points.txt
            echo "$(date +'%Y-%m-%d %H:%M:%S') - Downsampled: $TOTAL_ABSENCE → $presence_points"
            ~/bin/echoerr "Downsampled to $presence_points absence points"
        else
            cp $RANDOMPTS_DIR/absence_points_ALL.txt $RANDOMPTS_DIR/absence_points.txt
            echo "$(date +'%Y-%m-%d %H:%M:%S') - No downsampling needed"
            ~/bin/echoerr "No downsampling needed"
        fi

        echo "$(date +'%Y-%m-%d %H:%M:%S') - FINAL FILE: $RANDOMPTS_DIR/absence_points.txt"
        ~/bin/echoerr "COMPLETE: $RANDOMPTS_DIR/absence_points.txt"

        ## Cleanup
        rm -f $RANDOMPTS_DIR/absence_points_h*.txt
        rm -f $RANDOMPTS_DIR/random_points_h*.txt
        rm -f $RANDOMPTS_DIR/absence_points_ALL.txt

        echo "$(date +'%Y-%m-%d %H:%M:%S') - Cleanup complete"

    else
        echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: No absence point files found"
        ~/bin/echoerr "ERROR: No absence files to aggregate"
    fi
fi


