#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH --array=1-1148
#SBATCH -t 0:20:00
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_cellarea_creation.sh%A_%a.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_cellarea_creation.sh%A_%a.out
#SBATCH --job-name=sc04_cellarea_creation.sh

##### 1148 final tif number after removing 2 tif  _only1pixel 

##### sbatch    /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc04_cellarea_creation.sh

source ~/bin/gdal
source ~/bin/pktools
source ~/bin/grass

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
RAM=/dev/shm

###  find  /dev/shm  -user $USER   2>/dev/null  | xargs -n 1 -P 1 rm -ifr 

###  1148 files 
##  SLURM_ARRAY_TASK_ID=3
file=$(ls $INDIR/elv/*_elv.tif | tail -n  $SLURM_ARRAY_TASK_ID | head -1 )

filename=$(basename $file  _elv.tif )


cd $INDIR/are

echo processing area $file 

grass76  -f -text --tmp-location  -c $file    <<EOF
r.external.out   directory=$INDIR/are   format="GTiff" option="COMPRESS=DEFLATE,ZLEVEL=9" 
r.cell.area  output=${filename}_are_tmp.tif  units=km2 --o
r.external.out -r -p
EOF

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -ot Float32  -a_nodata -9999   $INDIR/are/${filename}_are_tmp.tif    $INDIR/are/${filename}_are.tif 
rm $INDIR/are/${filename}_are_tmp.tif  

exit 
#### laciato a mano 


gdalbuildvrt -overwrite  -srcnodata -9999 -vrtnodata -9999  $INDIR/are/all_tif.vrt $INDIR/are/*_are.tif 
rm  -f   $INDIR/are/all_tif_shp.shp
gdaltindex $INDIR/are/all_tif_shp.shp $INDIR/are/*_are.tif 
