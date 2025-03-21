#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc98_rclone_hydrography90m.sh.%J.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc98_rclone_hydrography90m.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc98_rclone_hydrography90m.sh
ulimit -c 0


####### global file 

# for file  in  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/*/*_tiles20d/*_ovr.tif   ; do
# rclone copy $file remote:hydrography90m_v.1.0/global
# done

########### stream
rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d --include="/order_vect_segment_??????.gpkg" remote:hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d

rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d --include="/order_vect_point_??????.gpkg" remote:hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d

exit 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_uniq_tiles20d
for file in stream_??????.tif ;do
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_uniq_tiles20d/$file remote:hydrography90m_v.1.0/r.watershed/segment_tiles20d/segment_${file:7}
done

### r.watershed
# rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/outlet_tiles_final20d_1p   --include="/outlet_??????.tif" remote:hydrography90m_v.1.0/r.watershed/outlet_tiles20d
# rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/outlet_polygonize_final20d --include="/outlet_??????.gpkg" remote:hydrography90m_v.1.0/r.watershed/outlet_tiles20d

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles 
for file in flow_??????.tif ; do
rclone copyto  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/$file            remote:hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_${file:5}
done

exit 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dir_tiles_final20d_1p
for file in dir_??????.tif ; do
rclone copyto  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dir_tiles_final20d_1p/$file remote:hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction_${file:4}
done 

### basin 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_1p
for file in lbasin_??????.tif ; do 
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_1p/$file remote:hydrography90m_v.1.0/r.watershed/basin_tiles20d/${file:1}
done 

rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_polygonize_final20d --include="/basin_??????.gpkg" remote:hydrography90m_v.1.0/r.watershed/basin_tiles20d

###### sub_catchment

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_basin_uniq_tiles20d
for file in basin_??????.tif ; do
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_basin_uniq_tiles20d/$file remote:hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d/sub_catchment_${file:6}
done

rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/basin_polygonize_final20d --include="/sub_catchment_??????.gpkg" remote:hydrography90m_v.1.0/r.watershed/sub_catchment_tiles20d


#######   depression

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dep_lakes_final20d_1p
for file in dep_??????.tif  ;do
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dep_lakes_final20d_1p/$file remote:hydrography90m_v.1.0/r.watershed/depression_tiles20d/depression_${file:4}
done


####### computational region 

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_large_enlarg
for file in bid*_msk.tif; do
filename=$(basename $file _msk.tif)
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_large_enlarg/$file remote:hydrography90m_v.1.0/r.watershed/regional_unit/regional_unit_${filename:3}.tif
done

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_tiles_enlarg
for file in bid*_msk.tif; do
filename=$(basename $file _msk.tif)
rclone copyto /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_tiles_enlarg/$file remote:hydrography90m_v.1.0/r.watershed/regional_unit/regional_unit_${filename:3}.tif
done

### r.stream.channel

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_channel_tiles20d

for dir in channel_curv_cel_tiles20d     channel_dist_up_cel_tiles20d  channel_elv_dw_cel_tiles20d  channel_elv_up_cel_tiles20d  channel_grad_dw_seg_tiles20d  channel_grad_up_seg_tiles20d channel_dist_dw_seg_tiles20d  channel_dist_up_seg_tiles20d  channel_elv_dw_seg_tiles20d  channel_elv_up_seg_tiles20d  channel_grad_up_cel_tiles20d ; do 
rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_channel_tiles20d/$dir  --include="/channel_*_??????.tif" remote:hydrography90m_v.1.0/r.stream.channel/$dir
done 

