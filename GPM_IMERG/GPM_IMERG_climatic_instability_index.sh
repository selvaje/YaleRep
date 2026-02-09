#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1
#SBATCH -t 6:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/GPM_IMERG_climatic_instability_index.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/GPM_IMERG_climatic_instability_index.sh.%J.err
#SBATCH --job-name=GPM_IMERG_climatic_instability_index
#SBATCH --mem=16G

###===============================================
module load StdEnv
module load foss/2020b
module load GDAL/3.6.2-foss-2022b
###===============================================

### The Climatic Instability Index (CII) is defined as
### CII=log(1+(σ/(μnorm​+ε)))
### where μnorm is the normalized average, ε is a regolarizzation term to avoid numerical instability and σ is standard dev.
### The CII represents the relative variability of precipitation with respect to its mean, providing a dimensionless measure of climatic instability. Higher values indicate increasingly variable and less predictable precipitation regimes, which are often associated with impulsive rainfall patterns.
### The logarithmic transformation reduces the influence of extreme values and improves numerical stability, facilitating comparisons across regions with markedly different precipitation regimes, capturing also the interaction between long-term climatic forcing and rainfall variability.

# -----------------------------
# Input / Output paths
# -----------------------------
IN_DIR="/gpfs/gibbs/pi/hydro/hydro/dataproces/GPM_IMERG"
OUT_DIR="/vast/palmer/scratch/sbsc/sm3665/dataproces/big_files"

AVG="${IN_DIR}/gpm_imerg_average_2000_2025.tif"
STD="${IN_DIR}/gpm_imerg_stdev_2000_2025.tif"

AVG_NORM="${OUT_DIR}/gpm_imerg_average_2000_2025_norm01.tif"
CII_OUT="${OUT_DIR}/gpm_imerg_climatic_instability_index_2000_2025.tif"

# -----------------------------
# Parameters
# -----------------------------
EPS=0.05   # regularization term

echo "Step 1: Normalizing mean precipitation to [0–1]"

# NOTE:
# Replace MIN_AVG and MAX_AVG with values obtained via:
# gdalinfo -mm gpm_imerg_average_2000_2025.tif
MIN_AVG=0
MAX_AVG=255

gdal_calc.py \
    -A "$AVG" \
    --outfile="$AVG_NORM" \
    --calc="clip((A - ${MIN_AVG}) / (${MAX_AVG} - ${MIN_AVG}), 0, 1)" \
    --type=Float32 \
    --NoDataValue=-9999 \
    --co COMPRESS=DEFLATE \
    --co PREDICTOR=3 \
    --co ZLEVEL=9 \
    --co TILED=YES \
    --co BLOCKXSIZE=512 \
    --co BLOCKYSIZE=512 \
    --quiet

echo "Step 2: Computing Climatic Instability Index (CII)"

gdal_calc.py \
    -A "$AVG_NORM" \
    -B "$STD" \
    --outfile="$CII_OUT" \
    --calc="log(1 + (B / (A + ${EPS})))" \
    --type=Float32 \
    --NoDataValue=-9999 \
    --co COMPRESS=DEFLATE \
    --co PREDICTOR=3 \
    --co ZLEVEL=9 \
    --co TILED=YES \
    --co BLOCKXSIZE=512 \
    --co BLOCKYSIZE=512 \
    --quiet

echo "CII successfully generated:"
echo "$CII_OUT"
