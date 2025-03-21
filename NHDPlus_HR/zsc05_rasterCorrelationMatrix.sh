#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_rasterCorrelationMatrix.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_rasterCorrelationMatrix.sh.%J.err
#SBATCH --job-name=sc05_rasterCorrelationMatrix.sh
#SBATCH --mem=30G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc05_rasterCorrelationMatrix.sh

source ~/bin/pktools
source ~/bin/gdal3
source ~/bin/grass78m

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR

gdalbuildvrt -overwrite $NHDP/raster_mskstr/MERIT_90m_mskstr.vrt  $NHDP/raster_mskstr/MERIT_*_90m_mskstr.tif 
gdalbuildvrt -overwrite $NHDP/raster_mskstr/HYDRO_90m_mskstr.vrt  $NHDP/raster_mskstr/HYDRO_*_90m_mskstr.tif 
gdalbuildvrt -overwrite $NHDP/raster_mskstr/NHDP_90m_mskstr.vrt   $NHDP/raster_mskstr/NHDP_*_90m_mskstr.tif  

grass78  -f -text --tmp-location  -c $NHDP/raster_mskstr/NHDP_90m_mskstr.vrt   <<'EOF'
r.external  output=NHDP     input=$NHDP/raster_mskstr/NHDP_90m_mskstr.vrt       --overwrite
g.region zoom=NHDP
r.external  output=HYDRO    input=$NHDP/raster_mskstr/HYDRO_90m_mskstr.vrt       --overwrite
r.external  output=MERIT    input=$NHDP/raster_mskstr/MERIT_90m_mskstr.vrt       --overwrite

r.mapcalc "NHDP_a  = if ( ( float(NHDP/10000) >= 1) && (HYDRO >= 1 ) && (MERIT >=1) , float(NHDP/10000)  , null())  "
r.mapcalc "MERIT_a = if ( ( float(NHDP/10000) >= 1) && (HYDRO >= 1 ) && (MERIT >=1) , float(MERIT)       , null()) "
r.mapcalc "HYDRO_a = if ( ( float(NHDP/10000) >= 1) && (HYDRO >= 1 ) && (MERIT >=1) , float(HYDRO)       , null()) "

r.univar map=NHDP_a  percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/raster_mskstr/NHDP_90m_mskstr.stat --overwrite
r.univar map=HYDRO_a percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/raster_mskstr/HYDRO_90m_mskstr.stat --overwrite
r.univar map=MERIT_a percentile=10,20,30,40,50,60,70,80,90  -ge  output=$NHDP/raster_mskstr/MERIT_90m_mskstr.stat --overwrite

r.covar -r  map=NHDP_a,HYDRO_a,MERIT_a > $NHDP/raster_corr/correlation_matrix_atpixel.txt 

r.mapcalc " NHDP_log   = log (float(NHDP_a))  "
r.mapcalc " HYDRO_log  = log (float(HYDRO_a)) "
r.mapcalc " MERIT_log  = log (float(MERIT_a)) "

r.covar -r  map=NHDP_log,HYDRO_log,MERIT_log > $NHDP/raster_corr/correlation_matrix_log_atpixel.txt

r.regression.line  mapx=NHDP_log   mapy=HYDRO_log    output=$NHDP/raster_corr/lm_NHDPvsHYDRO_log_atpixel.txt  --overwrite
r.regression.line  mapx=NHDP_log   mapy=MERIT_log    output=$NHDP/raster_corr/lm_NHDPvsMERIT_log_atpixel.txt  --overwrite

r.regression.line  mapx=NHDP_a   mapy=HYDRO_a    output=$NHDP/raster_corr/lm_NHDPvsHYDRO_atpixel.txt  --overwrite
r.regression.line  mapx=NHDP_a   mapy=MERIT_a    output=$NHDP/raster_corr/lm_NHDPvsMERIT_atpixel.txt  --overwrite

EOF

exit 
