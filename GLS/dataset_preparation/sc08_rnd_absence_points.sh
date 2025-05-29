#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc08_rnd_absence_points.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc08_rnd_absence_points.sh.%A_%a.err
#SBATCH --job-name=sc08_rnd_absence_points
#SBATCH --mem=180G
#SBATCH --array=1-115

### ==================- PARAMETERS ==================
export DATASET_FOLDER="/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS"
export INPUT_GPKG="$DATASET_FOLDER/points_presence.gpkg"
export OUTPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/GLS/global_no-landslide_area"
export RANDOMPTS_DIR="$DATASET_FOLDER/absence_points"
if [ ! -d "$RANDOMPTS_DIR" ]; then
    mkdir -p $RANDOMPTS_DIR
fi

export VRT="$OUTPUT_DIR/no_landslide_area.vrt"
## points distance
export PX1KM_WGS=0.008983333333
## mask resolution
export PX90M_WGS=0.000833333333 

### ================== MODULES LOAD ==================
ulimit -c 0
source ~/bin/gdal3 &> /dev/null

### ================== EXTRACT TILE INFOS FROM VRT ==================
export TILE_MASK=$(gdalinfo $VRT | grep -o "/.*/no_landslide_area_h..v..\.tif" | sort | uniq | sed -n "${SLURM_ARRAY_TASK_ID}p")
export TILE=$(basename $TILE_MASK .tif | sed 's/no_landslide_area_//')
export N_TILES=$(gdalinfo $VRT | grep -o "/.*/no_landslide_area_h..v..\.tif" | sort | uniq | wc -l)
export TILE_JOB_NAME="sc08_randompoints_${TILE}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
scontrol update JobName=$TILE_JOB_NAME JobId=${SLURM_JOB_ID}

echo "------------- PARAMETERS ------------"
echo " "
echo "$(date +'%Y-%m-%d %H:%M:%S') - JOB: $TILE_JOB_NAME"
echo " "
echo "$(date +'%Y-%m-%d %H:%M:%S') - WORKING TILE: $TILE_MASK ($TILE / $N_TILES)"
echo " "
~/bin/echoerr "------------- PARAMETERS ------------"
~/bin/echoerr " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - JOB: $TILE_JOB_NAME"
~/bin/echoerr " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - WORKING TILE: $TILE_MASK ($TILE / $N_TILES)"
~/bin/echoerr " "

## clean files from previous run for this tile
rm -f $RANDOMPTS_DIR/random_points_${TILE}.txt
rm -f $RANDOMPTS_DIR/absence_points_${TILE}.txt

