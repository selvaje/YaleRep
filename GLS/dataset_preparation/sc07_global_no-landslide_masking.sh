#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc07_global_no-landslide_masking.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc07_global_no-landslide_masking.sh.%A_%a.err
#SBATCH --job-name=sc07_global_no-landslide_masking.sh
#SBATCH --mem=32G
#SBATCH --array=1
#### 1-116 TOTAL GLOBAL TILES

### === SBATCH LINE ===
### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLS/dataset_preparation/sc07_global_no-landslide_masking.sh

### === VARIABLES ===
export RAM="/dev/shm"
export DATASET_FOLDER="/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS"
export INPUT_TXT="$DATASET_FOLDER/IDu_x_y_pa.txt"
export INPUT_GPKG="$DATASET_FOLDER/points_presence.gpkg"
export INPUT_SUB="$RAM/points_tile_${TILE}.gpkg"
export SLOPE="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT/geomorphometry_90m_wgs84/slope/all_slope_90M_dis.vrt"
#TEST#export ICE="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC220_snowper/permanent_cryosphere_*_90m.tif"
#TEST#export WATER="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC210_waterper/permanent_water_bodies_*_90m.tif"
export OUTPUT_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/GLS/global_no-landslide_area"
export BUFFERSIZE=900
export MH="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO"

### === RAM CLEANING ===
find /tmp/ -user $USER -mtime +2 2>/dev/null | xargs -n 1 -P 2 rm -rf
find $RAM/ -user $USER -mtime +2 2>/dev/null | xargs -n 1 -P 2 rm -rf

### === MODULES LOAD ===
ulimit -c 0
source ~/bin/gdal3  &> /dev/null

### === IDENTIFY CURRENT TILE FOR THIS JOB ===
## selects the working tile file name and extent from Hydrography90m tif files, using SLURM_ARRAY_TASK_ID as index and gdalinfo for the extraction
export file=$(ls $MH/CompUnit_stream_uniq_tiles20d/stream_h??v??.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )  
## gets the complete filename
export filename=$(basename $file .tif  )
## defines the working tile code 
export TILE=$( echo $filename | awk '{ gsub("stream_","") ; print }'   )

### === UPDATE JOB NAME  ===
## redefines the job name dinamically on working tile, to make easier debugging and enhance data backtracing
export TILE_JOB_NAME="sc07_tile_${TILE}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}"
scontrol update JobName=$TILE_JOB_NAME JobId=${SLURM_JOB_ID}

echo "WORKING TILE: $TILE"
~/bin/echoerr "WORKING TILE: $TILE"

### === EXTRACT TILE EXTENSIONS DIRECTLY FROM THE TILE FILE ===
## use gdalinfo to gather tile extension
## Corner coordinates extraction
corners=$(gdalinfo $file | grep -E "Upper Left|Lower Left|Upper Right|Lower Right")

