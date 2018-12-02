#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc25_reclass_lbasin_intb.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc25_reclass_lbasin_intb.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc25_reclass_lbasin_intb.sh

# sbatch  -d afterany:$(qmys | grep sc23_build_dem_location_broken_basin.sh | awk '{ print $1  }' | uniq)    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc25_reclass_lbasin_intb.sh

MERIT=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm

find  /tmp/     -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

lastmaxb=0
for file in $MERIT/lbasin_tiles_intb/lbasin_h??v??.tif ; do 
filename=$(basename  $file .tif )
pkstat -hist -i $file   | grep -v " 0" | awk -v lastmaxb=$lastmaxb '{ if ($1==0) { print $1 , 0  } else { lastmaxb=1+lastmaxb   ; print $1 , lastmaxb }   }' >  $RAM/$filename.txt   
lastmaxb=$(tail -1   $RAM/$filename.txt     | awk '{ print $2  }')
pkreclass -ot UInt32  -code  $RAM/$filename.txt      -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file -o $MERIT/lbasin_tiles_intb_reclass/$filename.tif 
gdal_edit.py  -a_nodata 0   $MERIT/lbasin_tiles_intb_reclass/$filename.tif 
rm  $RAM/$filename.txt    
done &   # to send to the back ground and start the other loop 

lastmaxs=0
for file in $MERIT/stream_tiles_intb/stream_h??v??.tif ; do 
filename=$(basename  $file .tif )
pkstat -hist -i $file   | grep -v " 0" | awk -v lastmaxs=$lastmaxs '{ if ($1==0) { print $1 , 0  } else { lastmaxs=1+lastmaxs   ; print $1 , lastmaxs }   }' >  $RAM/$filename.txt   
lastmaxs=$(tail -1   $RAM/$filename.txt     | awk '{ print $2  }')
pkreclass -ot UInt32  -code  $RAM/$filename.txt      -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file -o $MERIT/stream_tiles_intb_reclass/$filename.tif 
gdal_edit.py  -a_nodata 0   $MERIT/stream_tiles_intb_reclass/$filename.tif 
rm  $RAM/$filename.txt    
done 

# run in automatic the othe reclass script for the broken basin
sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc26_reclass_lbasin_broken.sh

