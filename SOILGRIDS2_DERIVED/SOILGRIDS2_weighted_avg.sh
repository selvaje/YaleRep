#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2
#SBATCH -t 12:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/SOILGRIDS2_weighted_avg.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/SOILGRIDS2_weighted_avg.sh.%J.err
#SBATCH --job-name=SOILGRIDS2_weighted_avg
#SBATCH --mem=32G

###===============================================
module load StdEnv
module load foss/2020b
module load GDAL/3.6.2-foss-2022b
###===============================================

BASE="/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2"
#OUT="/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2_DERIVED" #not enough space
OUT="/vast/palmer/scratch/sbsc/sm3665/dataproces/big_files" # scratch used for now

VARS=("sand" "silt" "clay")

for VAR in "${VARS[@]}"; do

    echo "Processing $VAR ..."

    VARDIR="${BASE}/${VAR}/wgs84_250m_grow"

    SUP_OUT="${OUT}/${VAR}_sup.tif"
    DEEP_OUT="${OUT}/${VAR}_deep.tif"

    # ---------- SUPERFICIAL (0–30 cm) ----------
    gdal_calc.py \
        -A "${VARDIR}/${VAR}_0-5cm.vrt" \
        -B "${VARDIR}/${VAR}_15-30cm.vrt" \
        --outfile="$SUP_OUT" \
        --calc="0.7*A + 0.3*B" \
	--type=Float32 \
	--co COMPRESS=DEFLATE \
	--co PREDICTOR=3 \
	--co ZLEVEL=9 \
	--co TILED=YES \
	--co BLOCKXSIZE=512 \
	--co BLOCKYSIZE=512 \
	--quiet \
	--NoDataValue=-9999 &

    # ---------- DEEP (30–200 cm) ----------
    gdal_calc.py \
        -A "${VARDIR}/${VAR}_30-60cm.vrt" \
        -B "${VARDIR}/${VAR}_60-100cm.vrt" \
        -C "${VARDIR}/${VAR}_100-200cm.vrt" \
        --outfile="$DEEP_OUT" \
        --calc="0.6*A + 0.3*B + 0.1*C" \
        --type=Float32 \
        --co COMPRESS=DEFLATE \
        --co PREDICTOR=3 \
        --co ZLEVEL=9 \
        --co TILED=YES \
        --co BLOCKXSIZE=512 \
        --co BLOCKYSIZE=512 \
	--quiet \
        --NoDataValue=-9999 &

    # wait until this var tifs are over
    wait

    echo "$VAR done."

done

echo "All soil rasters successfully generated."