### ================== EXTRACT TILE EXTENSIONS DIRECTLY FROM THE TILE FILE ==================
## use gdalinfo to gather tile extension
## Corner coordinates extraction
export corners=$(gdalinfo $TILE_MASK | grep -E "Upper Left|Lower Left|Upper Right|Lower Right")
export W=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $2}' | sed 's/ //g')
export N=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export S=$(echo "$corners" | grep "Lower Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export E=$(echo "$corners" | grep "Upper Right" | awk -F'[(),]' '{print $2}' | sed 's/ //g')

echo "$(date +'%Y-%m-%d %H:%M:%S') - TILE CORNER: N=$N, S=$S, E=$E, W=$W"
echo " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - TILE CORNER: N=$N, S=$S, E=$E, W=$W"
~/bin/echoerr " "

## 1km reduced corner coordinates for the r.random.cells process
export Ncrop=$(echo "$N - $PX1KM_WGS" | bc | awk '{printf "%.7f", $0}')
export Scrop=$(echo "$S + $PX1KM_WGS" | bc | awk '{printf "%.7f", $0}')
export Ecrop=$(echo "$E - $PX1KM_WGS" | bc | awk '{printf "%.7f", $0}')
export Wcrop=$(echo "$W + $PX1KM_WGS" | bc | awk '{printf "%.7f", $0}')

echo "$(date +'%Y-%m-%d %H:%M:%S') - 1KM CROPPED TILE CORNER: N=$Ncrop, S=$Scrop, E=$Ecrop, W=$Wcrop"
echo " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - 1KM CROPPED TILE CORNER: N=$Ncrop, S=$Scrop, E=$Ecrop, W=$Wcrop"
~/bin/echoerr " "

### ================== COUNT VALID PIXEL FOR THIS TILE ==================
## count valid pixels for this tile using gdalinfo
export valid_pixels=$(gdalinfo -hist $TILE_MASK | grep "  0 " | awk '{print $2}')

if [[ "$valid_pixels" =~ ^[0-9]+$ ]]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS=$valid_pixels"
    echo " "
else
    ## set valid pixel count to 0 for empty tiles
    valid_pixels=0
    echo "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS=$valid_pixels [EMPTY TILE]"
    echo " "
fi

## calculate the cells ratio for 90m pix res(mask resolution), considering the 1km distance between them: ( 1000m / 90m ) ^2 in wgs84 should be 116.208400084
pixels_per_km2=$(awk -v a="$PX1KM_WGS" -v b="$PX90M_WGS" 'BEGIN {printf "%.6f", ((a*a)/(b*b))}')

echo "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS=$valid_pixels" 
echo " "
echo "$(date +'%Y-%m-%d %H:%M:%S') - PIXEL RATIO PER KM2=$pixels_per_km2"
echo " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - VALID PIXELS=$valid_pixels"
~/bin/echoerr " "
~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - PIXEL RATIO PER KM2=$pixels_per_km2"
~/bin/echoerr " "

## calculate how many cells can be generated in this tile
export max_random_cells=$(awk "BEGIN {printf \"%d\", $valid_pixels/$pixels_per_km2}")

## counts presence points 
export presence_points=$(ogrinfo -so -al $INPUT_GPKG | grep "Feature Count" | awk '{print $3}')

## calculate the max cells cap for this tile
export cap_random_cells=$(awk "BEGIN {printf \"%d\", ($presence_points/$N_TILES)*2 }")

if [ "$max_random_cells" -gt "$cap_random_cells" ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS FOR THIS TILE: $max_random_cells"
    echo " "
    ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS FOR THIS TILE: $max_random_cells"
    ~/bin/echoerr " "
    max_random_cells=$cap_random_cells
    echo "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS EXCEEDING LIMIT, CAPPED TO: $max_random_cells"
    echo " "
    echo "--------- GRASS COMPUTATION ---------"
    ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS EXCEEDING LIMIT, CAPPED TO: $max_random_cells"
    ~/bin/echoerr " "
    ~/bin/echoerr "--------- GRASS COMPUTATION ---------"
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS FOR THIS TILE: $max_random_cells"
    echo " "
    echo "--------- GRASS COMPUTATION ---------"
    ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - MAX POINTS FOR THIS TILE: $max_random_cells"
    ~/bin/echoerr " "
    ~/bin/echoerr "--------- GRASS COMPUTATION ---------"
fi


### ================== GRASS PROCESSING - RANDOM ABSENCE SAMPLING ==================

if [ "$max_random_cells" -gt 0 ]; then
    module load GRASS/8.2.0-foss-2022b
    grass -f --text --tmp-location $TILE_MASK <<EOF
## ingest tile mask
r.external input=$TILE_MASK output=mask_tile --overwrite
## set working region using the 1km cropped borders
g.region n=$Ncrop s=$Scrop e=$Ecrop w=$Wcrop
## set the mask tile as working masking
r.mask raster=mask_tile
## generate random pixels
r.random.cells output=randcells_${TILE} distance=${PX1KM_WGS} ncells=${max_random_cells} seed=42 --overwrite
## convert random pixels into vect absence points
r.to.vect input=randcells_${TILE} output=random_points_${TILE} type=point --overwrite
## export vect points as txt
v.out.ascii input=random_points_${TILE} output=$RANDOMPTS_DIR/random_points_${TILE}.txt format=point separator=space --overwrite
EOF

### ================== AWK DATA RE-FORMATTING ==================                                                                                                                              
    if [ ! -f "$RANDOMPTS_DIR/random_points_${TILE}.txt" ]; then
	echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: GRASS Computation failed."
        ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: GRASS Computation failed."
    else
##  Update output absence file with landslide data structured informations
	echo "$(date +'%Y-%m-%d %H:%M:%S') - Re-formatting output files..."
	~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - Re-formatting output files..."
	awk 'BEGIN {OFS=" "} {print NR, $1, $2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1}' "$RANDOMPTS_DIR/random_points_${TILE}.txt" > "$RANDOMPTS_DIR/absence_points_${TILE}.txt"
	if [ -f "$RANDOMPTS_DIR/absence_points_${TILE}.txt" ]; then
            NUM_ABSENCE_POINTS=$(wc -l < "$RANDOMPTS_DIR/absence_points_${TILE}.txt")
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ABSENCE POINTS GENERATED: $NUM_ABSENCE_POINTS"
            ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - ABSENCE POINTS GENERATED: $NUM_ABSENCE_POINTS"
            echo "IN: $RANDOMPTS_DIR/absence_points_${TILE}.txt"
            ~/bin/echoerr "IN: $RANDOMPTS_DIR/absence_points_${TILE}.txt"
	else
            echo "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: Re-formatting process failed."
            ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - ERROR: Re-formatting process failed."
	fi
    fi
else
    echo "$(date +'%Y-%m-%d %H:%M:%S') - Not enough valid pixels, GRASS Computation skipped."
fi

### ====================== TXT APPENDING =======================
## absence point txts appending as soon as last job ended
if [ "$SLURM_ARRAY_TASK_ID" -eq "$N_TILES" ]; then
    sleep 120
    echo "$(date +'%Y-%m-%d %H:%M:%S') - All presence points per tile processed, appending..."
    ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - All presence points per tile processed, appending..."

    ## Appending all txts
    cat $RANDOMPTS_DIR/absence_points_*.txt > $RANDOMPTS_DIR/absence_points_ALL.txt

    ## Count total rows
    TOTAL_ABSENCE=$(wc -l < $RANDOMPTS_DIR/absence_points_ALL.txt)
    echo "$(date +'%Y-%m-%d %H:%M:%S') - ABSENCE POINTS GENERATED: $TOTAL_ABSENCE"
    ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - ABSENCE POINTS GENERATED: $TOTAL_ABSENCE"

    ## Random downsampling to pair presence points
    if [ "$TOTAL_ABSENCE" -gt "$presence_points" ]; then
        shuf $RANDOMPTS_DIR/absence_points_ALL.txt | head -n $presence_points > $RANDOMPTS_DIR/absence_points.txt
	rm -f $RANDOMPTS_DIR/absence_points_*.txt
	rm -f $RANDOMPTS_DIR/absence_points_ALL.txt
	echo "$(date +'%Y-%m-%d %H:%M:%S') - Random selection $presence_points / $TOTAL_ABSENCE to pair presence points."
        ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - Random selection $presence_points / $TOTAL_ABSENCE to pair presence points."
	echo "$(date +'%Y-%m-%d %H:%M:%S') - File: $RANDOMPTS_DIR/absence_points.txt"
        ~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - File: $RANDOMPTS_DIR/absence_points.txt"
    else
        cp $RANDOMPTS_DIR/absence_points_ALL.txt $RANDOMPTS_DIR/absence_points.txt
        rm -f $RANDOMPTS_DIR/absence_points_*.txt
        rm -f $RANDOMPTS_DIR/absence_points_ALL.txt
        echo "$(date +'%Y-%m-%d %H:%M:%S') - No downsampling needed, Absence points already Non serve il downsampling, i pabsence points already <= of presences."
	~/bin/echoerr "$(date +'%Y-%m-%d %H:%M:%S') - No downsampling needed, Absence points already Non serve il downsampling, i pabsence points already <= of presences."
    fi
fi
