#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1  
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_dif_derivative.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_dif_derivative.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_dif_derivative.sh
#SBATCH --array=1-98

# # bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc01_dif_derivative.sh /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_084_042.tif

# 98 number of files 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc01_dif_derivative.sh



## create  vrt 
## cd /project/fas/sbsc/ga254/dataproces/NED
## cd /project/fas/sbsc/ga254/dataproces/MERIT 
## for VAR in  dx dxx dxy dy dyy pcurv roughness  tcurv  tpi  tri vrm spi tci convergence  ; do   gdalbuildvrt $VAR/tiles/all_NA_tif.vrt $VAR/tiles/NA*.tif ; done

file=$(ls /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA*.tif  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
# file=$1
# use this if one file is missing 

export  NED=/project/fas/sbsc/ga254/dataproces/NED
export  MERITS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export  MERITP=/project/fas/sbsc/ga254/dataproces/MERIT
export     NM=/project/fas/sbsc/ga254/dataproces/NED_MERIT
export    RAM=/dev/shm

export filename=$(basename $file .tif )

echo filename  $filename 
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

### take the coridinates from the orginal files and increment on 8  pixels

export ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  - (8 * 100 )) }')
export uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  + (8 * 100 )) }')
export lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  + (8 * 100 )) }')
export lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  - (8 * 100 )) }')

# echo slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi tci convergence   | xargs -n 1 -P 4 bash -c $'

# VAR=$1

# gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry   $MERITS/$VAR/tiles/all_NA_tif.vrt $RAM/${filename}_${VAR}_M.tif 
# gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry     $NED/$VAR/tiles/all_NA_tif.vrt $RAM/${filename}_${VAR}_N.tif 

# echo slope with $file

# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A   $RAM/${filename}_${VAR}_M.tif -B   $RAM/${filename}_${VAR}_N.tif \
#  --calc="( A.astype(float) - B.astype(float) )" --outfile   $RAM/${filename}_${VAR}_dif.tif --overwrite --type=Float32

# gdaldem slope  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_${VAR}_dif.tif $RAM/${filename}_${VAR}_der.tif 
# gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_${VAR}_der.tif $NM/${VAR}/tiles/${filename}.tif  

# rm -f  $RAM/${filename}_${VAR}_?.tif   $RAM/${filename}_${VAR}_dif.tif  $RAM/${filename}_${VAR}_der.tif      

# ' _ 


echo sin cos Nw Ew  | xargs -n 1 -P 4 bash -c $'
VAR=$1

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITS/aspect/tiles/all_NA_${VAR}_tif.vrt  $RAM/${filename}_${VAR}_M.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry   $NED/aspect/tiles/all_NA_tif_$VAR.vrt     $RAM/${filename}_${VAR}_N.tif 

echo slope with $file

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A   $RAM/${filename}_${VAR}_M.tif -B   $RAM/${filename}_${VAR}_N.tif \
  --calc="( A.astype(float) - B.astype(float) )" --outfile   $RAM/${filename}_${VAR}_dif.tif --overwrite --type=Float32

gdaldem slope  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_${VAR}_dif.tif $RAM/${filename}_${VAR}_der.tif 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_${VAR}_der.tif $NM/aspect/tiles/${filename}_$VAR.tif  

rm -f  $RAM/${filename}_${VAR}_?.tif   $RAM/${filename}_${VAR}_dif.tif  $RAM/${filename}_${VAR}_der.tif      

' _ 


exit  


# just the elevation  
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry $MERITP/equi7/dem/NA/all_NA_tif.vrt    $RAM/${filename}_M.tif
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry    $NED/input_tif/all_NA_tif.vrt       $RAM/${filename}_N.tif

echo slope with $file

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A   $RAM/${filename}_M.tif -B   $RAM/${filename}_N.tif \
--calc="( A.astype(float) - B.astype(float) )" --outfile   $RAM/${filename}_dif.tif --overwrite --type=Float32

gdaldem slope  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_dif.tif $RAM/${filename}_der.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_dif.tif $NM/input_tif/tiles/${filename}_dif.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_der.tif $NM/input_tif/tiles/${filename}.tif

rm -f  $RAM/${filename}_?.tif   $RAM/${filename}_dif.tif  $RAM/${filename}_der.tif

