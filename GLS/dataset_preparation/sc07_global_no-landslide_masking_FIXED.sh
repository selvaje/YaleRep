#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 12:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc07_global_no-landslide_masking_FIXED.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc07_global_no-landslide_masking_FIXED.sh.%A_%a.err
#SBATCH --job-name=sc07_global_no-landslide_masking.sh
#SBATCH --mem=32G
#SBATCH --array=1-116
#### 1-116 TOTAL GLOBAL TILES

### === SBATCH LINE ===
### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLS/dataset_preparation/sc07_global_no-landslide_masking_FIXED_v2.sh

### === DESCRIPTION ===
### Creates a global mask of valid areas for absence point sampling
### Valid areas = NOT ice AND NOT water AND NOT within buffer of presence points
### Output: 1 = valid area for absence sampling, 0 = invalid area

### === VARIABLES ===
#### export RAM="/dev/shm" disabled because of RAM overload
export DATASET_FOLDER="/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS"
export INPUT_TXT="$DATASET_FOLDER/UGLC/UGLC_presence_points.txt"
export SCRATCH="/vast/palmer/scratch/sbsc/sm3665/dataproces/big_files"
export OUTPUT_DIR="$SCRATCH/global_absence_mask"
export RAM="$SCRATCH/tmp"

## Global input rasters (90m resolution)
export ICE="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC220_snowper/permanent_cryosphere_1992-2018_90m.tif"
export WATER="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC210_waterper/permanent_water_bodies_1992-2018_90m.tif"
export SLOPE="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT/geomorphometry_90m_wgs84/slope/all_slope_90M_dis.vrt"

## Buffer distance around presence points (in WGS84 degrees, ~360m)
export BUFFERSIZE=360
export BUFFER_DEG=0.003333333333

## Tile reference for grid structure
export MH="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO"

### === RAM CLEANING ===
find /tmp/ -user $USER -mtime +2 2>/dev/null | xargs -n 1 -P 2 rm -rf 2>/dev/null
find $RAM/ -user $USER -mtime +2 2>/dev/null | xargs -n 1 -P 2 rm -rf 2>/dev/null

### === MODULES LOAD ===
ulimit -c 0
source ~/bin/gdal3 &> /dev/null
source ~/bin/pktools &> /dev/null

### === IDENTIFY CURRENT TILE ===
export file=$(ls $MH/CompUnit_stream_uniq_tiles20d/stream_h??v??.tif | head -$SLURM_ARRAY_TASK_ID | tail -1)
export filename=$(basename $file .tif)
export TILE=$(echo $filename | awk '{gsub("stream_",""); print}')

### === UPDATE JOB NAME ===
export TILE_JOB_NAME="sc07_mask_${TILE}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
scontrol update JobName=$TILE_JOB_NAME JobId=${SLURM_JOB_ID}

echo "=========================================="
echo "WORKING TILE: $TILE"
echo "=========================================="
~/bin/echoerr "WORKING TILE: $TILE"

