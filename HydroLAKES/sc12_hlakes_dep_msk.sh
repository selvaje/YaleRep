#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_hlakes_dep_msk.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_hlakes_dep_msk.sh.%A_%a.err
#SBATCH --job-name=sc11_hlakes_dep_rec.sh
#SBATCH --mem=50G
#SBATCH --array=20,26,22

## 

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc12_hlakes_dep_msk.sh  


source ~/bin/gdal3
source ~/bin/pktools

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT_HYDRO

###                      msk cambiato as msk-merit
export file=$(  ls $MERIT/msk/*.tif | head -$SLURM_ARRAY_TASK_ID | tail -1   )
export filename=$(basename $file )

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $( getCorners4Gtranslate $file)   $DIR/tif_ID/all_tif_HydroLAKES_dep_rec.vrt   $RAM/$filename.msk.tif

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/$filename.msk.tif -p '='   -msknodata 1   -nodata 0 -i $file  -o  $MERIT/msk_caspian/$filename 
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/$filename.msk.tif -p '>'   -msknodata 0.5 -nodata 0 -i $file  -o  $MERIT/msk_depression/$filename   # only depressed-lake

# depressed-lake and depression.   ### folder change name msk_dep_lake  to msk  
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-m $RAM/$filename.msk.tif                                                -p '>'   -msknodata 0.5 -nodata 0 \
-m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dep/all_tif_dis.vrt -p '='   -msknodata 1   -nodata 0 \
-i $file  -o  $MERIT/msk_dep_lake/$filename   


rm -f  $RAM/$filename.msk.tif 