export W=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $2}' | sed 's/ //g')
export N=$(echo "$corners" | grep "Upper Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export S=$(echo "$corners" | grep "Lower Left" | awk -F'[(),]' '{print $3}' | sed 's/ //g')
export E=$(echo "$corners" | grep "Upper Right" | awk -F'[(),]' '{print $2}' | sed 's/ //g')

echo "TILE CORNER: N=$N, S=$S, E=$E, W=$W"
~/bin/echoerr "TILE CORNER: N=$N, S=$S, E=$E, W=$W"

## 0.1 Extended corner coordinates for the buffering process
export Nplus=$(echo "$N + 0.1" | bc | awk '{printf "%.7f", $0}')
export Splus=$(echo "$S - 0.1" | bc | awk '{printf "%.7f", $0}')
export Eplus=$(echo "$E + 0.1" | bc | awk '{printf "%.7f", $0}')
export Wplus=$(echo "$W - 0.1" | bc | awk '{printf "%.7f", $0}')

echo "EXTENDED TILE CORNER: N=$Nplus, S=$Splus, E=$Eplus, W=$Wplus"
~/bin/echoerr "EXTENDED TILE CORNER: N=$Nplus, S=$Splus, E=$Eplus, W=$Wplus"

### === CREATE THE TILE EXTENSION FOR SLOPE, PERMANENT ICE COVER, PERMANENT WATER BODIES ===
export TILE_FILE="$RAM/slope_tile_${TILE}.tif"
gdal_translate -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $SLOPE $TILE_FILE

#TEST#export ICE_TILE_FILE="$RAM/ice_tile_${TILE}.tif"
#TEST#gdal_translate -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $ICE $ICE_TILE_FILE

#TEST#export WATER_TILE_FILE="$RAM/water_tile_${TILE}.tif"
#TEST#gdal_translate -projwin $W $N $E $S -co COMPRESS=DEFLATE -co ZLEVEL=9 $WATER $WATER_TILE_FILE

### === SELECT ONLY VALID PRESENCE POINTS AND SAVE THEM AS GPKG ===
## Verify and create the presence file 'points_presence.gpkg'
if [ ! -f "/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS/points_presence.gpkg" ]; then
    echo " "
    echo "points_presence.gpkg file does not exist. Data processing..."
    
    ## Data filtering
    awk 'NR>1 && $4==1 {print $2, $3}' "$INPUT_TXT" > "$DATASET_FOLDER/points_filtered.txt"
    
    ## Converts selected data as GPKG
    source ~/bin/pktools
    pkascii2ogr -f "GPKG" -a_srs EPSG:4326 -x 0 -y 1 -i "$DATASET_FOLDER/points_filtered.txt" -o "$INPUT_GPKG"
    
    ## Delete temp files
    rm -f /gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS/points_filtered.txt
    
    echo "points_presence.gpkg                 check"
    echo " "
else
    echo " "
    echo "points_presence.gpkg                 check"
    echo " "
fi

### === EXTRACT POINT SUBSAMPLE FROM THIS TILE ===
ogr2ogr -f "GPKG" $INPUT_SUB $INPUT_GPKG -spat $Wplus $Splus $Eplus $Nplus

### === GRASS GEO-PROCESSING ===
## Checks if there are any points in that tile, to avoid r.buffer error, and just use the slope thresholding as a final mask
POINT_COUNT=$(ogrinfo $INPUT_SUB -al -so 2>/dev/null | grep "Feature Count" | awk '{print $NF}')

if [ "$POINT_COUNT" -eq 0 ]; then

    ## 1 - No points in tile case
    echo "$POINT_COUNT points found in $TILE tile. Proceeding with slope-based masking only."
    module load GRASS/8.2.0-foss-2022b
    grass -f --text --tmp-location $TILE_FILE <<'EOF'
      ### INGEST SLOPE BASED ON TILE EXTENSION
      r.external input=$TILE_FILE output=slope --overwrite
      #TEST#r.external input=$ICE_TILE_FILE output=ice --overwrite
      #TEST#r.external input=$WATER_TILE_FILE output=water --overwrite
      
      ### CREATE A MASK BASED ON A SLOPE THRESHOLDING (IF <=5 = 1 ELSE =0, NODATA=0)
      r.mapcalc "no_landslide_area = if(slope <= 5, 1, 0)" --overwrite
      #TEST#r.mapcalc "no_landslide_area = if(slope <= 5 && ice == 1 && water == 1, 1, 0)" --overwrite
      
      ### EXPORT THE MASKED TILE
      r.out.gdal -f -c -m input=no_landslide_area output=$OUTPUT_DIR/no_landslide_area_${TILE}.tif format=GTiff nodata=0 createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte --overwrite

EOF

else

    ## 2 - No points in tile case
    echo "$POINT_COUNT points found in $TILE tile. Proceeding with combined buffer and slope based masking."
    module load GRASS/8.2.0-foss-2022b
    grass -f --text --tmp-location $TILE_FILE <<'EOF'
      ## INGEST SLOPE BASED ON TILE EXTENSION
      r.external input=$TILE_FILE output=slope --overwrite
      #TEST#r.external input=$ICE_TILE_FILE output=ice --overwrite
      #TEST#r.external input=$WATER_TILE_FILE output=water --overwrite

      ## INCREASE TILE EXTENSION FOR THE BUFFER MASKING
      g.region n=$Nplus s=$Splus e=$Eplus w=$Wplus

      ## INGEST POINTS SUBSAMPLE FOR THIS TILE 
      v.in.ogr input=$INPUT_SUB output=points --overwrite

      ## BUFFER MASKING ON RASTERIZED SUBSAMPLE POINTS (SET 0 IN THE BUFFER AREA, AND 1 OUTSIDE)
      v.to.rast input=points output=points_rast use=val value=1 --overwrite
      r.buffer input=points_rast output=points_buffer_rast distances=$BUFFERSIZE --overwrite

      ## SET THE TILE BACK ON THE ORIGINAL EXTENSION, REMOVING ALL BUFFER MASKING BORDER EFFECTS
      g.region n=$N s=$S e=$E w=$W

      ## CALCULATE FINAL RASTER MASK
      ## Combine slope mask (slope <= 5 = 1, slope >5 = 0) and buffer mask (outside buffer = 1, inside = 0)
      r.mapcalc "no_landslide_area = if(slope <= 5 && isnull(points_buffer_rast), 1, 0)" --overwrite
      #TEST#r.mapcalc "no_landslide_area = if(slope <= 5 && isnull(points_buffer_rast) && ice == 1 && water == 1, 1, 0)" --overwrite 
      
      ### MASKED TILE EXPORT
      r.out.gdal -f -c -m input=no_landslide_area output=$OUTPUT_DIR/no_landslide_area_${TILE}.tif format=GTiff nodata=0 createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte --overwrite

EOF

fi

if [ -f "$OUTPUT_DIR/no_landslide_area_${TILE}.tif" ]; then
    echo "Mask tile: $OUTPUT_DIR/no_landslide_area_${TILE}.tif created."
else
    echo "GRASS fail. No Mask tile created."
fi

echo " "

### === CLEAN ALL TEMP DATA ===
#TEST#rm -f $ICE_TILE_FILE $WATER_TILE_FILE
rm -f $TILE_FILE $INPUT_SUB $RAM/points_filtered_${TILE}.*

### === BUILDVRT AS SOON AS ALL 116 TILES EXISTS IN THE FOLDER

export TILE_COUNT=$(ls $OUTPUT_DIR/no_landslide_area_*.tif 2>/dev/null | wc -l)
if [ "$TILE_COUNT" -eq 116 ]; then
    echo "tile count: $TILE_COUNT / 116"
    echo "All tiles completed."
    echo "Building VRT."
    gdalbuildvrt $OUTPUT_DIR/no_landslide_area.vrt\
		 $OUTPUT_DIR/no_landslide_area_*.tif
    echo "Creating a 1km downscaled global tif for visual checking purpose."
    gdal_translate -of GTiff\
		   -co COMPRESS=DEFLATE -co ZLEVEL=9\
		   -tr 0.00833333333333 0.00833333333333\
		   -r nearest\
		   /gpfs/gibbs/pi/hydro/hydro/dataproces/GLS/global_no-landslide_area/no_landslide_area.vrt\
		   /gpfs/gibbs/pi/hydro/hydro/dataproces/GLS/global_no-landslide_area/no_landslide_area_1km.tif
else
    echo "tile count: $TILE_COUNT / 116"
fi

