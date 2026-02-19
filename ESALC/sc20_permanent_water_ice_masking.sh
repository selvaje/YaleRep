#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc20_permanent_water_ice_masking.sh.%j.out
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc20_permanent_water_ice_masking.sh.%j.err
#SBATCH --job-name=sc20_permanent_water_ice_masking.sh
#SBATCH --mem=64G

source ~/bin/gdal3
set -euo pipefail

echo "Job started at $(date)"
# ---------------------------------------------------------
# GDAL tuning (safe, no writing outside target dir)
# ---------------------------------------------------------
export GDAL_CACHEMAX=32000
export GDAL_NUM_THREADS=ALL_CPUS

# ---------------------------------------------------------
# INPUT (READ ONLY)
# ---------------------------------------------------------
DIR1="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC220_snowper"
DIR2="/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/LC210_waterper"
TIF1="$DIR1/permanent_cryosphere_1992-2018_90m.tif"
TIF2="$DIR2/permanent_water_bodies_1992-2018_90m.tif"
TIF1_ALIGN="$DIR1/permanent_cryosphere_1992-2018_90m_aligned.tif"
TIF2_ALIGN="$DIR2/permanent_water_bodies_1992-2018_90m_aligned.tif"
TIF1_MASKED="$DIR1/permanent_cryosphere_1992-2018_90m_masked.tif"
TIF2_MASKED="$DIR2/permanent_water_bodies_1992-2018_90m_masked.tif"

MASK_VRT="/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/msk/all_tif_dis.vrt"

echo "=============================================="
echo "Reading MERIT grid..."

read WIDTH HEIGHT <<< $(gdalinfo "$MASK_VRT" | awk '
/Size is/ {gsub(/,/,""); print $3, $4}')
echo "MERIT size: $WIDTH x $HEIGHT"

echo "=============================================="
echo "Aligning permanent cryosphere to MERIT grid..."

gdalwarp \
  "$TIF1" \
  "$TIF1_ALIGN" \
  -r near \
  -ts $WIDTH $HEIGHT \
  -t_srs EPSG:4326 \
  -dstnodata 0 \
  -co COMPRESS=LZW \
  -co BIGTIFF=YES \
  -multi \
  -wo NUM_THREADS=ALL_CPUS


[[ -f "$TIF1_ALIGN" ]] || { echo "ERROR: cryosphere alignment failed"; exit 1; }
echo "Cryosphere aligned OK"

echo "Masking cryosphere..."

gdal_calc.py \
  -A "$TIF1_ALIGN" \
  -B "$MASK_VRT" \
  --outfile="$TIF1_MASKED" \
  --calc="A*(B==1)" \
  --NoDataValue=0 \
  --type=Byte \
  --co="COMPRESS=LZW" \
  --co="BIGTIFF=YES" \
  --overwrite

[[ -f "$TIF1_MASKED" ]] || { echo "ERROR: cryosphere masking failed"; exit 1; }
echo "Cryosphere masked OK"
   
echo "=============================================="
echo "Aligning permanent water bodies to MERIT grid..."

gdalwarp \
  "$TIF2" \
  "$TIF2_ALIGN" \
  -r near \
  -ts $WIDTH $HEIGHT \
  -t_srs EPSG:4326 \
  -dstnodata 0 \
  -co COMPRESS=LZW \
  -co BIGTIFF=YES \
  -multi \
  -wo NUM_THREADS=ALL_CPUS


echo "Masking water bodies..."

gdal_calc.py \
  -A "$TIF2_ALIGN" \
  -B "$MASK_VRT" \
  --outfile="$TIF2_MASKED" \
  --calc="A*(B==1)" \
  --NoDataValue=0 \
  --type=Byte \
  --co="COMPRESS=LZW" \
  --co="BIGTIFF=YES" \
  --overwrite

[[ -f "$TIF2_MASKED" ]] || { echo "ERROR: water masking failed"; exit 1; }
echo "Water masked OK"
