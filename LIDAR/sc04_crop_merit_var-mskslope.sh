#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 3:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_crop_merit_var.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_crop_merit_var.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc04_crop_merit_var.sh 

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc04_crop_merit_var-mskslope.sh 


export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export LIDAR=/project/fas/sbsc/ga254/dataproces/LIDAR

echo create vrt file 

# echo azimuth dx dxy dyy exposition forms intensity pcurv roughness spi tcurv tpi variance width convergence dxx dy elongation extend range slope tci tri vrm | xargs -n 1 -P 8 bash -c $' 

# dir=$1
# rm -f  $MERIT/$dir/tiles/all_tif.vrt 
# gdalbuildvrt $MERIT/$dir/tiles/all_tif.vrt  $MERIT/$dir/tiles/*.tif  -overwrite
# ' _ 

# for var in cos sin Nw Ew ; do 
# dir=aspect 
# rm -f  $MERIT/$dir/tiles/all_tif_$var.vrt 
# gdalbuildvrt  $MERIT/$dir/tiles/all_tif_$var.vrt  $MERIT/$dir/tiles/*$var.tif  -overwrite
# done 

echo crop merit data 

# ls /project/fas/sbsc/ga254/dataproces/LIDAR/*/dsm*.tiff | grep -v aspect  | xargs -n 1 -P 8 bash -c $' 
# file=$1
# filename=$(basename $file)

# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $file) $MERIT/$(basename $(dirname $file ))/tiles/all_tif.vrt $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30} 

# pksetmask -m $LIDAR/input/SC14_CZO/dtm_wgs84_slope2.tif   -msknodata 0 -nodata -9999   -i  $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30}   -o $LIDAR/$(basename $(dirname $file ))/mrt${filename:3:30} 
# rm   $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30} 

# ' _

ls /project/fas/sbsc/ga254/dataproces/LIDAR/aspect/dsm*e_{cos,sin,Nw,Ew}.tiff | xargs -n 1 -P 8 bash -c $' 
file=$1
filename=$(basename $file)
var=$( basename  $(echo $filename | cut -f 5 -d "_" )   .tif )

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $(getCorners4Gtranslate $file)  $MERIT/$(basename $(dirname $file ))/tiles/all_tif_$var.vrt $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30} 

pksetmask -m $LIDAR/input/SC14_CZO/dtm_wgs84_slope2.tif   -msknodata 0 -nodata -9999   -i  $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30}    -o $LIDAR/$(basename $(dirname $file ))/mrt${filename:3:30} 
rm   $LIDAR/$(basename $(dirname $file ))/tmpmrt${filename:3:30} 

' _

