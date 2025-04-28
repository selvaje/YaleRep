#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc49_compUnit_stream_indeces_tile20d.sh.%A_%a.out  
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc49_compUnit_stream_indeces_tile20d.sh.%A_%a.err
#SBATCH --job-name=sc49_compUnit_stream_indeces_tile20d.sh
#SBATCH --array=1-116
#SBATCH --mem=20G

####  1-116

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc49_compUnit_stream_indeces_tile20d_fullslope.sh

ulimit -c 0

source ~/bin/gdal3

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# SLURM_ARRAY_TASK_ID=3
export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=16000
echoerr "tile $tile"
echo    "tile $tile"

# calculate TCI and SPI  https://grass.osgeo.org/grass73/manuals/r.watershed.html 
# CTI  Compound topographic index   ln(a / tan(b)) map 
# SPI  Stream power index           a * tan(b) 
# STI  Stream transportation index   (0.4 + 1) * ( A  / 22.13)^0.4 *  (sin(B) / 0.0896)^1.3
echo  generate TCI   with file   $tile
# ln(α / tan(β)) where α is the cumulative upslope area draining through a point per unit contour length and tan(β) is the local slope angle.

# ulx uly lrx lry
gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 \
 -projwin  $(getCorners4Gtranslate $file | awk '{print $1 - 0.1 , $2 + 0.1 , $3 + 0.1 , $4 - 0.1  }')  $MERIT/elv/all_tif_dis.vrt  $RAM/elv_${tile}.tif
cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_${tile}_pos.tif $RAM/flow_${tile}_pos.tif

module load GRASS/8.2.0-foss-2022b &> /dev/null

grass  -f --text --tmp-location  $RAM/elv_${tile}.tif   <<'EOF'
r.external  input=$RAM/elv_${tile}.tif         output=elv      --overwrite 
r.external  input=$RAM/flow_${tile}_pos.tif    output=flow_pos --overwrite 
r.slope.aspect -e elevation=elv   precision=FCELL slope=slope
g.region raster=flow_pos
r.mapcalc 'cti = float(log(flow_pos / (tan(slope * (3.14159265359 / 180)) + 0.00001)) * 100000000 ) '
r.mapcalc 'spi = float(flow_pos * tan((slope * (3.14159265359 / 180)) + 0.00001) * 1000 )'
r.mapcalc 'sti = float(1.4 * pow((flow_pos / 22.13), 0.4) * pow((sin(slope * (3.14159265359 / 180)) / 0.0896), 1.3))'


r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-2147483648 input=cti output=$RAM/cti_${tile}.tif
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-9999 input=spi output=$RAM/spi_${tile}.tif
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-9999 input=sti output=$RAM/sti_${tile}.tif
EOF

source ~/bin/pktools &> /dev/null

#### cti
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -2147483648 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -2147483648 \
-i $RAM/cti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif
rm  $RAM/cti_${tile}.tif

gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.mm

#### spi
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -9999 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -9999 \
-i $RAM/spi_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif

rm  $RAM/spi_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.mm
#### sti
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -9999 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -9999 \
-i $RAM/sti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif

rm  $RAM/sti_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.mm

gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti2_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi2_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti2_${tile}_10p.tif

if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 5000
for var in spi cti sti ; do 
echo $var compute global view

rm -f $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis_10p.tif

gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}2_*_10p.tif
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis.vrt     $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}2_??????.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}2_dis_10p.tif
done 
fi

