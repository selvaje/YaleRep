#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc26_flow_streamMasking.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc26_flow_streamMasking.sh.%A_%a.err
#SBATCH --job-name=sc26_flow_streamMasking.sh
#SBATCH --mem=30G
#SBATCH --array=1-50

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc26_flow_streamMasking.sh

source ~/bin/pktools
source ~/bin/gdal3

export MERIT=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR



pksetmask  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $NHDP/flow_slope/stream_tiles_intb2/stream_EA22_sp22.tif   -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $NHDP/raster_90m/MERIT_${filename}_90m.tif -o $NHDP/raster_mskstr/MERIT_${filename}_90m_mskstr.tif

pksetmask -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_uniq_$tile.tif   -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $file                                      -o $NHDP/raster_mskstr/HYDRO_${filename}_90m_mskstr.tif

pksetmask -ot Float32  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $MERIT/CompUnit_stream_uniq_tiles20d/stream_uniq_$tile.tif   -msknodata 0 -nodata -1 -m $NHDP/raster_90m/NHDP_${filename}_90m.tif -msknodata -9999 -nodata -1 \
-i $NHDP/raster_90m/NHDP_${filename}_90m.tif  -o $NHDP/raster_mskstr/NHDP_${filename}_90m_mskstr.tif
