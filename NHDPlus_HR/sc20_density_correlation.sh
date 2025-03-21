#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_density_correlation.sh.J%.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_density_correlation.sh.J%.err
#SBATCH --job-name=sc20_density_correlation.sh
#SBATCH --mem=1G

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc20_density_correlation.sh

source ~/bin/pktools
source ~/bin/gdal3
source ~/bin/grass78m 

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export RAM=/dev/shm
export NHDP=/gpfs/loomis/project/sbsc/hydro/dataproces/NHDPlus_HR

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -min 0.5 -max 9999999 -i $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity.tif -o $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1.tif

gdal_edit.py -a_nodata 0 $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1.tif

grass78  -f -text --tmp-location  -c $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1.tif  <<'EOF'
r.external input=$NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1.tif output=raster

r.mapcalc "rast4clump = if(isnull(raster), 2 , raster) "
r.clump -d input=rast4clump    output=raster_clump
g.region zoom=raster
r.out.gdal --overwrite -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16 format=GTiff nodata=9999  input=raster_clump output=$NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.tif
EOF

pkstat --hist -i $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.tif > $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.txt 

# 343 out of usa


# $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $(getCorners4Gtranslate $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.tif ) /gpfs/gibbs/pi/hydro/hydro/dataproces/FLOW1k/FLO1K_mean_averaged_1960-2015.tif $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m  $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1.tif -msknodata 0 -nodata -9999   -i $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa.tif -o $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk.tif

pkfilter -co COMPRESS=DEFLATE -co ZLEVEL=9 -dx 10 -dy 10 -d 10  -f max  -i $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk.tif -o $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk_10k.tif


gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $(getCorners4Gtranslate $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_0_1_clump.tif ) $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity.tif $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_crop.tif

gdal_translate -of XYZ  $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk_10k.tif  $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk.xyz
gdal_translate -of XYZ  $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_crop.tif $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_crop.xyz


paste -d " " $NHDP/raster_stream_rasterize/FLO1K_mean_averaged_1960-2015_usa_msk.xyz $NHDP/raster_stream_rasterize/NHDPLUS_NHDFlowline_stream10kmDensity_crop.xyz | awk '{ print $3 , $6  }' | grep -v -e " -9999" -e " 0$" > $NHDP/raster_stream_rasterize/FLO1K_NHDPLUS_NHDFlowline.txt

