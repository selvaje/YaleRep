#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH --array=1-1150
#SBATCH -t 0:10:00
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_layers_preparation.sh%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_layers_preparation.sh%A_%a.out
#SBATCH --job-name=sc02_layers_preparation.sh

# sbatch  --dependency=afterok:$(qmys | grep sc01_wget_merit_river.sh  | awk '{  print $1 }'  | uniq )    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc02_layers_preparation.sh

# 1150 files 
file=$(ls  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dir/*_dir.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )

# extract depression 

# Flow direction is prepared in 1-byte SIGNED integer (int8). The flow direction is represented as follows.
# 1: east, 2: southeast, 4: south, 8: southwest, 16: west, 32: northwest, 64: north. 128: northeast
# 0: river mouth, -1: inland depression, -9: undefined (ocean)
# NOTE: If a flow direction file is opened as UNSIGNED integer, undefined=247 and inland depression=255

filename=$(basename $file  _dir.tif )

DEP=$(pkstat -hist -i $file  | grep  "^255 " | awk '{  print $1  }')

if [ -z $DEP ] ; then 
echo no depression value for $file 
else 
pkgetmask  -min 254 -max 256  -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $file -o /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/${filename}_dep.tif
gdal_edit.py -a_nodata 0 /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/${filename}_dep.tif
fi 

gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/all_tif.vrt   /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/*.tif 
rm  -f /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/all_tif_shp.* 
gdaltindex  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/all_tif_shp.shp   /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/*.tif 

# for cheching 
# ls /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/dep/*.tif | xargs -n 1 -P 12  bash -c $' DEP=$(pkstat -max  -i  $1  | awk \'{  print $2  }\' ) ; if [ $DEP -eq 1 ] ; then echo  $1 ; fi   ' _ 


# extract mask land 0 1  
file=$(ls  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/elv/*_elv.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )
filename=$(basename $file  _elv.tif  )
pkgetmask  -min -9990 -max 100000 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $file -o /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/${filename}_msk.tif
gdal_edit.py -a_nodata 0 /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/${filename}_msk.tif 

exit 

# lanciati a mano 

gdalbuildvrt -overwrite  -srcnodata 0 -vrtnodata 0  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/all_tif.vrt   /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/*_msk.tif
rm  -f /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/all_tif_shp.* 
gdaltindex  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/all_tif_shp.shp   /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/*_msk.tif








