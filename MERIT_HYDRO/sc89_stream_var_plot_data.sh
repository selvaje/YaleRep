#!/bin/sh
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc80_stream_var_plot_data.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc80_stream_var_plot_data.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc80_stream_var_plot_data.sh.%J.out

# bash  /project/fas/sbsc/hydro/scripts/MERIT_HYDRO/sc80_stream_var_plot_data.sh

source ~/bin/gdal3
module load R/3.5.3-foss-2018a-X11-20180131

OUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/figure/data_stream_var_plot
 MHSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
 MHPR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

geostring="8.64 44.5 8.8 44.4"
gdal_translate -projwin $geostring $MHPR/elv/all_tif_dis.vrt  $MHSC/figure/data_stream_var_plot/elv.tif

###  111120 / 90 * 46.25
gdaldem  slope -co COMPRESS=DEFLATE -co ZLEVEL=9 -s 57103 $MHSC/figure/data_stream_var_plot/elv.tif $MHSC/figure/data_stream_var_plot/slope.tif

ogr2ogr -spat 8.64 44.4 8.8 44.5 -clipdst  8.64 44.4 8.8 44.5 -clipdstlayer merged -skipfailures -t_srs EPSG:4326 -s_srs EPSG:4326 $MHSC/figure/data_stream_var_plot/stream_vect.shp  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order/vect/order_vect_59.gpkg 


for var in flow_tiles dir_tiles_final20d_1p  dir_tiles_final20d_1p lbasin_tiles_final20d_1p outlet_tiles_final20d_1p ; do 

if [ $var = flow_tiles  ]               ; then varname="flow"   ; fi 
if [ $var = dir_tiles_final20d_1p  ]    ; then varname="dir"    ; fi 
if [ $var = lbasin_tiles_final20d_1p  ] ; then varname="lbasin" ; fi 
if [ $var = outlet_tiles_final20d_1p  ] ; then varname="outlet" ; fi 


gdal_translate -projwin $geostring  $MHSC/$var/${varname}_h18v04.tif $MHSC/figure/data_stream_var_plot/$varname.tif
done 

###### unique basin and stream

gdal_translate -projwin $geostring  $MHSC/CompUnit_basin_uniq_tiles20d/basin_h18v04.tif        $MHSC/figure/data_stream_var_plot/basin.tif
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_uniq_tiles20d/stream_h18v04.tif $MHSC/figure/data_stream_var_plot/stream.tif

rm $MHSC/figure/data_stream_var_plot/basin_shp.* $MHSC/figure/data_stream_var_plot/lbasin_shp.*
gdal_polygonize.py -8  $MHSC/figure/data_stream_var_plot/basin.tif $MHSC/figure/data_stream_var_plot/basin_shp.shp
gdal_polygonize.py -8  $MHSC/figure/data_stream_var_plot/lbasin.tif $MHSC/figure/data_stream_var_plot/lbasin_shp.shp

###### order 

for var in  hack  horton  shreve  strahler  topo ; do 
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_order/all_tif_${var}_dis.vrt   $MHSC/figure/data_stream_var_plot/order_${var}.tif
done 

#### distance 

for var in outlet_diff_dw_basin outlet_diff_dw_scatch outlet_dist_dw_basin outlet_dist_dw_scatch stream_diff_dw_farth stream_diff_up_farth stream_diff_up_near stream_dist_dw_farth stream_dist_proximity stream_dist_up_farth stream_dist_up_near  ; do
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_dist/all_tif_${var}_dis.vrt   $MHSC/figure/data_stream_var_plot/${var}.tif
done 


####### slope 

for var in slope_curv_max_dw_cel slope_curv_min_dw_cel slope_elv_dw_cel slope_grad_dw_cel ; do
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_slope/all_tif_${var}_dis.vrt   $MHSC/figure/data_stream_var_plot/${var}.tif
done

#######  channel 

for var in channel_curv_cel channel_dist_dw_seg channel_dist_up_cel channel_dist_up_seg channel_elv_dw_cel channel_elv_dw_seg channel_elv_up_cel channel_elv_up_seg channel_grad_dw_seg channel_grad_up_cel channel_grad_up_seg channel_ident ; do
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_channel/all_tif_${var}_dis.vrt   $MHSC/figure/data_stream_var_plot/${var}.tif
done 

##### flow indices

for var in cti spi sti ; do 
gdal_translate -projwin $geostring  $MHSC/CompUnit_stream_indices_tiles20d/all_tif_${var}_dis.vrt   $MHSC/figure/data_stream_var_plot/${var}.tif
done 
