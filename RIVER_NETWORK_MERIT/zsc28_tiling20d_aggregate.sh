#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc28_tiling20d_aggregate.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc28_tiling20d_aggregate.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc28_tiling20d_aggregate.sh
#SBATCH --array=1-126


# 1-126
#### sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc28_tiling20d_aggregate.sh
#### sbatch  --dependency=afterany:$(qmys | grep sc27_tiling_merge_lbasin_intb_broken_no-oft.sh | awk '{ print $1  }' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc28_tiling20d_aggregate.sh

# to run before the computation 
# gdalbuildvrt   -overwrite  -te -180 -60 180 85 /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final/all_tif.vrt  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_final/lbasin_h??v??.tif
# gdalbuildvrt   -overwrite  -te -180 -60 180 85 /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final/all_tif.vrt  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_tiles_final/stream_h??v??.tif
# gdalbuildvrt   -overwrite  -te -180 -60 180 85 /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dir_tiles_final/all_tif.vrt     /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dir_tiles_final/dir_h??v??.tif

export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm


find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# SLURM_ARRAY_TASK_ID=17

export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )

echo $ulx $uly $lrx $lry


echo $ulx $uly $lrx $lry   


echo lbasin stream dir | xargs -n 1 -P 3 bash -c $'  
VAR=$1

gdal_translate -a_nodata 0 -ot UInt32  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $ulx $uly $lrx $lry  $MERIT/${VAR}_tiles_final/all_tif.vrt   $MERIT/${VAR}_tiles_final20d/${VAR}_$tile.tif 
pkstat -hist -i   $MERIT/${VAR}_tiles_final20d/${VAR}_$tile.tif   | grep -v " 0" | awk \'{ print $1  }\'  >  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}_hist.txt


pkfilter -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 -of GTiff -dx 10 -dy 10 -d 10 -f mode -i  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}.tif -o $MERIT/${VAR}_tiles_final20d_10p/${VAR}_${tile}_10p.tif
pkfilter -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 -of GTiff -dx 5  -dy  5 -d  5 -f mode -i  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}.tif -o $MERIT/${VAR}_tiles_final20d_5p/${VAR}_${tile}_5p.tif

' _ 

