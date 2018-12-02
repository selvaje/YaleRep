#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_geomorphon_1-100km.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_geomorphon_1-100km.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc10_geomorphon_1-100km.sh 

# for file in altitude_100KMmedian_MERIT.tif altitude_10KMmedian_MERIT.tif altitude_1KMmedian_MERIT.tif altitude_50KMmedian_MERIT.tif altitude_5KMmedian_MERIT.tif; do sbatch --export=file=$file /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_geomorphon_1-100km.sh; done 

# bash /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc10_geomorphon_1-100km.sh   /project/fas/sbsc/ga254/dataproces/MERIT/altitude/median/altitude_100KMmedian_MERIT.tif 

# export file=$1 

export filename=$( basename $file .tif )
export RAM=/dev/shm
DIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/altitude/median
rm -r /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/forms_1-100km/loc_$filename

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh   /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/forms_1-100km loc_$filename  $DIR/$file 

echo  3 5 7 9 | xargs -n 1 -P 4 bash -c $'  
search=$1
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.geomorphon  elevation=${filename}  forms=forms${search}_${filename} search=${search} skip=0 flat=1 dist=0 step=0 start=0 --overwrite

r.colors -r map=forms${search}_${filename}
r.out.gdal -c -f createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND"  format=GTiff type=Byte nodata=0 input=forms${search}_${filename}   output=${RAM}/forms${search}_${filename}.tif 

pkcreatect  -min 0 -max 10   > $RAM/forms${search}_${filename}.txt
pkcreatect   -co COMPRESS=DEFLATE -co ZLEVEL=9   -ct  $RAM/forms${search}_${filename}.txt    -i $RAM/forms${search}_${filename}.tif     -o /project/fas/sbsc/ga254/dataproces/MERIT/forms_1-100km/forms${search}_${filename}.tif   
gdal_edit.py  -a_nodata 0  /project/fas/sbsc/ga254/dataproces/MERIT/forms_1-100km/forms${search}_${filename}.tif   
rm -f $RAM/forms${search}_${filename}.tif     $RAM/forms${search}_${filename}.txt

' _ 


