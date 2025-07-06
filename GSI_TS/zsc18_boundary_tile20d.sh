#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc18_boundary_tile20d.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stdout/sc18_boundary_tile20d.sh.%A_%a.err
#SBATCH --job-name=sc18_boundary_tile20d.sh
#SBATCH --array=1-116
#SBATCH --mem=20G

####  1-116

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc18_boundary_tile20d.sh

ulimit -c 0
find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

module load GRASS/8.2.0-foss-2022b

export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export file=$(ls $SCMH/lbasin_tiles_final20d_1p/lbasin_??????.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$( basename $file | awk '{gsub("lbasin_","") ; gsub(".tif","") ; print }'   )
export GDAL_CACHEMAX=16000


grass  --text --tmp-location /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_${tile}.tif    --exec <<'EOF'
r.external -e input=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_${tile}.tif  output=flow --o --q
v.external input=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/basin_polygonize_final20d/sub_catchment_${tile}.gpkg output=sub_catchment
v.external where="prev_str01=0"  input=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d/order_vect_point_${tile}.gpkg output=header



g.list raster -p
r.info  map=SA_elevation

r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16 format=GTiff nodata=-9999  input=slope  output=/home/user/my_SE_data/exercise/grassdb/slope.tif
EOF

exit



#  calculate TCI and SPI  https://grass.osgeo.org/grass73/manuals/r.watershed.html 
# CTI  Compound topographic index   ln(a / tan(b)) map 
# SPI  Stream power index           a * tan(b) 
# STI  Stream transportation index   (0.4 + 1) * ( A  / 22.13)^0.4 *  (sin(B) / 0.0896)^1.3
echo  generate TCI   with file   $tile
# ln(α / tan(β)) where α is the cumulative upslope area draining through a point per unit contour length and tan(β) is the local slope angle.

# ulx uly lrx lry
gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 \
 -projwin  $(getCorners4Gtranslate $file | awk '{print $1 - 0.1 , $2 + 0.1 , $3 + 0.1 , $4 - 0.1  }')  $MERIT/elv/all_tif_dis.vrt  $RAM/elv_${tile}.tif

grass78  -f -text --tmp-location  -c $RAM/elv_${tile}.tif   <<EOF
r.external  input=$RAM/elv_${tile}.tif   output=elv    --overwrite 

r.slope.aspect elevation=elv   precision=FCELL slope=slope 

r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Float32  format=GTiff nodata=-9999 input=slope  output=$RAM/slope_${tile}.tif
EOF

gdalbuildvrt  -te $(getCorners4Gwarp $file )   $RAM/slope_${tile}.vrt $RAM/slope_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/slope_${tile}.vrt
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/slope_${tile}.vrt
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $RAM/slope_${tile}.vrt
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/slope_${tile}.vrt

# gdalinfo -mm $RAM/slope_${tile}.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/slope_${tile}.mm

cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_${tile}_pos.tif $RAM/flow_${tile}_pos.tif

module load miniconda/4.9.2

# conda create  gdalcalc_env 
# conda install gdal # GDAL 3.3.2, released 2021/09/01 

source /gpfs/gibbs/pi/hydro/ga254/conda_envs/gdalcalc_env/lib/python3.9/venv/scripts/common/activate

echo  generate cti $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif 
/gpfs/gibbs/pi/hydro/ga254/conda_envs/gdalcalc_env/bin/gdal_calc.py --overwrite --NoDataValue=-9999 --NoDataValue=-9999999  --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=BIGTIFF=YES  -B $RAM/slope_${tile}.vrt   -A $RAM/flow_${tile}_pos.tif \
--debug --type=Int32   --outfile=$RAM/cti_${tile}.tif    --calc="((log ( A.astype(float) / (tan(  B.astype(float) * 3.141592 / 180) + 0.01 ))) * 100000000 )"

echo  generate spi $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif 
/gpfs/gibbs/pi/hydro/ga254/conda_envs/gdalcalc_env/bin/gdal_calc.py --overwrite --NoDataValue=-9999 --NoDataValue=-9999999  --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=BIGTIFF=YES  -B $RAM/slope_${tile}.vrt   -A $RAM/flow_${tile}_pos.tif \
--debug --type=Int32   --outfile=$RAM/spi_${tile}.tif    --calc="((A.astype(float) * (tan( B.astype(float) * 3.141592 / 180) + 0.01 ) ) * 1000)"

echo  generate sti $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif
/gpfs/gibbs/pi/hydro/ga254/conda_envs/gdalcalc_env/bin/gdal_calc.py --overwrite --NoDataValue=-9999 --NoDataValue=-9999999  --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=BIGTIFF=YES  -B $RAM/slope_${tile}.vrt   -A $RAM/flow_${tile}_pos.tif \
--debug --type=Int32   --outfile=$RAM/sti_${tile}.tif    --calc="(( (0.4 + 1) *  numpy.power(( A.astype(float)  / 22.13),0.4) *  numpy.power((sin( B.astype(float) * 3.141592 / 180 ) / 0.0896),1.3) ) * 1000 )"

conda  deactivate

source ~/bin/gdal3
source ~/bin/pktools

pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/slope_${tile}.vrt  -msknodata -9999 -nodata -2147483648 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -2147483648 \
-i $RAM/cti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif

rm  $RAM/cti_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.mm

pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/slope_${tile}.vrt  -msknodata -9999 -nodata -9999 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -9999 \
-i $RAM/spi_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif

rm  $RAM/spi_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.mm

pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/slope_${tile}.vrt  -msknodata -9999 -nodata -9999 \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -9999 \
-i $RAM/sti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif

rm  $RAM/sti_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.mm

gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}_10p.tif


if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 5000
for var in spi cti sti ; do 
echo $var compute global view

rm -f $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis_10p.tif

gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}_*_10p.tif
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis.vrt     $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}_??????.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis_10p.tif
done 
fi

