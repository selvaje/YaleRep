#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_stream_lbasin_colorComposite_apply_ct.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_stream_lbasin_colorComposite_apply_ct.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc30_stream_lbasin_colorComposite_apply_ct.sh 
#SBATCH --array=1-126


####    sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc30_stream_lbasin_colorComposite_apply_ct.sh 
####    sbatch  --dependency=afterany:$(qmys | grep sc28_tiling20d_aggregate.sh  | awk '{ print $1  }' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc30_stream_lbasin_colorComposite_apply_ct.sh 


export MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm

find  /tmp/     -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# SLURM_ARRAY_TASK_ID=17

export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )

echo $ulx $uly $lrx $lry


echo lbasin stream | xargs -n 1 -P 2 bash -c $'  
VAR=$1

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9  -alpha  $MERIT/${VAR}_tiles_final20d/${VAR}_$tile.tif   $MERIT/tmp/${VAR}_hist_ct.txt   $MERIT/${VAR}_tiles_final20d_ct/${VAR}_$tile.tif 

' _ 





