#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc26_reclass_lbasin_broken.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc26_reclass_lbasin_broken.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc26_reclass_lbasin_broken.sh

# sbatch  --dependency=afterok:$(qmys | grep sc25_reclass_lbasin_intb.sh    | awk '{ print $1  }' | uniq)    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc26_reclass_lbasin_broken.sh

MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm

find  /tmp/     -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

# get the last max from the intire basin tiles 

lastmaxb=$( gdalinfo -mm $(ls  -rt  $MERIT/lbasin_tiles_intb_reclass/lbasin_h*.tif | tail -1 ) | grep Comp | awk -F , '{ print int($2)   }' )

for file in $MERIT/lbasin_unit_large/lbasin_brokb*.tif ; do 
filename=$(basename  $file .tif )
pkstat -hist -i $file   | grep -v " 0" | awk -v lastmaxb=$lastmaxb '{ if ($1==0) { print $1 , 0  } else { lastmaxb=1+lastmaxb   ; print $1 , lastmaxb }   }' >  $RAM/$filename.txt   
lastmaxb=$(tail -1   $RAM/$filename.txt     | awk '{ print $2  }')
pkreclass -ot UInt32  -code  $RAM/$filename.txt      -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file -o $MERIT/lbasin_unit_large_reclass/$filename.tif
gdal_edit.py  -a_nodata 0  $MERIT/lbasin_unit_large_reclass/$filename.tif
rm  $RAM/$filename.txt    
done & # send to the back ground 

# same reclass for the stream

lastmaxs=$( gdalinfo -mm $(ls  -rt  $MERIT/stream_tiles_intb_reclass/stream_h*.tif | tail -1 ) | grep Comp | awk -F , '{ print int($2)   }' )

for file in $MERIT/stream_unit_large/stream_brokb*.tif ; do 
filename=$(basename  $file .tif )
pkstat -hist -i $file   | grep -v " 0" | awk -v lastmaxs=$lastmaxs '{ if ($1==0) { print $1 , 0  } else { lastmaxs=1+lastmaxs   ; print $1 , lastmaxs }   }' >  $RAM/$filename.txt   
lastmaxs=$(tail -1   $RAM/$filename.txt     | awk '{ print $2  }')
pkreclass -ot UInt32  -code  $RAM/$filename.txt      -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file -o $MERIT/stream_unit_large_reclass/$filename.tif
gdal_edit.py  -a_nodata 0  $MERIT/stream_unit_large_reclass/$filename.tif
rm  $RAM/$filename.txt    
done 

gdalbuildvrt  -overwrite  -te -180 -60 180 85 $MERIT/stream_unit_large_reclass/all_tif.vrt    $MERIT/stream_unit_large_reclass/*.tif
gdalbuildvrt  -overwrite  -te -180 -60 180 85 $MERIT/lbasin_unit_large_reclass/all_tif.vrt    $MERIT/lbasin_unit_large_reclass/*.tif


sbatch  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc27_tiling_merge_lbasin_intb_broken_no-oft.sh
