#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc05_dem_variables_float_noMult_equi7.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc05_dem_variables_float_noMult_equi7.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc05_dem_variables_float_noMult_equi7.sh
#SBATCH --array=1-806

# 806    number of files 
# bash    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc05_dem_variables_float_noMult_equi7.sh
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc05_dem_variables_float_noMult_equi7.sh  

module load Apps/GRASS/7.3-beta

# 
# file=/gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT/equi7/dem/EU/EU_048_000.tif

file=$(ls /gpfs/loomis/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT/equi7/dem/??/??_???_???.tif | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
# use this if one file is missing

MERIT=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT
SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/grace0/dataproces/MERIT
RAM=/dev/shm
filename=$(basename $file .tif )
CT=${filename:0:2}
echo filename  $filename
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%.16f" ,  $3  - (8 * 100 )) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%.16f" ,  $4  + (8 * 100 )) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%.16f" ,  $3  + (8 * 100 )) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%.16f" ,  $4  - (8 * 100 )) }')

echo $ulx $uly $lrx $lry
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin  $ulx $uly $lrx $lry  $MERIT/equi7/dem/${CT}/all_${CT}_tif.vrt  $RAM/$filename.tif 
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif   -msknodata -9999 -nodata 0 -i $RAM/$filename.tif -o $RAM/${filename}_0.tif
gdal_edit.py  -a_nodata -9999 $RAM/${filename}_0.tif

# standard deviation 3 x 3 

pkfilter -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -of GTiff  -dx 3 -dy 3 -f stdev  -i  $RAM/${filename}_0.tif -o $RAM/stdev_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/stdev_${filename}_0.tif $RAM/stdev_${filename}_crop.tif     
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/stdev_${filename}_crop.tif  -o $MERIT/elev-stdev/tiles/elev-stdev_100M_MERIT_${filename}.tif  
rm -f $RAM/stdev_${filename}_crop.tif $RAM/stdev_${filename}_0.tif 

# echo slope with $file

#  to consider xy in degree and z in meters
gdaldem slope -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_0.tif   $RAM/slope_${filename}_0.tif 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/slope_${filename}_0.tif $RAM/slope_${filename}_crop.tif     
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/slope_${filename}_crop.tif  -o $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif  
rm -f $RAM/slope_${filename}_crop.tif $RAM/slope_${filename}_0.tif

echo  aspect  with file $file 

gdaldem aspect   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $RAM/${filename}_0.tif   $RAM/aspect_${filename}_0.tif 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/aspect_${filename}_0.tif $RAM/aspect_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/aspect_${filename}_crop.tif  -o $MERIT/aspect/tiles/aspect_100M_MERIT_${filename}.tif
rm -f $RAM/aspect_${filename}_crop.tif $RAM/aspect_${filename}_0.tif

echo sin and cos of slope and aspect $file 




gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $MERIT/aspect/tiles/aspect_100M_MERIT_${filename}.tif --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $MERIT/aspect-sine/tiles/aspect-sine_100M_MERIT_${filename}.tif --overwrite --type=Float32
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $MERIT/aspect/tiles/aspect_100M_MERIT_${filename}.tif --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $MERIT/aspect-cosine/tiles/aspect-cosine_100M_MERIT_${filename}.tif --overwrite --type=Float32

# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $MERIT/slope/tiles/${filename}.tif  --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $SCRATCH/slope/tiles/${filename}_sin.tif  --overwrite --type=Float32
# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $MERIT/slope/tiles/${filename}.tif  --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $SCRATCH/slope/tiles/${filename}_cos.tif  --overwrite --type=Float32

echo   Ew  Nw   median  

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif -B $MERIT/aspect-sine/tiles/aspect-sine_100M_MERIT_${filename}.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $MERIT/easthness/tiles/easthness_100M_MERIT_${filename}.tif --overwrite --type=Float32
gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif -B $MERIT/aspect-cosine/tiles/aspect-cosine_100M_MERIT_${filename}.tif  --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $MERIT/northness/tiles/northness_100M_MERIT_${filename}.tif --overwrite --type=Float32