### === EXTRACT TILE EXTENT ===
corners=$(gdalinfo $file | grep -E "Upper Left|Lower Left|Upper Right|Lower Right")
export W=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $2}' | sed 's/ //g')
export N=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export S=$(echo "$corners" | grep "Lower Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export E=$(echo "$corners" | grep "Upper Right" | awk -F'[(),]' '{print $2}' | sed 's/ //g')

echo "TILE EXTENT: W=$W, S=$S, E=$E, N=$N"

## Extended extent for buffer edge effects (+0.01 degrees buffer)
export Wplus=$(echo "$W - 0.01" | bc | awk '{printf "%.7f", $0}')
export Splus=$(echo "$S - 0.01" | bc | awk '{printf "%.7f", $0}')
export Eplus=$(echo "$E + 0.01" | bc | awk '{printf "%.7f", $0}')
export Nplus=$(echo "$N + 0.01" | bc | awk '{printf "%.7f", $0}')

echo "EXTENDED EXTENT: W=$Wplus, S=$Splus, E=$Eplus, N=$Nplus"

### === EXTRACT TILE SUBSETS FROM GLOBAL RASTERS ===
export ICE_TILE="$RAM/ice_${TILE}.tif"
export WATER_TILE="$RAM/water_${TILE}.tif"
export SLOPE_TILE="$RAM/slope_${TILE}.tif"

echo "Extracting ice tile..."
gdal_translate -q -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $ICE $ICE_TILE

echo "Extracting water tile..."
gdal_translate -q -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $WATER $WATER_TILE

echo "Extracting slope tile..."
gdal_translate -q -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $SLOPE $SLOPE_TILE

### === FILTER PRESENCE POINTS FOR THIS TILE FROM TXT ===
export POINTS_TXT="$RAM/presence_${TILE}.txt"

echo "Filtering presence points for tile from TXT..."
awk -v w="$Wplus" -v s="$Splus" -v e="$Eplus" -v n="$Nplus" \
    'NR>1 && $2>=w && $2<=e && $3>=s && $3<=n {print $2, $3}' \
    "$INPUT_TXT" > "$POINTS_TXT"

POINT_COUNT=$(wc -l < "$POINTS_TXT")
echo "Found $POINT_COUNT presence points in tile"

## Convert to GPKG if there are points
if [ "$POINT_COUNT" -gt 0 ]; then
    export POINTS_GPKG="$RAM/presence_${TILE}.gpkg"
    pkascii2ogr -f "GPKG" -a_srs EPSG:4326 -x 0 -y 1 \
                -i "$POINTS_TXT" -o "$POINTS_GPKG"
fi

### === GRASS PROCESSING ===
module load GRASS/8.2.0-foss-2022b

if [ "$POINT_COUNT" -eq 0 ]; then
    echo "No presence points - creating mask from ice/water only"
    
    grass -f --text --tmp-location $SLOPE_TILE <<EOF
        ## Ingest rasters
        r.external input=$ICE_TILE output=ice --overwrite
        r.external input=$WATER_TILE output=water --overwrite
	r.external input=$SLOPE_TILE output=slope --overwrite
        
        ## Set region to original tile extent (not extended)
        g.region n=$N s=$S e=$E w=$W
        
        ### CREATE A MASK BASED WITHOUT PRESENCE POINT EXCLUDING BUFFERS
        ## Combine:
        ## slope mask (slope >0 = 1, slope <=0  = 0);
        ## permanent cryosphere presence (=0 presence, =1 absence);
        ## permanent hydrosphere presence (=0 presence, =1 absence):
        r.mapcalc "no_landslide_area = if(slope > 0 && ice == 1 && water == 1, 1, 0)" --overwrite
 
        ## Export
        r.out.gdal -f -c -m input=no_landslide_area \
                   output=$OUTPUT_DIR/absence_mask_${TILE}.tif \
                   format=GTiff nodata=0 \
                   createopt="COMPRESS=DEFLATE,ZLEVEL=9" \
                   type=Byte --overwrite
EOF

else
    echo "Processing with $POINT_COUNT presence points and buffers"
    
    grass -f --text --tmp-location $SLOPE_TILE <<EOF
        ## Ingest rasters
        r.external input=$ICE_TILE output=ice --overwrite
        r.external input=$WATER_TILE output=water --overwrite
        r.external input=$SLOPE_TILE output=slope --overwrite                                                                                                     

        ## Set extended region for buffer processing
        g.region n=$Nplus s=$Splus e=$Eplus w=$Wplus
        
        ## Import presence points
        v.in.ogr input=$POINTS_GPKG output=presence --overwrite
        
        ## Create buffer around presence points
        v.to.rast input=presence output=presence_rast use=val value=1 --overwrite
        r.buffer input=presence_rast output=buffer_rast distances=$BUFFER_DEG --overwrite
        
        ## Reset to original tile extent
        g.region n=$N s=$S e=$E w=$W

        ## Create buffer mask: 1=outside buffer (valid), 0=inside buffer (invalid)
        r.mapcalc "buffer_inv = if(isnull(buffer_rast), 1, 0)" --overwrite
        
        ## CALCULATE FINAL RASTER MASK
        ## Combine:
        ## slope mask (slope >0 = 1, slope <=0 = 0);
        ## buffer mask (outside buffer = 1, inside = 0);
        ## permanent cryosphere presence (=0 presence, =1 absence);
        ## permanent hydrosphere presence (=0 presence, =1 absence):
        r.mapcalc "no_landslide_area = if(slope > 0 && ice == 1 && water == 1 && buffer_inv == 1, 1, 0)" --overwrite 
        
        ## Export
        r.out.gdal -f -c -m input=no_landslide_area \
                   output=$OUTPUT_DIR/absence_mask_${TILE}.tif \
                   format=GTiff nodata=0 \
                   createopt="COMPRESS=DEFLATE,ZLEVEL=9" \
                   type=Byte --overwrite
EOF
    
fi

## Cleanup
rm -f $ICE_TILE $WATER_TILE $SLOPE_TILE $POINTS_GPKG $POINTS_TXT

if [ -f "$OUTPUT_DIR/absence_mask_${TILE}.tif" ]; then
    echo "SUCCESS: Created $OUTPUT_DIR/absence_mask_${TILE}.tif"
    ~/bin/echoerr "SUCCESS: absence_mask_${TILE}.tif"
else
    echo "ERROR: Failed to create mask tile"
    ~/bin/echoerr "ERROR: Failed to create absence_mask_${TILE}.tif"
    exit 1
fi

### === CREATE VRT AND PREVIEW (only last job) ===
TILE_COUNT=$(ls $OUTPUT_DIR/absence_mask_*.tif 2>/dev/null | wc -l)
echo "Tiles completed: $TILE_COUNT / 116"

if [ "$TILE_COUNT" -eq 116 ]; then
    echo "All tiles complete! Creating VRT and 1km preview..."
    
    gdalbuildvrt $OUTPUT_DIR/absence_mask.vrt \
                 $OUTPUT_DIR/absence_mask_*.tif
    
    echo "Creating 1km downsampled preview..."
    gdal_translate -of GTiff \
                   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
                   -tr 0.00833333333333 0.00833333333333 \
                   -r average \
                   $OUTPUT_DIR/absence_mask.vrt \
                   $OUTPUT_DIR/absence_mask_1km.tif
    
    echo "DONE! VRT and preview created."
    ~/bin/echoerr "COMPLETE: VRT and 1km preview created"
fi

echo "=========================================="
echo "JOB COMPLETED: $TILE"
echo "=========================================="
