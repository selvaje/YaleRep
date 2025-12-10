#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc01_mean_NDVI.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc01_mean_NDVI.sh.%J.err
#SBATCH --job-name=sc01_mean_NDVI.sh
#SBATCH --mem=10G

module load StdEnv
module load foss/2020b
module load PKTOOLS/2.6.7.6-foss-2020b

SRC="/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA-MODIS_NDVI"
OUT="/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA-MODIS_NDVI/average_global_NDVI_2000_2025_3600x1800.tif"

FILES=$(find "$SRC" -mindepth 2 -type f -name "*.tif" | sort)

if [ -z "$FILES" ]; then
    echo "No file found in $SRC"
    exit 1
fi

echo "Calculating average pf $(echo "$FILES" | wc -l) raster..."
# Calcolo media pixel per pixel                                                                                                 
pkcomposite -i $FILES -o "$OUT" -stat mean -cr nodata -co COMPRESS=LZW
echo "Output: $OUT"