echo  generate a Terrain Ruggedness Index TRI  with file   $file 
gdaldem TRI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/tri_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tri_${filename}_0.tif $RAM/tri_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/tri_${filename}_crop.tif -o $MERIT/tri/tiles/tri_100M_MERIT_${filename}.tif
rm -f $RAM/tri_${filename}_crop.tif $RAM/tri_${filename}_0.tif

echo  generate a Topographic Position Index TPI  with file  $filename.tif
gdaldem TPI -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/tpi_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/tpi_${filename}_0.tif $RAM/tpi_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/tpi_${filename}_crop.tif -o $MERIT/tpi/tiles/tpi_100M_MERIT_${filename}.tif
rm -f $RAM/tpi_${filename}_crop.tif $RAM/tpi_${filename}_0.tif

echo  generate roughness   with file   $filename.tif
gdaldem roughness -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  $RAM/${filename}_0.tif   $RAM/roughness_${filename}_0.tif
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/roughness_${filename}_0.tif $RAM/roughness_${filename}_crop.tif
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $RAM/$filename.tif  -msknodata -9999 -nodata -9999 -i $RAM/roughness_${filename}_crop.tif -o $MERIT/roughness/tiles/roughness_100M_MERIT_${filename}.tif
rm -f $RAM/roughness_${filename}_crop.tif $RAM/roughness_${filename}_0.tif


#  calculate TCI and SPI  https://grass.osgeo.org/grass73/manuals/r.watershed.html 
# TCI  topographic index ln(a / tan(b)) map 
# SPI  Stream power index a * tan(b) 

echo  generate TCI   with file   $filename.tif
# ln(α / tan(β)) where α is the cumulative upslope area draining through a point per unit contour length and tan(β) is the local slope angle.


echo  generate cti with file $filename.tif
gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif -A $MERIT/equi7/upa/${filename:0:2}/${filename}.tif  --outfile=$MERIT/cti/tiles/${filename}_tmp.tif    --calc="( log  (      A.astype(float) / (tan(  B.astype(float) * 3.141592 / 180) + 0.01 ) )  )"
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m   $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif   -msknodata -9999 -nodata -9999 -i $MERIT/cti/tiles/${filename}_tmp.tif  -o $MERIT/cti/tiles/cti_100M_MERIT_${filename}.tif
rm  $MERIT/cti/tiles/${filename}_tmp.tif

echo  generate spi with file $filename.tif
gdal_calc.py --overwrite --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND  -B $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif -A $MERIT/equi7/upa/${filename:0:2}/${filename}.tif --outfile=$MERIT/spi/tiles/${filename}_tmp.tif   --calc="(    A.astype(float) *  (tan(  B.astype(float) * 3.141592 / 180) + 0.01 )  )"
pksetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m   $MERIT/slope/tiles/slope_100M_MERIT_${filename}.tif   -msknodata -9999 -nodata -9999 -i $MERIT/spi/tiles/${filename}_tmp.tif  -o $MERIT/spi/tiles/spi_100M_MERIT_${filename}.tif
rm  $MERIT/spi/tiles/${filename}_tmp.tif

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
##      extend   Rasters containing local extend (area) of the form
##       width   Rasters containing local width of the form


/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.geomorphon  elevation=${filename}_0 forms=forms_$filename  intensity=intensity_$filename  exposition=exposition_$filename  range=range_$filename  variance=variance_$filename  elongation=elongation_$filename azimuth=azimuth_$filename   extend=extend_$filename  width=width_$filename   search=3 skip=0 flat=1 dist=0 step=0 start=0 --overwrite

r.slope.aspect elevation=${filename}_0   precision=FCELL  pcurvature=pcurv_$filename tcurvature=tcurv_$filename dx=dx_$filename dxx=dxx_$filename  dy=dy_$filename dyy=dyy_$filename  dxy=dxy_$filename

############## https://grass.osgeo.org/grass72/manuals/addons/r.convergence.html 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.convergence  input=${filename}_0  output=conv_${filename} --overwrite

