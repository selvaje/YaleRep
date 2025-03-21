#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc25_flowCorrelNHDP-HYDRO.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc25_flowCorrelNHDP-HYDRO.sh.%A_%a.err
#SBATCH --job-name=sc25_flowCorrelNHDP-HYDRO.sh
#SBATCH --mem=30G
#SBATCH --array=1

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc25_flowCorrelNHDP-HYDRO.sh

source ~/bin/pktools
source ~/bin/gdal3
source ~/bin/grass78m

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO
export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export RAM=/dev/shm

## cd /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_90m
## gdalbuildvrt   -overwrite NHDP_flow_90m.vrt   NHDP_flow_*_90m.tif
## gdalbuildvrt -te  $(  getCorners4Gwarp ../flow_slope/flow_tiles_intb1/flow_NA5_sp1.tif )   -overwrite NHDP_flow_90m_crop.vrt   NHDP_flow_*_90m.tif

export th_sp=$SLURM_ARRAY_TASK_ID 

# pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
# -m $NHDP/raster_90m/NHDP_flow_90m_crop.vrt   -msknodata -9999 -nodata -9999999  \
# -i $NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$th_sp.tif  -o $RAM/flow_NA5_$th_sp.tif

grass78  -f -text --tmp-location  -c  $NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$th_sp.tif     <<'EOF'
r.external  output=HYDRO     input=$NHDP/flow_slope/flow_tiles_intb1/flow_NA5_sp$th_sp.tif     --overwrite
g.region    zoom=HYDRO
r.external  output=NHDP     input=$NHDP/raster_90m/NHDP_flow_90m_crop.vrt     --overwrite

r.mapcalc "NHDP_f  = float(NHDP/10000) "
if [ $th_sp -eq  1  ] ; then  
r.univar map=NHDP_f  percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/flow_slope/flow_stat/flow_NHDP.stat   --overwrite
fi 
r.univar map=HYDRO   percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/flow_slope/flow_stat/flow_HYDRO_sp$th_sp.stat  --overwrite

r.regression.line  mapx=NHDP_f   mapy=HYDRO    output=$NHDP/flow_slope/flow_stat/flow_HYDRO_sp$th_sp.regrs      --overwrite

EOF

rm -rf $RAM/flow_NA5_$th_sp.tif 

exit 
