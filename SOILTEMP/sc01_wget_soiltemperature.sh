#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_soiltemperature.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_soiltemperature.sh.%A_%a.err
#SBATCH --job-name=sc01_wget_soiltemperature.sh
#SBATCH --array=1-48%4
#SBATCH --mem=10G

#####  #SBATCH --array=1-48

source ~/bin/gdal3

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILTEMP/sc01_wget_soiltemperature.sh

# files at https://zenodo.org/record/4558732#.YhZQoHWYWV5
# publication at https://onlinelibrary.wiley.com/doi/10.1111/gcb.16060 

##   ssh transfer "curl -s https://zenodo.org/record/4558732#.Ydv0Hf7MJPY" | grep "link rel=" | awk -F[\"] '{print $6}' | grep tif > /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILTEMP/input/list_tif.txt 

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILTEMP

### SLURM_ARRAY_TASK_ID=1
LINE=$(cat $DIR/input/list_tif.txt | head -n $SLURM_ARRAY_TASK_ID | tail -1)  
file=$( echo $LINE | sed 's,/, ,g' | awk '{print $6}')
filename=$(basename $file .tif)

rm -f $DIR/input/$file
ssh transfer "wget -c  -nH -P $DIR/input   $LINE -q " 
GDAL_CACHEMAX=8000
mv $DIR/input/$file $DIR/input/${filename}_orig.tif
gdal_translate  -co BLOCKXSIZE=512 -co BLOCKYSIZE=512  -co TILED=YES  -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin 0 0 43200 21120 $DIR/input/${filename}_orig.tif $DIR/input/${filename}.tif

exit 