# setting up the g.region to the initial tile size before to exprot 
ulxG=$(echo $ulx  | awk '{  printf ("%.16f" ,  $1  + (8 * 100 )) }')
ulyG=$(echo $uly  | awk '{  printf ("%.16f" ,  $1  - (8 * 100 )) }')
lrxG=$(echo $lrx  | awk '{  printf ("%.16f" ,  $1  - (8 * 100 )) }')
lryG=$(echo $lry  | awk '{  printf ("%.16f" ,  $1  + (8 * 100 )) }')

echo g.region w=$ulxG e=$lrxG n=$ulyG s=$lryG 
g.region      w=$ulxG e=$lrxG n=$ulyG s=$lryG 
r.mask  raster=$filename   --o 

# r.vector.ruggedness 
r.colors -r map=vrm_${filename}  
r.out.gdal -c  -f -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=vrm_${filename}  output=$MERIT/vrm/tiles/vrm_100M_MERIT_${filename}.tif  --o
gdal_edit.py  -a_nodata -9999 $MERIT/vrm/tiles/vrm_100M_MERIT_${filename}.tif 
rm -f  $MERIT/vrm/tiles/vrm_100M_MERIT_${filename}.tif.aux.xml

# r.geomorphon forms 
r.colors -r map=forms_${filename} 
r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Byte nodata=0 input=forms_$filename  output=$RAM/${filename}.tif  --o 

pkcreatect  -min 0 -max 10   > $RAM/color${filename}.txt
pkcreatect   -co COMPRESS=DEFLATE -co ZLEVEL=9   -ct  $RAM/color${filename}.txt   -i $RAM/${filename}.tif  -o $MERIT/geom/tiles/geom_100M_MERIT_${filename}.tif  
gdal_edit.py  -a_nodata 0  $MERIT/geom/tiles/geom_100M_MERIT_${filename}.tif  
rm $RAM/${filename}.tif   $RAM/color${filename}.txt

# r.geomorphon intensity # for now not computed 

# for geo in intensity exposition range variance elongation azimuth extend width ; do               
# r.colors -r map=${geo}_${filename}
# r.out.gdal -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32 nodata=-9999  input=${geo}_$filename  output=$MERIT/${geo}/tiles/${geo}_100M_MERIT_${filename}.tif  --o 
# gdal_edit.py  -a_nodata -9999  $MERIT/${geo}/tiles/${geo}_100M_MERIT_${filename}.tif 
# rm -f $MERIT/${geo}/tiles/${geo}_100M_MERIT_${filename}.tif.aux.xml
# done 

# r.slope.aspect 
for var in  dx dxx dy dyy dxy tcurv pcurv ; do  
r.colors -r map=${var}_${filename} 
r.out.gdal -c -f  -m     createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff  type=Float32   nodata=-9999  input=${var}_$filename       output=$MERIT/${var}/tiles/${var}_100M_MERIT_${filename}.tif   --o
gdal_edit.py  -a_nodata -9999 $MERIT/${var}/tiles/${var}_100M_MERIT_${filename}.tif  
rm -f  $MERIT/${var}/tiles/${var}_100M_MERIT_${filename}.tif.aux.xml
done 

# r.convergence 
r.colors -r map=conv_${filename}  
r.out.gdal -c -m  -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9,PROFILE=GeoTIFF,INTERLEAVE=BAND" format=GTiff type=Float32  nodata=-9999  input=conv_${filename}  output=$MERIT/convergence/tiles/convergence_100M_MERIT_${filename}.tif  --o
gdal_edit.py  -a_nodata -9999 $MERIT/convergence/tiles/convergence_100M_MERIT_${filename}.tif 
rm -f  $MERIT/convergence/tiles/convergence_100M_MERIT_${filename}.tif.aux.xml


##############################

rm -rf $RAM/loc_$filename   $RAM/*.tif.aux.xml   $RAM/${filename}.tif   $RAM/$filename.vrt   $RAM/${filename}_0.tif 






