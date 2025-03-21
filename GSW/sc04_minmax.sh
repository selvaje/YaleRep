#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00    # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_minmax.sh.%A_%a.err 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_minmax.sh.%A_%a.err
#SBATCH  --array=107,146,186,21,237,240,282,284,326,335,373,385,419,425,476,70
#SBATCH  --mem=10G
#SBATCH --job-name=sc04_minmax.sh

# after the download 504 files in all the folder. 

ulimit -c 0

### for var in change transitions   extent  occurrence  recurrence  seasonality ; do   sbatch --export=var=$var  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc04_minmax.sh  ; done 


source /home/ga254/bin/gdal3
source /home/ga254/bin/pktools 

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/input

file=$(ls $DIR/${var}_download/${var}-??????????-??????????.tif  |  head  -n  $SLURM_ARRAY_TASK_ID  |  tail  -1 ) 
filename=$(basename $file .tif )

MIN=$(pkstat -min -i   $file  | awk '{ print $2 }')

# pkstat  -src_min -1  -src_max 200   -mm -i  $file | awk  '{ print $2 , $4  }'  >   $DIR/${var}_download/$filename.mm 
# gdal_translate -a_nodata 255  -tr 0.00833333333333333  0.00833333333333333 -r mode   -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/${var}_download/$filename.tif  $DIR/${var}_download/${filename}_1km.tif

pkstat  --hist  -i  $file | grep -v " 0"   >   $DIR/${var}_download/$filename.hist

exit 

#####

files in all the folders. 

429 change  
504 transitions 
428 extent  
432 occurrence  
419 recurrence 
420 seasonality

# lanciato a mano 

for var in change transitions   extent  occurrence  recurrence  seasonality ; do 
# gdalbuildvrt -overwrite  -srcnodata 255 -vrtnodata  255  $DIR/${var}_1km.vrt  $DIR/${var}_download/*_1km.tif 
# gdal_translate -a_nodata 255   -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/${var}_1km.vrt  $DIR/${var}_1km.tif
awk '{ print $1  }'  $DIR/${var}_download/${var}-*.hist | sort -g  | uniq  > $DIR/${var}_class.txt
done 


change from 0 to 200     ; 100 no changes  ;  ( 253 land ;  254  ???  ;  255 sea ) >  100 
extent from 0 to   1     ;   0 land ;   1 water ;  ( 255 sea )   >  1

occurrence from 1 to 100 ;   0 land ; 100 water ;   255 sea  >  100    #  Water Occurence 
recurrence from 1 to 100 ;   0 land ; 100 water ;   255 sea  >  100    #  Annual Water Reoccurence 

seasonality from 1 to 12 ; 12 evrymonth ;  0 land ;    255 sea  >  12  
transitions 1-10  10 class ;               0 land ; 
