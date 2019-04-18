#!/bin/bash
#SBATCH -p day
#SBATCH -J sc01_wget.sh 
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000

# sbatch /gpfs/loomis/home.grace/fas/sbsc/ga254/scripts/GDP/sc01_wget.sh 

# https://www.nature.com/articles/sdata20184.pdf

# wget https://datadryad.org/bitstream/handle/10255/dryad.154107/GDP_PPP_30arcsec_v2.nc

DIR=/project/fas/sbsc/ga254/dataproces/GDP/input
# echo 1 1990 2 2000 3 2015 | xargs -n 2 -P 3 bash -c $'  
# DIR=/project/fas/sbsc/ga254/dataproces/GDP/input
# gdal_translate -a_ullr -180 +90 180 -90 -co COMPRESS=DEFLATE -co ZLEVEL=9   -b $1 $DIR/GDP_PPP_30arcsec_v2.nc  $DIR/GDP_PPP_30arcsec_v2_$2.tif
# ' _

# gdal_translate -a_ullr -180 +90 180 -90 -a_nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -b 21 $DIR/GDP_PPP_1990_2015_5arcmin_v2.nc  $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010.tif 

# gdal_translate  -projwin  $( getCorners4Gtranslate  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp/buffer_point_tif_crop.tif ) -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010.tif $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_crop.tif  

gdalwarp -co  BIGTIFF=YES -srcnodata -9 -dstnodata -9 -r cubic  -tr 0.00027777777777777 0.00027777777777777  -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_crop.tif $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m.tif -overwrite

oft-calc $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m.tif    $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m_tmp.tif <<EOF
1
#1 90000 /
EOF

pksetmask -m $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m.tif -msknodata -9 -nodata -9 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m_tmp.tif -o $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m90000.tif 
# rm -f $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m_tmp.tif   $DIR/GDP_PPP_1990_2015_5arcmin_v2_2010_30m.tif


