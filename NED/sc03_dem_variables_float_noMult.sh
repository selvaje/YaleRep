#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 5:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_dem_variables_float_noMult.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_dem_variables_float_noMult.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_dem_variables_float_noMult.sh
#SBATCH --array=1-98

# # bash /gpfs/home/fas/sbsc/ga254/scripts/NED/sc03_dem_variables_float_noMult.sh /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_066_048.tif 

# 98  number of files 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/NED/sc03_dem_variables_float_noMult.sh  

module load Apps/GRASS/7.3-beta

## create directory 
## for VAR in forms aspect dx dxx dxy dy dyy pcurv roughness slope tcurv  tpi  tri vrm spi tci convergence  intensity exposition range variance elongation azimuth extend width   ; do for MATH in min max mean median  stdev tiles ; do for  KM in 1 5 10 50 100  ; do mkdir -p  $VAR/$MATH/tiles_km$KM ; done ; done ; done

#file=$(ls /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA*.tif  | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
file=$1
# use this if one file is missing 

MERIT=/project/fas/sbsc/ga254/dataproces/MERIT 
NED=/project/fas/sbsc/ga254/dataproces/NED
RAM=/dev/shm
filename=$(basename $file .tif )
echo filename  $filename 
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

### take the coridinates from the orginal files and increment on 8  pixels

ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  - (8 * 100 )) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  + (8 * 100 )) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  + (8 * 100 )) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  - (8 * 100 )) }')

echo $ulx $uly $lrx $lry  # vrt is needed to clip before to create the tif 
gdalbuildvrt -overwrite -te $ulx $lry  $lrx $uly    $RAM/$filename.vrt  $NED/input_tif/all_NA_tif.vrt   
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulx $uly $lrx $lry  $RAM/$filename.vrt   $RAM/$filename.tif 
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif   -msknodata -9999 -nodata 0 -i $RAM/$filename.tif -o $RAM/${filename}_0.tif
gdal_edit.py  -a_nodata -9999 $RAM/${filename}_0.tif

# echo slope with $file

# -s to consider xy in degree and z in meters
gdaldem slope   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_0.tif   $RAM/slope_${filename}_0.tif 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/slope_${filename}_0.tif $RAM/slope_${filename}_crop.tif     
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/slope_${filename}_crop.tif  -o $NED/slope/tiles/${filename}.tif  
rm -f $RAM/slope_${filename}_crop.tif $RAM/slope_${filename}_0.tif

echo  aspect  with file $file 

# there are compleatly flat area that become -9999 so insert the zero_for_flat
gdaldem aspect -zero_for_flat   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_0.tif   $RAM/aspect_${filename}_0.tif 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/aspect_${filename}_0.tif $RAM/aspect_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/aspect_${filename}_crop.tif  -o $NED/aspect/tiles/${filename}.tif
rm -f $RAM/aspect_${filename}_crop.tif $RAM/aspect_${filename}_0.tif

echo sin and cos of slope and aspect $file 

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $NED/aspect/tiles/${filename}.tif --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $NED/aspect-sine/tiles/${filename}.tif --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $NED/aspect/tiles/${filename}.tif --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $NED/aspect-cosine/tiles/${filename}.tif --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $NED/slope/tiles/${filename}.tif  --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $NED/slope/tiles/${filename}_sin.tif  --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $NED/slope/tiles/${filename}.tif  --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $NED/slope/tiles/${filename}_cos.tif  --overwrite --type=Float32

echo   eastness  northness   median  

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $NED/slope/tiles/${filename}.tif -B $NED/aspect-sine/tiles/${filename}.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $NED/eastness/tiles/${filename}.tif --overwrite --type=Float32
gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $NED/slope/tiles/${filename}.tif -B $NED/aspect-cosine/tiles/${filename}.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $NED/northness/tiles/${filename}.tif --overwrite --type=Float32

echo  generate a Terrain Ruggedness Index TRI  with file   $file 
gdaldem TRI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/tri_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tri_${filename}_0.tif $RAM/tri_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/tri_${filename}_crop.tif -o $NED/tri/tiles/${filename}.tif
rm -f $RAM/tri_${filename}_crop.tif $RAM/tri_${filename}_0.tif

echo  generate a Topographic Position Index TPI  with file  $filename.tif
gdaldem TPI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/tpi_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tpi_${filename}_0.tif $RAM/tpi_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/tpi_${filename}_crop.tif -o $NED/tpi/tiles/${filename}.tif
rm -f $RAM/tpi_${filename}_crop.tif $RAM/tpi_${filename}_0.tif

echo  generate roughness   with file   $filename.tif
gdaldem roughness -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/roughness_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/roughness_${filename}_0.tif $RAM/roughness_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/roughness_${filename}_crop.tif -o $NED/roughness/tiles/${filename}.tif
rm -f $RAM/roughness_${filename}_crop.tif $RAM/roughness_${filename}_0.tif


#  calculate TCI and SPI  https://grass.osgeo.org/grass73/manuals/r.watershed.html 
# TCI  topographic index ln(a / tan(b)) map 
# SPI  Stream power index a * tan(b) 

##  echo  generate TCI   with file   $filename.tif
##  ln(α / tan(β)) where α is the cumulative upslope area draining through a point per unit contour length and tan(β) is the local slope angle.

##  echo  generate tci with file $filename.tifx

gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $NED/slope/tiles/${filename}.tif -A  $MERIT/equi7/upa/NA/${filename}.tif    --outfile=$NED/cti/tiles/${filename}_tmp.tif    --calc="( log  (      A.astype(float) / (tan(  B.astype(float) * 3.141592 / 180) + 0.01 ) )  )"
 pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m   $NED/slope/tiles/${filename}.tif   -msknodata -9999 -nodata -9999 -i $NED/cti/tiles/${filename}_tmp.tif  -o $NED/cti/tiles/${filename}.tif
 rm  $NED/cti/tiles/${filename}_tmp.tif

echo  generate spi with file $filename.tif
 gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $NED/slope/tiles/${filename}.tif -A $MERIT/equi7/upa/NA/${filename}.tif --outfile=$NED/spi/tiles/${filename}_tmp.tif --calc="(    A.astype(float) *  (tan(  B.astype(float) * 3.141592 / 180) + 0.01 ) )"
 pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m   $NED/slope/tiles/${filename}.tif   -msknodata -9999 -nodata -9999 -i $NED/spi/tiles/${filename}_tmp.tif  -o $NED/spi/tiles/${filename}.tif

 rm  $NED/spi/tiles/${filename}_tmp.tif

# ###############  VRM  ########################################

rm -rf $RAM/loc_$filename 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh    $RAM loc_$filename   $RAM/${filename}_0.tif 

filename=$( basename  $file _0.tif )  # necessario per sovrascirve il filename di create location

r.in.gdal in=$RAM/$filename.tif   out=$filename --overwrite  memory=2000 # used later as mask

/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.vector.ruggedness elevation=${filename}_0   output=vrm_${filename}  --overwrite 

##   intensity   Rasters containing mean relative elevation of the form
##  exposition   Rasters containing maximum difference between extend and central cell
##       range   Rasters containing difference between max and min elevation of the form extend
##    variance   Rasters containing variance of form boundary
##  elongation   Rasters containing local elongation
##     azimuth   Rasters containing local azimuth of the elongation
##      extend   Rasters containing local extend area of the form
##       width   Rasters containing local width of the form

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.geomorphon  elevation=${filename}_0 forms=forms_$filename  intensity=intensity_$filename  exposition=exposition_$filename  range=range_$filename  variance=variance_$filename  elongation=elongation_$filename azimuth=azimuth_$filename   extend=extend_$filename  width=width_$filename   search=3 skip=0 flat=1 dist=0 step=0 start=0 --overwrite

r.slope.aspect elevation=${filename}_0   precision=FCELL  pcurvature=pcurv_$filename tcurvature=tcurv_$filename dx=dx_$filename dxx=dxx_$filename  dy=dy_$filename dyy=dyy_$filename  dxy=dxy_$filename

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

# r.vector.ruggedness 
r.colors -r map=vrm_${filename}  
r.out.gdal -c  -f -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=vrm_${filename}  output=$NED/vrm/tiles/${filename}.tif  --o
gdal_edit.py  -a_nodata -9999 $NED/vrm/tiles/${filename}.tif
rm -f $NED/vrm/tiles/${filename}.tif.aux.xml

# r.geomorphon forms 
r.colors -r map=forms_${filename} 
r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Byte nodata=0 input=forms_$filename  output=$RAM/${filename}.tif 

pkcreatect  -min 0 -max 10   > $RAM/color${filename}.txt
pkcreatect   -co COMPRESS=DEFLATE -co ZLEVEL=9   -ct  $RAM/color${filename}.txt   -i $RAM/${filename}.tif  -o $NED/forms/tiles/${filename}.tif  
gdal_edit.py  -a_nodata 0  $NED/forms/tiles/${filename}.tif 
rm $RAM/${filename}.tif   $RAM/color${filename}.txt

r.geomorphon intensity

for geo in intensity exposition range variance elongation azimuth extend width ; do               
r.colors -r map=${geo}_${filename}
r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32 nodata=-9999  input=${geo}_$filename  output=$NED/${geo}/tiles/${filename}.tif
gdal_edit.py  -a_nodata -9999  $NED/${geo}/tiles/${filename}.tif
rm -f $NED/${geo}/tiles/${filename}.tif.aux.xml
done 

# r.slope.aspect 
for var in  dx dxx dy dyy dxy tcurv pcurv ; do  
r.colors -r map=${var}_${filename} 
r.out.gdal -c -f  -m     createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff  type=Float32   nodata=-9999  input=${var}_$filename       output=$NED/${var}/tiles/${filename}.tif   --o ; 
gdal_edit.py  -a_nodata -9999 $NED/${var}/tiles/${filename}.tif 
rm -f $NED/${var}/tiles/${filename}.tif.aux.xml
done 

# r.covergence 
r.colors -r map=conv_${filename}  
r.out.gdal -c -m  -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=conv_${filename}  output=$NED/convergence/tiles/${filename}.tif  --o
gdal_edit.py  -a_nodata -9999 $NED/convergence/tiles/${filename}.tif
rm -f $NED/convergence/tiles/${filename}.tif.aux.xml


##############################






rm -rf $RAM/loc_$filename   $RAM/${filename}.tif.aux.xml   $RAM/${filename}.tif   $RAM/$filename.vrt   $RAM/${filename}_0.tif 






