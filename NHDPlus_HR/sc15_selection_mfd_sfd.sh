#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc15_selection_mfd_sfd.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc15_selection_mfd_sfd.sh.%A_%a.err
#SBATCH --job-name=sc15_selection_mfd_sfd.sh
#SBATCH --mem=40G
#SBATCH --array=1-50

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc15_selection_mfd_sfd.sh

source ~/bin/pktools
source ~/bin/gdal3
source ~/bin/grass78m

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO
export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export sp=$SLURM_ARRAY_TASK_ID
export RAM=/dev/shm

GDAL_CACHEMAX=30000
### filtering  

# cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_uniq_tiles20d/CompUnit_stream_uniq_tiles20d
# gdalbuildvrt  all_tif_stram_uniq.vrt  stream_uniq_??????.tif
# /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_rasterize 
# gdalbuildvrt  all_tif_NHDPLUS_NHDFlowline_flow.vrt NHDPLUS_NHDFlowline_flow_??????.tif

pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m /gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES/tif_ID/all_tif_HydroLAKES.vrt  -p '>' -msknodata 0.5 -nodata -9999999 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/all_tif_stram_uniq.vrt  -p '='   -msknodata 0 -nodata  -9999999  \
-m $NHDP/raster_flow_rasterize/all_tif_NHDPLUS_NHDFlowline_flow.vrt  -p '='  -msknodata -9999999  -nodata -9999999  \
-i $NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$sp.tif   -o $RAM/flow_NA5_sp${sp}_msk.tif

gdalinfo -mm $NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$sp.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' > $NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$sp.mm
gdalinfo -mm $RAM/flow_NA5_sp${sp}_msk.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print $3,$4}' >  $NHDP/flow_slope/flow_NHDP_HYDRO/flow_NA5_sp${sp}_msk.mm

cp $RAM/flow_NA5_sp${sp}_msk.tif   $NHDP/flow_slope/flow_NHDP_HYDRO/flow_NA5_sp${sp}_msk.tif

grass78  -f -text --tmp-location  -c $RAM/flow_NA5_sp${sp}_msk.tif   <<'EOF'

r.external  output=HYDRO    input=$RAM/flow_NA5_sp${sp}_msk.tif      --overwrite
r.info map=HYDRO    > $NHDP/flow_slope/flow_NHDP_HYDRO/HYDRO_sp${sp}.info
g.region zoom=HYDRO
r.external  output=NHDP     input=$NHDP/raster_flow_rasterize/all_tif_NHDPLUS_NHDFlowline_flow_msk.vrt      --overwrite
r.info map=NHDP    > $NHDP/flow_slope/flow_NHDP_HYDRO/NHDP_sp${sp}.info

r.mapcalc "NHDP_HYDRO = if (  NHDP > 1 && HYDRO > 1  , NHDP - HYDRO  , null() ) "
r.mapcalc "abs_NHDP_HYDRO = abs ( NHDP_HYDRO  )"

r.info map=NHDP_HYDRO    > $NHDP/flow_slope/flow_NHDP_HYDRO/NHDP_HYDRO_sp${sp}.info 
r.info map=abs_NHDP_HYDRO    > $NHDP/flow_slope/flow_NHDP_HYDRO/abs_NHDP_HYDRO_sp${sp}.info

r.univar map=NHDP_HYDRO      percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/flow_slope/flow_NHDP_HYDRO/flow_NHDP_HYDRO_sp${sp}.stat --overwrite
r.univar map=abs_NHDP_HYDRO  percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/flow_slope/flow_NHDP_HYDRO/flow_abs_NHDP_HYDRO_sp${sp}.stat --overwrite

r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" nodata=-9999999 type=Float32 format=GTiff input=NHDP_HYDRO output=$NHDP/flow_slope/flow_NHDP_HYDRO/flow_NHDP_HYDRO_sp${sp}.tif
r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" nodata=-9999999 type=Float32 format=GTiff input=abs_NHDP_HYDRO output=$NHDP/flow_slope/flow_NHDP_HYDRO/flow_abs_NHDP_HYDRO_sp${sp}.tif

EOF

rm -f $RAM/flow_NA5_sp${sp}_msk.tif

exit 

