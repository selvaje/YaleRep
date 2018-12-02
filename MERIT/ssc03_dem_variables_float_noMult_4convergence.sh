#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 3:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_dem_variables_float_noMult.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_dem_variables_float_noMult.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_dem_variables_float_noMult.sh
#SBATCH --array=1-8

####SBATCH --array=1-1150%10

# # for file in /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n30w090_dem.tif  ; do   sbatch --export=file=$file   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc03_dem_variables_float_noMult.sh  ; done 
# # bash /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc03_dem_variables_float_noMult.sh /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n30w090_dem.tif 
# # nodata pixe in 1927385 n30w090_dem.tif 

# 1150 number of files 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc03_dem_variables_float_noMult_4convergence.sh  

module load Apps/GRASS/7.3-beta

# for dir in dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm ; do join -v  1    -1 1 -2 1 <(ls *.tif | sort ) <( ls        /project/fas/sbsc/ga254/dataproces/MERIT/$dir/tiles/  | sort ) ; done | sort | uniq  > /tmp/file_missing.txt 
# for tif in  $( cat /tmp/file_missing.txt )  ; do sbatch  --export=tif=$tif   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc03_dem_variables_float_noMult.sh   ; done
# file=/project/fas/sbsc/ga254/dataproces/MERIT/input_tif/$tif 

file=$(ls /project/fas/sbsc/ga254/dataproces/MERIT/tmp/*_dem.tif  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
# use this if one file is missing 

MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
RAM=$MERIT/tmp
# RAM=/dev/shm
filename=$(basename $file .tif )
echo filename  $filename 
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

### take the coridinates from the orginal files and increment on 8  pixels

ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  - (8 * 0.000833333333333 )) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  + (8 * 0.000833333333333 )) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $3  + (8 * 0.000833333333333 )) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f" ,  $4  - (8 * 0.000833333333333 )) }')

echo $ulx $uly $lrx $lry  # vrt is needed to clip before to create the tif 
gdalbuildvrt -overwrite -te $ulx $lry  $lrx $uly    $RAM/$filename.vrt  $MERIT/input_tif/all_tif.vrt   
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulx $uly $lrx $lry  $RAM/$filename.vrt   $RAM/$filename.tif 
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif   -msknodata -9999 -nodata 0 -i $RAM/$filename.tif -o $RAM/${filename}_0.tif
gdal_edit.py  -a_nodata -9999 $RAM/${filename}_0.tif

# ###############  VRM  ########################################

rm -rf $RAM/loc_$filename 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh    $RAM loc_$filename   $RAM/${filename}_0.tif 

filename=$( basename  $file _0.tif )  # necessario per sovrascirve il filename di create location

r.in.gdal in=$RAM/$filename.tif   out=$filename --overwrite  memory=2000 # used later as mask

############## https://grass.osgeo.org/grass72/manuals/addons/r.convergence.html 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.convergence  input=${filename}_0  output=conv_${filename} --overwrite

# setting up the g.region to the initial tile size before to exprot 
ulxG=$(echo $ulx  | awk '{  printf ("%.16f" ,  $1  + (8 * 0.000833333333333 )) }')
ulyG=$(echo $uly  | awk '{  printf ("%.16f" ,  $1  - (8 * 0.000833333333333 )) }')
lrxG=$(echo $lrx  | awk '{  printf ("%.16f" ,  $1  - (8 * 0.000833333333333 )) }')
lryG=$(echo $lry  | awk '{  printf ("%.16f" ,  $1  + (8 * 0.000833333333333 )) }')

echo g.region w=$ulxG e=$lrxG n=$ulyG s=$lryG 
g.region      w=$ulxG e=$lrxG n=$ulyG s=$lryG 
r.mask  raster=$filename   --o 


# r.covergence 
r.colors -r map=conv_${filename}  
r.out.gdal -c -m  -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=conv_${filename}  output=$MERIT/convergence/tiles/${filename}.tif  --o
gdal_edit.py  -a_nodata -9999 $MERIT/convergence/tiles/${filename}.tif
rm -f $MERIT/convergence/tiles/${filename}.tif.aux.xml


##############################


rm -rf $RAM/loc_$filename   $RAM/${filename}.tif.aux.xml   $RAM/${filename}.tif   $RAM/$filename.vrt   $RAM/${filename}_0.tif 






