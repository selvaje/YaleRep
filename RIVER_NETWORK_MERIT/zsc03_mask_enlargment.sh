#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1  
#SBATCH --array=1-1150
#SBATCH -t 1:00:00
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_mask_enlargment.sh%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_mask_enlargment.sh%A_%a.out
#SBATCH --job-name=sc03_mask_enlargment.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc03_mask_enlargment.sh

# 1150 files 

DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
DIRS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
RAM=/dev/shm

file=$(ls  /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/msk/*_msk.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )
filename=$(basename $file  _msk.tif  )

pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff  -dx 10  -dy 10 -d 10  -f max   -i $file -o    $DIRS/msk_enlarge/tiles_km1/${filename}_msk.tif 

exit 

# da attivare se serve la msk enlargment con la risoluzione minore 

ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  - (8 * 0.000833333333333 )) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  + (8 * 0.000833333333333 )) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  + (8 * 0.000833333333333 )) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  - (8 * 0.000833333333333 )) }')

echo $ulx $uly $lrx $lry  # vrt is needed to clip before to create the tif 

gdalbuildvrt -overwrite -te $ulx $lry  $lrx $uly    $RAM/$filename.vrt  $DIRP/msk/all_tif.vrt   

pkfilter -nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -of GTiff -circ  -dx 11  -dy 11  -f max   -i $file -o   $DIRP/msk_enlarge/msk_enl90m/$filename.tmp.tif 

ulxG=$(echo $ulx  | awk '{  printf ("%.16f" ,  $1  + (8 * 0.000833333333333 )) }')
ulyG=$(echo $uly  | awk '{  printf ("%.16f" ,  $1  - (8 * 0.000833333333333 )) }')
lrxG=$(echo $lrx  | awk '{  printf ("%.16f" ,  $1  - (8 * 0.000833333333333 )) }')
lryG=$(echo $lry  | awk '{  printf ("%.16f" ,  $1  + (8 * 0.000833333333333 )) }')

gdal_translate -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $ulxG $ulyG $lrxG $lryG  $DIRP/msk_enlarge/msk_enl90m/$filename.tmp.tif  $DIRP/msk_enlarge/msk_enl90m/${filename}_msk.tif 
rm $DIRP/msk_enlarge/msk_enl90m/$filename.tmp.tif 








