#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc95_hydrography90m_foldervrt.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc95_hydrography90m_foldervrt.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc95_hydrography90m_foldervrt.sh 
ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc95_hydrography90m_foldervrt.sh 

source ~/bin/gdal3

### r.watershed

HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO 

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/outlet_tiles20d 
gdalbuildvrt -overwrite   $HYDRO/hydrography90m_v.1.0/r.watershed/outlet_tiles20d/outlet.vrt             $HYDRO/outlet_tiles_final20d_1p/outlet_??????.tif 

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d 
gdalbuildvrt -overwrite    $HYDRO/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation.vrt $HYDRO/flow_tiles/flow_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/direction_tiles20d 
gdalbuildvrt -overwrite   $HYDRO/hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction.vrt       $HYDRO/dir_tiles_final20d_1p/dir_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d 
gdalbuildvrt -overwrite   $HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d/basin.vrt               $HYDRO/lbasin_tiles_final20d_1p/lbasin_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d 
gdalbuildvrt -overwrite    $HYDRO/hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d/sub_catchment.vrt   $HYDRO/CompUnit_basin_uniq_tiles20d/basin_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/segment_tiles20d 
gdalbuildvrt -overwrite    $HYDRO/hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment.vrt            $HYDRO/CompUnit_stream_uniq_tiles20d/stream_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/depression_tiles20d 
gdalbuildvrt -overwrite   $HYDRO/hydrography90m_v.1.0/r.watershed/depression_tiles20d/depression.vrt      $HYDRO/dep_lakes_final20d_1p/dep_??????.tif   

mkdir -p $HYDRO/hydrography90m_v.1.0/r.watershed/regional_unit_tiles20d 
gdalbuildvrt -overwrite    $HYDRO/hydrography90m_v.1.0/r.watershed/regional_unit_tiles20d/regional_unit.vrt $HYDRO/lbasin_compUnit_large_enlarg/bid*_msk.tif $HYDRO/lbasin_compUnit_tiles_enlarg/bid*_msk.tif 

### r.stream.channel

for dir in channel_curv_cel_tiles20d  channel_dist_up_cel_tiles20d  channel_elv_dw_cel_tiles20d  channel_elv_up_cel_tiles20d  channel_grad_dw_seg_tiles20d  channel_grad_up_seg_tiles20d channel_dist_dw_seg_tiles20d  channel_dist_up_seg_tiles20d  channel_elv_dw_seg_tiles20d  channel_elv_up_seg_tiles20d  channel_grad_up_cel_tiles20d ; do 
mkdir -p $HYDRO/hydrography90m_v.1.0/r.stream.channel/$dir  
gdalbuildvrt -overwrite   $HYDRO/hydrography90m_v.1.0/r.stream.channel/$dir/$(basename $dir _tiles20d).vrt            $HYDRO/CompUnit_stream_channel_tiles20d/$dir/channel_*_??????.tif
done 

### r.stream.slope 

for dir in slope_curv_max_dw_cel_tiles20d  slope_grad_dw_cel_tiles20d slope_elv_dw_cel_tiles20d slope_curv_min_dw_cel_tiles20d ; do 
mkdir -p $HYDRO/hydrography90m_v.1.0/r.stream.slope/$dir  
gdalbuildvrt  -overwrite   $HYDRO/hydrography90m_v.1.0/r.stream.slope/$dir/$(basename $dir _tiles20d).vrt           $HYDRO/CompUnit_stream_slope_tiles20d/$dir/slope_*_??????.tif
done 

### r.stream.distance 

for dir in outlet_diff_dw_basin_tiles20d   outlet_dist_dw_basin_tiles20d   stream_diff_dw_near_tiles20d   stream_diff_up_near_tiles20d  stream_dist_proximity_tiles20d  stream_dist_up_near_tiles20d outlet_diff_dw_scatch_tiles20d  outlet_dist_dw_scatch_tiles20d  stream_diff_up_farth_tiles20d  stream_dist_dw_near_tiles20d  stream_dist_up_farth_tiles20d ; do 
mkdir -p $HYDRO/hydrography90m_v.1.0/r.stream.distance/$dir  
gdalbuildvrt  -overwrite   $HYDRO/hydrography90m_v.1.0/r.stream.distance/$dir/$(basename $dir _tiles20d).vrt   $HYDRO/CompUnit_stream_dist_tiles20d/$dir/*_??????.tif
done 

### flow.index

for dir in cti_tiles20d  sti_tiles20d  spi_tiles20d ; do 
mkdir -p $HYDRO/hydrography90m_v.1.0/flow.index/$dir  
gdalbuildvrt -overwrite    $HYDRO/hydrography90m_v.1.0/flow.index/$dir/$(basename $dir _tiles20d).vrt $HYDRO/CompUnit_stream_indices_tiles20d/$dir/???_??????.tif
done 

#### r.stream.order 

for dir in order_hack_tiles20d  order_horton_tiles20d  order_shreve_tiles20d  order_strahler_tiles20d  order_topo_tiles20d ; do 
mkdir -p $HYDRO/hydrography90m_v.1.0/r.stream.order/$dir  
gdalbuildvrt  -overwrite    $HYDRO/hydrography90m_v.1.0/r.stream.order/$dir/$(basename $dir _tiles20d).vrt  $HYDRO/CompUnit_stream_order_tiles20d/$dir/order_*_??????.tif
done 

mkdir -p $HYDRO/hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d
cp $HYDRO/CompUnit_stream_order/all_gpkg_vect_dis.vrt   $HYDRO/hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d/order_vect.vrt 
 


