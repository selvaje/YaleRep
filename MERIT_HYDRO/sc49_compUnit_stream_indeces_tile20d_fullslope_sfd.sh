#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc49_compUnit_stream_indeces_tile20d.sh.%A_%a.out  
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc49_compUnit_stream_indeces_tile20d.sh.%A_%a.err
#SBATCH --job-name=sc49_compUnit_stream_indeces_tile20d.sh
#SBATCH --array=1-116
#SBATCH --mem=20G

####  1-116

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc49_compUnit_stream_indeces_tile20d_fullslope_sfd.sh

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

gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 \
 -projwin  $(getCorners4Gtranslate $file ) $SCMH/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd.tif $RAM/flow_${tile}_pos.tif 

module load GRASS/8.2.0-foss-2022b &> /dev/null

grass  -f --text --tmp-location  $RAM/elv_${tile}.tif   <<'EOF'
r.external  input=$RAM/elv_${tile}.tif         output=elv      --overwrite 
r.external  input=$RAM/flow_${tile}_pos.tif    output=flow_pos --overwrite 
r.slope.aspect -e elevation=elv   precision=FCELL slope=slope
g.region raster=flow_pos
r.mapcalc 'cti = float(log(flow_pos / (tan(slope * (3.14159265359 / 180)) + 0.00001)) * 100000000 ) '
r.mapcalc 'spi = float(flow_pos * tan((slope * (3.14159265359 / 180)) + 0.00001) * 100000 )'
r.mapcalc 'sti = float(1.4 * pow((flow_pos / 22.13), 0.4) * pow((sin(slope * (3.14159265359 / 180)) / 0.0896), 1.3) * 200000000)'

# Int32   -2,147,483,648 2,147,483,647
# UInt32               0 4,294,967,295   
# pksetmask accept as no data 2,147,483,647 or -2,147,483,648 so keep all Int32 

r.info map=cti | grep Range | awk '{printf "%.2f %.2f\n",$7,$10}' > $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.mm 
#  -312 424 600 ;  2 709 549 000  ; -312 424 640   2 147 483 520 from gdal 
r.info map=spi | grep Range | awk '{printf "%.2f %.2f\n",$7,$10}' > $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.mm 
# 0  1 306 402 000  ; 0  1 306 401 536 from gdal 
r.info map=sti | grep Range | awk '{printf "%.2f %.2f\n",$7,$10}' > $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.mm 
# 0  991 724 000   ; 0   991 723 968 from gdal 

r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-2147483648 input=cti output=$RAM/cti_${tile}.tif
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-2147483648  input=spi output=$RAM/spi_${tile}.tif
r.out.gdal -f --o -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32 format=GTiff nodata=-2147483648  input=sti output=$RAM/sti_${tile}.tif
EOF

source ~/bin/pktools &> /dev/null

echo cti ; echoerr cti
cp $RAM/cti_${tile}.tif $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_${tile}_tmp.tif
pksetmask -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -2147483648 \
-m $RAM/flow_${tile}_pos.tif  -msknodata  -9999999  -nodata  -2147483648 \
-i $RAM/cti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif
rm  $RAM/cti_${tile}.tif

gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.mmg

echo  spi
echoerr  spi

pksetmask -ot Int32  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -2147483648  \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -2147483648  \
-i $RAM/spi_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif

rm  $RAM/spi_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.mmg

echo  sti  ; echoerr  sti
cp $RAM/sti_${tile}.tif $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_${tile}_tmp.tif
pksetmask -ot Int32 -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/elv_${tile}.tif  -msknodata -9999 -nodata -2147483648  \
-m $RAM/flow_${tile}_pos.tif  -msknodata -9999999 -nodata -2147483648  \
-i $RAM/sti_${tile}.tif   -o $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif

rm  $RAM/sti_${tile}.tif
gdalinfo -mm $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }' > $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.mmg

gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/cti_tiles20d/cti_sfd_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/spi_tiles20d/spi_sfd_${tile}_10p.tif
gdal_translate -tr 0.00833333333333333333333333333333333 0.00833333333333333333333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}.tif  $SCMH/CompUnit_stream_indices_tiles20d/sti_tiles20d/sti_sfd_${tile}_10p.tif

if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 5000
for var in spi cti sti ; do 
echo $var compute global view

rm -f $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis_10p.tif

gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}_sfd*_10p.tif
gdalbuildvrt -overwrite $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis.vrt     $SCMH/CompUnit_stream_indices_tiles20d/${var}_tiles20d/${var}_sfd_??????.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis_10p.vrt $SCMH/CompUnit_stream_indices_tiles20d/all_tif_${var}_sfd_dis_10p.tif
done 
fi

