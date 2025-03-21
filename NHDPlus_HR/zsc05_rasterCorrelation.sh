#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_rasterCorrelation.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_rasterCorrelation.sh.%A_%a.err
#SBATCH --job-name=sc05_rasterCorrelation.sh
#SBATCH --mem=30G
#SBATCH --array=1-8

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc05_rasterCorrelation.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  
source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export file=$(ls $MERIT/flow_tiles/flow_{h04v02,h06v02,h08v02,h10v02,h04v04,h06v04,h08v04,h10v04}_pos.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _pos.tif )
export tile=$(echo $filename | sed 's/flow_//g')



GDAL_CACHEMAX=20000
#filtering 

gdal_translate -of AAIGrid   $NHDP/raster_mskstr/MERIT_${filename}_90m_mskstr.tif $NHDP/raster_corr/MERIT_${filename}_90m_mskstr.asc
rm -f $NHDP/raster_corr/MERIT_${filename}_90m_mskstr.prj $NHDP/raster_corr/MERIT_${filename}_90m_mskstr.asc.aux.xml

gdal_translate -of AAIGrid   $NHDP/raster_mskstr/HYDRO_${filename}_90m_mskstr.tif $NHDP/raster_corr/HYDRO_${filename}_90m_mskstr.asc
rm -f $NHDP/raster_corr/HYDRO_${filename}_90m_mskstr.prj $NHDP/raster_corr/HYDRO_${filename}_90m_mskstr.asc.aux.xml

gdal_translate -of AAIGrid   $NHDP/raster_mskstr/NHDP_${filename}_90m_mskstr.tif  $NHDP/raster_corr/NHDP_${filename}_90m_mskstr.asc
rm -f $NHDP/raster_corr/NHDP_${filename}_90m_mskstr.prj $NHDP/raster_corr/NHDP_${filename}_90m_mskstr.asc.aux.xml

awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_corr/MERIT_${filename}_90m_mskstr.asc > $NHDP/raster_corr/MERIT_${filename}_90m_mskstr.txt
awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_corr/HYDRO_${filename}_90m_mskstr.asc > $NHDP/raster_corr/HYDRO_${filename}_90m_mskstr.txt
awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_corr/NHDP_${filename}_90m_mskstr.asc  > $NHDP/raster_corr/NHDP_${filename}_90m_mskstr.txt


