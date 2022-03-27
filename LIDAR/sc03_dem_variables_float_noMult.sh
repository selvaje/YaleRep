#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 3:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_dem_variables_float_noMult.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_dem_variables_float_noMult.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_dem_variables_float_noMult.sh

# # for file in /project/fas/sbsc/ga254/dataproces/LIDAR/input/*/d{s,t}m_wgs84_crop_a.tif  ; do   sbatch --export=file=$file   /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc03_dem_variables_float_noMult.sh  ; done 
# # bash /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc03_dem_variables_float_noMult.sh /project/fas/sbsc/ga254/dataproces/LIDAR/input/ID09_Lloyd/dsm_wgs84_crop_a.tif

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc03_dem_variables_float_noMult.sh  

module load Apps/GRASS/7.3-beta

# use this if one file is missing 

LIDAR=/project/fas/sbsc/ga254/dataproces/LIDAR
RAM=/dev/shm
# file=$1
filename=$(basename $file .tif )

### take the coridinates from the orginal files and increment on 8  pixels

xsize=$(  pkinfo -ns  -i  $file | awk '{ print $2 -2  }' )
ysize=$(  pkinfo -nl  -i  $file | awk '{ print $2 -2  }' )

# -s to consider xy in degree and z in meters
gdaldem slope    -s 111120 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   ${file}   $RAM/slope_${filename}_0.tif 
gdal_translate   -srcwin 1 1 $xsize $ysize   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/slope_${filename}_0.tif $LIDAR/slope/${filename}.tif  
rm -f $RAM/slope_${filename}_0.tif

echo  aspect  with file $file 

gdaldem aspect   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  ${file}   $RAM/aspect_${filename}_0.tif 
gdal_translate   -srcwin  1 1 $xsize $ysize   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/aspect_${filename}_0.tif $LIDAR/aspect/${filename}.tif
rm -f $RAM/aspect_${filename}_0.tif


echo sin and cos of slope and aspect $file 

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $LIDAR/aspect/${filename}.tif --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $LIDAR/aspect/${filename}_sin.tif --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $LIDAR/aspect/${filename}.tif --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $LIDAR/aspect/${filename}_cos.tif --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $LIDAR/slope/${filename}.tif  --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $LIDAR/slope/${filename}_sin.tif  --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $LIDAR/slope/${filename}.tif  --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $LIDAR/slope/${filename}_cos.tif  --overwrite --type=Float32

echo   Ew  Nw   median  

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $LIDAR/slope/${filename}.tif -B $LIDAR/aspect/${filename}_sin.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $LIDAR/aspect/${filename}_Ew.tif --overwrite --type=Float32
gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $LIDAR/slope/${filename}.tif -B $LIDAR/aspect/${filename}_cos.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $LIDAR/aspect/${filename}_Nw.tif --overwrite --type=Float32

echo  generate a Terrain Ruggedness Index TRI  with file   $file 
gdaldem TRI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  ${file}   $RAM/tri_${filename}_0.tif
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tri_${filename}_0.tif $LIDAR/tri/${filename}.tif
rm -f  $RAM/tri_${filename}_0.tif

echo  generate a Topographic Position Index TPI  with file  $filename.tif
gdaldem TPI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  ${file}   $RAM/tpi_${filename}_0.tif
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tpi_${filename}_0.tif $LIDAR/tpi/${filename}.tif
rm -f  $RAM/tpi_${filename}_0.tif

echo  generate roughness   with file   $filename.tif
gdaldem roughness -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  ${file}   $RAM/roughness_${filename}_0.tif
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/roughness_${filename}_0.tif  $LIDAR/roughness/${filename}.tif
rm -f $RAM/roughness_${filename}_0.tif


#  calculate TCI and SPI  https://grass.osgeo.org/grass73/manuals/r.watershed.html 
# TCI  topographic index ln(a / tan(b)) map 
# SPI  Stream power index a * tan(b) 

# echo  generate TCI   with file   $filename.tif
# ln(α / tan(β)) where α is the cumulative upslope area draining through a point per unit contour length and tan(β) is the local slope angle.

# filenameupa=$(basename $file dem.tif)

# echo  generate tci with file $filename.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin  $(getCorners4Gtranslate  $LIDAR/roughness/${filename}.tif ) /project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upa/all_tif.vrt  $LIDAR/upa/${filename}.tif
gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $LIDAR/slope/${filename}.tif -A $LIDAR/upa/${filename}.tif  --outfile=$LIDAR/tci/${filename}.tif    --calc="(log ( A.astype(float) / (tan(  B.astype(float) * 3.141592 / 180) + 0.01 ) ) )"

# echo  generate spi with file $filename.tif
gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $LIDAR/slope/${filename}.tif -A $LIDAR/upa/${filename}.tif  --outfile=$LIDAR/spi/${filename}.tif   --calc="(    A.astype(float) *  (tan(  B.astype(float) * 3.141592 / 180) + 0.01 )  )"
rm  $LIDAR/spi/${filename}_tmp.tif

