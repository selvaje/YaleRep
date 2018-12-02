#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc28_tiling20d_aggregate.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc28_tiling20d_aggregate.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc28_tiling20d_aggregate.sh




#### sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc28_tiling20d_aggregate.sh
#### sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc28_tiling20d_aggregate.sh

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


# tiles camptacha h34v00 h34v02 
# tiles alaska    h00v00 h00v02 

# macrotiles captacha lbasin_h07v01.tif 
# macrotiles alaska   lbasin_h00v01.tif  






echo lbasin stream dir | xargs -n 1 -P 3 bash -c $'  
VAR=$1

gdal_translate -a_nodata 0 -ot UInt32  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $ulx $uly $lrx $lry  $MERIT/${VAR}_tiles_final/all_tif.vrt   $MERIT/${VAR}_tiles_final20d/${VAR}_$tile.tif 
pkstat -hist -i   $MERIT/${VAR}_tiles_final20d/${VAR}_$tile.tif   | grep -v " 0" | awk \'{ print $1  }\'  >  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}_hist.txt


pkfilter -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 -of GTiff -dx 10 -dy 10 -d 10 -f mode -i  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}.tif -o $MERIT/${VAR}_tiles_final20d_10p/${VAR}_${tile}_10p.tif
pkfilter -nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot UInt32 -of GTiff -dx 5  -dy  5 -d  5 -f mode -i  $MERIT/${VAR}_tiles_final20d/${VAR}_${tile}.tif -o $MERIT/${VAR}_tiles_final20d_5p/${VAR}_${tile}_5p.tif

' _ 