### r.stream.slope 
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_slope_tiles20d
for dir in slope_curv_max_dw_cel_tiles20d         slope_grad_dw_cel_tiles20d slope_elv_dw_cel_tiles20d slope_curv_min_dw_cel_tiles20d ; do 
rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_slope_tiles20d/$dir --include="/slope_*_??????.tif"    remote:hydrography90m_v.1.0/r.stream.slope/$dir
done 
### r.stream.distance 
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_dist_tiles20d
for dir in outlet_diff_dw_basin_tiles20d   outlet_dist_dw_basin_tiles20d   stream_diff_dw_near_tiles20d   stream_diff_up_near_tiles20d  stream_dist_proximity_tiles20d  stream_dist_up_near_tiles20d outlet_diff_dw_scatch_tiles20d  outlet_dist_dw_scatch_tiles20d  stream_diff_up_farth_tiles20d  stream_dist_dw_near_tiles20d  stream_dist_up_farth_tiles20d ; do 
rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_dist_tiles20d/$dir --include="/*_??????.tif"   remote:hydrography90m_v.1.0/r.stream.distance/$dir 
done 
### flow.index

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_indices_tiles20d
for dir in cti_tiles20d    sti_tiles20d  spi_tiles20d ; do 
rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_indices_tiles20d/$dir  --include="/???_??????.tif"   remote:hydrography90m_v.1.0/flow.index/$dir
done 

#### r.stream.order 
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d 
for dir in order_hack_tiles20d  order_horton_tiles20d  order_shreve_tiles20d  order_strahler_tiles20d  order_topo_tiles20d ; do 
rclone copy  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/$dir --include="/order_*_??????.tif"  remote:hydrography90m_v.1.0/r.stream.order/$dir 
done 

rclone copy /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_vect_tiles20d --include="/order_*_??????.gpkg" remote:hydrography90m_v.1.0/r.stream.order/order_vect_tiles20d



exit 

sacct -S2021-12-22 -u ga254 -ojobid,start,end,alloccpu,cputime,state   | grep COMPLETED | grep -v "\+" | awk '{ print $5  }' | grep - > day_time.txt
sacct -S2021-12-22 -u ga254 -ojobid,start,end,alloccpu,cputime,state   | grep COMPLETED | grep -v "\+" | awk '{ print $5  }' | grep -v - > hour_time.txt

awk -F '-'  '{ sum =  $1  + sum   } END {print sum }' day_time.txt    > day_sum.txt

sed  's,-, ,g'  day_time.txt  |  sed  's,:, ,g' | awk   '{ sum_h=$2+sum_h; sum_m=$3+sum_m; sum_s=$4+sum_s} END {  print sum_h , sum_m ,  sum_s   }' > day_time_sum1.txt
sed  's,-, ,g'  hour_time.txt |  sed  's,:, ,g' | awk   '{ sum_h=$1+sum_h; sum_m=$2+sum_m; sum_s=$3+sum_s} END {  print sum_h , sum_m ,  sum_s   }' > day_time_sum2.txt

cat day_time_sum*.txt | awk   '{ sum_h=$1+sum_h; sum_m=$2+sum_m; sum_s=$3+sum_s} END {  print sum_h , sum_m ,  sum_s   }' > time_sum.txt

awk '{ print $3/3600   }'   time_sum.txt  > time_sum_sec.txt
awk '{ print $2/60   }'     time_sum.txt  > time_sum_min.txt

cat time_sum_min.txt time_sum_sec.txt <(awk '{ print $1   }'  time_sum.txt) | awk   '{ sum=$1+sum } END {  print sum / 24  }' > time_sum_day.txt

cat time_sum_day.txt day_sum.txt  | awk   '{ sum=$1+sum } END {  print sum   }' > day_total.txt 




###############################



ls  -l  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/flow_??????.tif  \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dir_tiles_final20d_1p/dir_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/outlet_tiles_final20d_1p/outlet_??????.tif  \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/outlet_polygonize_final20d/outlet_??????.gpkg   \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_tiles_final20d_1p/lbasin_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_polygonize_final20d/basin_??????.gpkg  \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_basin_uniq_tiles20d/basin_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/basin_polygonize_final20d/sub_catchment_??????.gpkg \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_uniq_tiles20d/stream_????_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_large_enlarg/bid*_msk.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/lbasin_compUnit_tiles_enlarg/bid*_msk.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_channel_tiles20d/channel_*_tiles20d/channel_*_??????.tif   \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_slope_tiles20d/slope_*_tiles20d/slope_*_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_dist_tiles20d/*_*_tiles20d/*_*_??????.tif  \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_indices_tiles20d/*_tiles20d/???_??????.tif \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_*_tiles20d/order_*_??????.gpkg  \
        /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_order_tiles20d/order_*_tiles20d/order_*_??????.tif  \
        | awk '{  sum = $5 + sum  } END{ print sum } '  
