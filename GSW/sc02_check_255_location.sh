#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00    # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_nodata_cleaning.sh.%A_%a.err
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_nodata_cleaning.sh.%A_%a.err
#SBATCH  --array=1-504
#SBATCH  --mem=5G

ulimit -c 0

### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc02_nodata_cleaning.sh

source ~/bin/gdal3
source ~/bin/pktools 

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input


file=$(ls $DIR/occurrence/*tif |  head  -n  $SLURM_ARRAY_TASK_ID  |  tail  -1 ) 
filename=$(basename $file .tif )

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9   -min  253   -max 258  -i   $file  -o  $DIR/binary/$filename.tif  
gdal_translate -a_nodata  0   -co COMPRESS=DEFLATE -co ZLEVEL=9  -r average    -tr  0.008333333333333  0.008333333333333   $DIR/binary/$filename.tif  $DIR/binary/${filename}_1km.tif 

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then 
sleep 300 

gdalbuildvrt   -srcnodata 0  -vrtnodata 0  $DIR/binary/occurrence_1km.vrt  $DIR/binary/occurrence*_1km.tif  
gdal_translate -a_nodata  0   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/binary/occurrence_1km.vrt $DIR/binary/occurrence_1km.tif 
rm $DIR/binary/occurrence_1km.vrt 

fi 


exit 

change 0 254       0 land    255 sea  >  100 
extent 0 1         0 land    255 sea  >  1
occurrence 0 100   0 land    255 sea  >  100
recurrence 0 100   0 land    255 sea  >  100 
seasonality 0 12   0 land    255 sea  >  12  
