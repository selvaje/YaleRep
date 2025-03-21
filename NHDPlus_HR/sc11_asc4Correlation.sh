#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_asc4Correlation.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_asc4Correlation.sh.%A_%a.err
#SBATCH --job-name=sc11_asc4Correlation.sh
#SBATCH --mem=60G
#SBATCH --array=1-8

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc11_asc4Correlation.sh

###  h04v02  h06v02  h08v02  h10v02  
###  h04v04  h06v04  h08v04  h10v04  
source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export NHDP=/gpfs/loomis/project/sbsc/hydro/dataproces/NHDPlus_HR
export HydroLAKES=/gpfs/loomis/project/sbsc/hydro/dataproces/HydroLAKES
export file=$(ls $MERIT/flow_tiles/flow_{h04v02,h06v02,h08v02,h10v02,h04v04,h06v04,h08v04,h10v04}_pos.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _pos.tif )
export tile=$(echo $filename | sed 's/flow_//g')

GDAL_CACHEMAX=50000
### filtering  
#### hydrography90m flow accumulation 
pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $HydroLAKES/tif_ID/all_tif_HydroLAKES.vrt  -p '>' -msknodata 0.5 -nodata -9999999 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_$tile.tif -p '='  -msknodata 0 -nodata  -9999999  \
-m $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif -p '='  -msknodata -9999999  -nodata -9999999  \
-i $MERIT/flow_tiles/flow_${tile}_pos.tif   -o $NHDP/raster_flow_val/flow_${tile}_pos_msk.tif

gdalinfo -mm $NHDP/raster_flow_val/flow_${tile}_pos_msk.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $NHDP/raster_flow_val/flow_${tile}_pos_msk.mm

#### MERIT-HYDRO flow accumulation 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $( getCorners4Gtranslate $MERIT/flow_tiles/flow_${tile}_pos.tif ) /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/upa/all_tif.vrt /tmp/flow_${tile}_mer.tif  # mer stay for merit

pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $HydroLAKES/tif_ID/all_tif_HydroLAKES.vrt  -p '>' -msknodata 0.5 -nodata -9999999 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_$tile.tif -p '='  -msknodata 0 -nodata  -9999999  \
-m $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_$tile.tif -p '='  -msknodata -9999999  -nodata -9999999  \
-i /tmp/flow_${tile}_mer.tif   -o $NHDP/raster_flow_val/flow_${tile}_mer_msk.tif
rm -f  /tmp/flow_${tile}_mer.tif
gdalinfo -mm $NHDP/raster_flow_val/flow_${tile}_mer_msk.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $NHDP/raster_flow_val/flow_${tile}_mer_msk.mm

#### NHDPLUS_NHDFlowline  flow accumulation 

pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $HydroLAKES/tif_ID/all_tif_HydroLAKES.vrt  -p '>' -msknodata 0.5 -nodata -9999999 \
-m $MERIT/flow_tiles/flow_${tile}_pos.tif   -p '='  -msknodata -9999999  -nodata -9999999  \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_$tile.tif -p '='  -msknodata 0 -nodata  -9999999  \
-i $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}.tif  -o $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.tif

gdalinfo -mm $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.mm

# transform to ascci

gdal_translate -of AAIGrid   $NHDP/raster_flow_val/flow_${tile}_pos_msk.tif $NHDP/raster_flow_val/flow_${tile}_pos_msk.asc
rm -f $NHDP/raster_flow_val/flow_${tile}_pos_msk.prj  $NHDP/raster_flow_val/flow_${tile}_pos_msk.asc.aux.xml

gdal_translate -of AAIGrid   $NHDP/raster_flow_val/flow_${tile}_mer_msk.tif $NHDP/raster_flow_val/flow_${tile}_mer_msk.asc
rm -f $NHDP/raster_flow_val/flow_${tile}_mer_msk.prj  $NHDP/raster_flow_val/flow_${tile}_mer_msk.asc.aux.xml

gdal_translate -of AAIGrid $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.tif $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.asc
rm -f  $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.prj  $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.asc.aux.xml

#### remove all nodata and transpose in one column
awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_flow_val/flow_${tile}_pos_msk.asc   > $NHDP/raster_flow_val/flow_${tile}_pos_msk.txt
awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_flow_val/flow_${tile}_mer_msk.asc   > $NHDP/raster_flow_val/flow_${tile}_mer_msk.txt
awk '{if (NR>6) {for (col=1; col<=NF; col++) {if ($col>-0.5) printf "%s\n", $col}}}' $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.asc  > $NHDP/raster_flow_rasterize/NHDPLUS_NHDFlowline_flow_${tile}_msk.txt



