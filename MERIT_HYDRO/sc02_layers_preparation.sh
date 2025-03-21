#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH --array=1-1148
#SBATCH -t 0:10:00
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_layers_preparation.sh%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_layers_preparation.sh%A_%a.out
#SBATCH --job-name=sc02_layers_preparation.sh

#### 1148 final tif number after removing 2 tifi _only1pixel 

##### sbatch  --dependency=afterok:$(myq |  grep sc01_wget_merit_hydro_river.sh  | awk '{  print $1 }'  ) /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc02_layers_preparation.sh

source ~/bin/gdal
source ~/bin/pktools

HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

# file=$(ls $HYDRO/dir/*_dir.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )

# # extract depression 

# # Flow direction is prepared in 1-byte SIGNED integer (int8). The flow direction is represented as follows.
# # 1: east, 2: southeast, 4: south, 8: southwest, 16: west, 32: northwest, 64: north. 128: northeast
# # 0: river mouth, -1: inland depression, -9: undefined (ocean)
# # NOTE: If a flow direction file is opened as UNSIGNED integer, undefined=247 and inland depression=255
# # 0: river mouth is a 1 pixel line arround the coast

# filename=$(basename $file  _dir.tif )

# DEP=$(pkstat -hist -i $file  | grep  "^255 " | awk '{  print $1  }')

# if [ -z $DEP ] ; then 
# echo no depression value for $file 
# else 
# pkgetmask  -min 254 -max 256  -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $file -o $HYDRO/dep/${filename}_dep.tif
# gdal_edit.py -a_nodata 0 $HYDRO/dep/${filename}_dep.tif
# fi 

# ## for cheching 
# ##  ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dep/*.tif | xargs -n 1 -P 12  bash -c $' DEP=$(pkstat -max  -i  $1  | awk \'{  print $2  }\' ) ; if [ $DEP -eq 1 ] ; then echo  $1 ; fi   ' _ 

# # extract mask land 0 1  
file=$(ls $HYDRO/elv/*_elv.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )
filename=$(basename $file  _elv.tif  )
# pkgetmask  -min -9990 -max 100000 -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $file -o $HYDRO/msk/${filename}_msk.tif
# gdal_edit.py -a_nodata 0  $HYDRO/msk/${filename}_msk.tif 

## pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte   -of GTiff  -dx 10 -dy 10 -d 10   -f max -i $HYDRO/msk/${filename}_msk.tif  -o $HYDRO/msk_1km/${filename}_msk_d10.tif

pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte   -of GTiff  -dx 40 -dy 40 -d 40   -f max -i $HYDRO/msk/${filename}_msk.tif  -o $HYDRO/msk_1km/${filename}_msk_d40.tif

# for now not processed 
# pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte   -of GTiff  -dx 11 -dy 11 -circ   -f max -i $HYDRO/msk/${filename}_msk.tif  -o $HYDRO/msk_1km/${filename}_msk_d1.tif

exit 