# ###############  VRM  ########################################

rm -rf $RAM/loc_$filename 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh    $RAM loc_$filename   ${file}

filename=$( basename  $file .tif )  # necessario per sovrascirve il filename di create location

r.in.gdal in=$file   out=$filename --overwrite  memory=2000 # used later as mask

/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.vector.ruggedness elevation=${filename}   output=vrm_${filename}  --overwrite 

##   intensity   Rasters containing mean relative elevation of the form
##  exposition   Rasters containing maximum difference between extend and central cell
##       range   Rasters containing difference between max and min elevation of the form extend
##    variance   Rasters containing variance of form boundary
##  elongation   Rasters containing local elongation
##     azimuth   Rasters containing local azimuth of the elongation
##      extend   Rasters containing local extend (area) of the form
##       width   Rasters containing local width of the form

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.geomorphon  elevation=${filename} forms=forms_$filename  intensity=intensity_$filename  exposition=exposition_$filename  range=range_$filename  variance=variance_$filename  elongation=elongation_$filename azimuth=azimuth_$filename   extend=extend_$filename  width=width_$filename   search=3 skip=0 flat=1 dist=0 step=0 start=0 --overwrite

r.slope.aspect elevation=${filename}   precision=FCELL  pcurvature=pcurv_$filename tcurvature=tcurv_$filename dx=dx_$filename dxx=dxx_$filename  dy=dy_$filename dyy=dyy_$filename  dxy=dxy_$filename

############## https://grass.osgeo.org/grass72/manuals/addons/r.convergence.html 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.convergence  input=${filename}  output=conv_${filename} --overwrite

# r.vector.ruggedness 
r.colors -r map=vrm_${filename}  
r.out.gdal -c  -f -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=vrm_${filename}  output=$LIDAR/vrm/${filename}_tmp.tif  --o
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $LIDAR/vrm/${filename}_tmp.tif   $LIDAR/vrm/${filename}.tif
gdal_edit.py  -a_nodata -9999 $LIDAR/vrm/${filename}.tif
rm -f $LIDAR/vrm/${filename}.tif.aux.xml $LIDAR/vrm/${filename}_tmp.tif 

# r.geomorphon forms 
r.colors -r map=forms_${filename} 
r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Byte nodata=0 input=forms_$filename  output=$RAM/${filename}_tmp.tif 
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_tmp.tif  $RAM/${filename}.tif
pkcreatect  -min 0 -max 10   > $RAM/color${filename}.txt
pkcreatect   -co COMPRESS=DEFLATE -co ZLEVEL=9   -ct  $RAM/color${filename}.txt   -i $RAM/${filename}.tif  -o $LIDAR/forms/${filename}.tif  
gdal_edit.py  -a_nodata 0  $LIDAR/forms/${filename}.tif 
rm $RAM/${filename}.tif   $RAM/color${filename}.txt   $RAM/${filename}_tmp.tif 

r.geomorphon intensity

for geo in intensity exposition range variance elongation azimuth extend width ; do               
r.colors -r map=${geo}_${filename}
r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32 nodata=-9999  input=${geo}_$filename  output=$LIDAR/${geo}/${filename}_tmp.tif
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $LIDAR/${geo}/${filename}_tmp.tif  $LIDAR/${geo}/${filename}.tif
gdal_edit.py  -a_nodata -9999  $LIDAR/${geo}/${filename}.tif
rm -f $LIDAR/${geo}/${filename}.tif.aux.xml $LIDAR/${geo}/${filename}_tmp.tif  
done 

# r.slope.aspect 
for var in  dx dxx dy dyy dxy tcurv pcurv ; do  
r.colors -r map=${var}_${filename} 
r.out.gdal -c -f  -m     createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff  type=Float32   nodata=-9999  input=${var}_$filename       output=$LIDAR/${var}/${filename}_tmp.tif   --o ; 
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $LIDAR/${var}/${filename}_tmp.tif  $LIDAR/${var}/${filename}.tif
gdal_edit.py  -a_nodata -9999 $LIDAR/${var}/${filename}.tif 
rm -f $LIDAR/${var}/${filename}.tif.aux.xml $LIDAR/${var}/${filename}_tmp.tif  
done 

# r.covergence 
r.colors -r map=conv_${filename}  
r.out.gdal -c -m  -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=conv_${filename}  output=$LIDAR/convergence/${filename}_tmp.tif  --o
gdal_translate   -srcwin 1 1 $xsize $ysize  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $LIDAR/convergence/${filename}_tmp.tif  $LIDAR/convergence/${filename}.tif
gdal_edit.py  -a_nodata -9999 $LIDAR/convergence/${filename}.tif
rm -f $LIDAR/convergence/${filename}.tif.aux.xml $LIDAR/convergence/${filename}_tmp.tif 


##############################


rm -rf $RAM/loc_$filename   $RAM/${filename}.tif.aux.xml   $RAM/${filename}.tif   $RAM/$filename.vrt   $RAM/${filename}.tif 






