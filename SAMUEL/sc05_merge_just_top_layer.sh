#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 11 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/sc05_weightedAVE.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/output/sc05_weightedAVE.sh.%J.err
#SBATCH --job-name=sc05_weightedAVE.sh
#SBATCH --mem-per-cpu=15000M
#SBATCH --array=1-8

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc02_weightedAVE.sh

# AWCtS is eft out because it's been done
# for VAR in SLTPPT CLYPPT SNDPPT WWP TEXMHT PHIHOX ORCDRC BLDFIE CECSOL CRFVOL;do   echo $VAR >> /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/variableNames.txt; done

module purge
source ~/bin/gdal3

#export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/
export DIR=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess
export RAM=/tmp

export FOLD=$(cat $DIR/variableNames.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)
echo $FOLD


# Directories for the specific variable
VAR=$FOLD
VAR_DIR="${DIR}/${VAR}/wgs84_250m_grow"
OUT_DIR="${DIR}/${VAR}_WeAv"
mkdir -p $OUT_DIR

# Output directory for the variable
OUT_DIR="${DIR}/${VAR}_WeAv"
mkdir -p $OUT_DIR

if [[ "$VAR" == "ocs" ]]; then
  echo "Processing single-layer variable: $VAR"

  # Step 1: Build .vrt for the single layer (0-30cm)
  SINGLE_LAYER_VRT="${OUT_DIR}/${VAR}_0-30cm_merged.vrt"
  gdalbuildvrt -overwrite "$SINGLE_LAYER_VRT" ${VAR_DIR}/*_0-30cm_*.tif

  # Step 2: Directly use the single-layer `.vrt` to create the final `.tif`
  FINAL_FILE="${RAM}/${VAR}_0-30cm.tif"
  gdal_translate "$SINGLE_LAYER_VRT" "$FINAL_FILE" \
      --config GDAL_CACHEMAX 500 \
      -a_nodata -32768 
  echo "Final single-layer output created for $VAR: $FINAL_FILE"
  mv $FINAL_FILE ${OUT_DIR}
fi

echo "Processing completed for ${VAR}."
