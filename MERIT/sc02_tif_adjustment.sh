#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02a_dem_variables_float_noMult.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02a_dem_variables_float_noMult.sh.%J.err 
#SBATCH --mail-user=email

# for file in /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n30w090_dem.tif  ; do   sbatch --export=file=$file   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc02a_dem_variables_float_noMult.sh  ; done 

MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
RAM=/dev/shm
filename=$(basename $file .tif )

echo filename  $filename 
echo file   $file 

# chech for consistence 
# cd /project/fas/sbsc/ga254/dataproces/MERIT/input_tif 
# ls *.tif | xargs -n 1 -P 8 bash -c $' gdalinfo $1 | grep Pixel | awk \'{ gsub ("[(),]"," ") ; print $4  }\'    ' _  | uniq 
# ls *.tif | xargs -n 1 -P 8 bash -c $' gdalinfo $1 -mm  | grep Comp | awk \'{ gsub ("[=,]"," ") ; print $3  }\'    ' _ | sort -g > /tmp/list_min.txt
# head -1 /tmp/list_min.txt #   -1127.794
# tail -1 /tmp/list_min.txt #    4272.999
# ls *.tif | xargs -n 1 -P 8 bash -c $' gdalinfo $1 -mm  | grep Comp | awk \'{ gsub ("[=,]"," ") ; print $4  }\'    ' _ | sort -g > /tmp/list_max.txt
# head -1 /tmp/list_max.txt  # 0.074
# tail -1 /tmp/list_max.txt  # 8839.172 
# ls *.tif | xargs -n 1 -P 8 bash -c $' gdalinfo $1  | grep "Size is"  | awk \'{ gsub ("[=,]"," ") ; print $0  }\'    ' _  | uniq = Size is 6000  6000

# 1150  files
# gdalbuildvrt   -overwrite  $INDIR/all_tif.vrt   $INDIR/*.tif 
# gdaltindex  $INDIR/all_tif_shp.shp   $INDIR/*.tif 
# Size is 432002, 174001

# Corner Coordinates:
# Upper Left  (-180.0000000,  84.9999800) (180d 0' 0.00"W, 84d59'59.93"N)
# Lower Left  (-180.0000000, -60.0002733) (180d 0' 0.00"W, 60d 0' 0.98"S)
# Upper Right ( 180.0002267,  84.9999800) (180d 0' 0.82"E, 84d59'59.93"N)
# Lower Right ( 180.0002267, -60.0002733) (180d 0' 0.82"E, 60d 0' 0.98"S)
# Center      (   0.0001133,  12.4998533) (  0d 0' 0.41"E, 12d29'59.47"N)

# adjust the coordinates 
# ls *.tif | xargs -n 1 -P 8 bash -c $' gdal_edit.py -a_ullr $(getCorners4Gtranslate $1 | awk \'{  printf ("%.0f %.0f %.0f %.0f " ,  $1 , $2 , $3 , $4 ) }\' )  $1  ' _
# rm  $INDIR/all_tif_shp.* 

# gdalbuildvrt -srcnodata -9999 -vrtnodata -9999      -overwrite  -tr 0.000833333333333333 0.000833333333333333  $INDIR/all_tif.vrt   $INDIR/*.tif 
# gdaltindex  $INDIR/all_tif_shp.shp   $INDIR/*.tif 

# Size is 432000, 174000
# Pixel Size = (0.000833333333333,-0.000833333333333)
# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)


# tile sistem non piu implementato 
# Size is 432000, 174000
#       x =   72 *  6000   y = 24 *  7250 
#       x =   36 * 12000   y = 12 * 14500 selezionata qust 

# build up the new tiles sistem 
# for xn in $(seq 0 35 ) ; do  for yn in $(seq 0 11 ) ; do echo $( expr $xn \* 12000 ) $( expr $yn \* 14500 ) 12000 14500 ; done ; done > $INDIR/../geo_file/tiles_36x12.txt 

# cat /project/fas/sbsc/ga254/dataproces/MERIT/geo_file/tiles_36x12.txt  | xargs -n 4  -P 8 bash -c $'  
# gdal_translate -of VRT  -srcwin $1 $2 12000 14500  $INDIR/all_tif.vrt $INDIR/../altitude/vrt/tiles_${1}_${2}.vrt 
# ' _ 
# gdaltindex $INDIR/../altitude/vrt/merit_tiles.shp  $INDIR/../altitude/vrt/tiles*.vrt 
# max=$(pkstat -max  -i  /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/tiles/vrt/tiles_${1}_${2}.vrt | awk \' { print $2  }\') 
# if  [ $max -eq -32768 ] ; then rm -f   /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/tiles/vrt/tiles_${1}_${2}.vrt ; fi 
# ' _ 
# gdaltindex  /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/tiles/vrt/srtm_tiles.shp  /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/tiles/vrt/*.vrt 

# ls  *.vrt >   /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/geo_file/tiles_12000.txt 
# cd /lustre/scratch/client/fas/sbsc/ga254/dataproces/SRTM/geo_file 
# awk 'NR%8==1 {x="F"++i;}{ print >  "tiles8_list12000"x".txt" }' tiles_12000.txt 





### take the coridinates from the orginal files and increment on 1 pixels
ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f"  $3  -  0.000833333333333 ) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]","") ; printf ("%.16f"  $4  +  0.000833333333333 ) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f"  $3  +  0.000833333333333 ) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]","") ; printf ("%.16f"  $4  -  0.000833333333333 ) }')

# gdal_translate -of VRT -a_nodata none -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin  $ulx $uly $lrx $lry  $INDIR/all_tif_cut.vrt $INDIR/tif_overlup/$filename.tif
# pkreclass  -of GTiff -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND -c -32768 -r 0 -i  $INDIR/tif_overlup/$filename.tif  -o $OUTDIR/altitude/tiles/$filename.tif  
# force the nodata to be -32768. gdaldem any number that is labeled to nodata will convert it in -9999 
# gdal_edit.py -a_nodata -32768  $OUTDIR/altitude/tiles/$filename.tif


echo gdalbuildvrt -te $ulx $lry $lrx $lry -overwrite $MERIT/input_tif/all_tif.vrt     $MERIT/altitude/vrt/$filename.vrt

exit 

echo  slope with file  

gdaldem slope    -s 111120 -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND   $INDIR/altitude/vrt/$filename.vrt $RAM/slope_${filename}.tif 
gdal_translate   -srcwin 1 1 6000 6000   -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/slope_${filename}.tif  $MERIT/slope/tiles/${filename}.tif  

rm $RAM/slope_${filename}.tif 
# -s to consider xy in degree and z in meters

exit 



echo  aspect  with file 

# gdaldem aspect  -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND  $OUTDIR/altitude/tiles/$filename.tif   $RAM/aspect_${filename}.tif  
# gdal_translate   -srcwin 1 1 12000 12000   -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/aspect_${filename}.tif  $OUTDIR/aspect/tiles/${filename}.tif
# rm $RAM/aspect_${filename}.tif 

echo sin and cos of slope and aspect  

# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $OUTDIR/aspect/tiles/${filename}.tif --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $OUTDIR/aspect/tiles/${filename}_sin.tif --overwrite --type=Float32
# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $OUTDIR/aspect/tiles/${filename}.tif --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $OUTDIR/aspect/tiles/${filename}_cos.tif --overwrite --type=Float32
# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $OUTDIR/slope/tiles/${filename}.tif  --calc="(sin(A.astype(float) * 3.141592 / 180))" --outfile   $OUTDIR/slope/tiles/${filename}_sin.tif  --overwrite --type=Float32
# gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $OUTDIR/slope/tiles/${filename}.tif  --calc="(cos(A.astype(float) * 3.141592 / 180))" --outfile   $OUTDIR/slope/tiles/${filename}_cos.tif  --overwrite --type=Float32

echo   Ew  Nw   median  

# gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $OUTDIR/slope/tiles/${filename}.tif -B $OUTDIR/aspect/tiles/${filename}_sin.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $OUTDIR/aspect/tiles/${filename}_Ew.tif --overwrite --type=Float32
# gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $OUTDIR/slope/tiles/${filename}.tif -B $OUTDIR/aspect/tiles/${filename}_cos.tif --calc="((sin(A.astype(float) * 3.141592 / 180)) * B.astype(float))" --outfile  $OUTDIR/aspect/tiles/${filename}_Nw.tif --overwrite --type=Float32

###############  VRM  ########################################


rm -rf $OUTDIR/vrm/tiles/loc_$filename 

source /lustre/home/client/fas/sbsc/ga254/scripts/general/create_location.sh $OUTDIR/vrm/tiles  loc_$filename $OUTDIR/altitude/tiles/$filename.tif  
~/.grass7/addons/bin/r.vector.ruggedness.py      elevation=$filename   output=${filename}_vrm
r.out.gdal -c  createopt="COMPRESS=LZW,ZLEVEL=9" format=GTiff type=Float64  input=${filename}_vrm  output=$OUTDIR/vrm/tiles/${filename}".tif" --o

rm -rf $OUTDIR/vrm/tiles/loc_$filename 

################################################

echo  generate a Terrain Ruggedness Index TRI  with file   $file
# gdaldem TRI -co COMPRESS=LZW -co ZLEVEL=9  -co INTERLEAVE=BAND $OUTDIR/altitude/tiles/$filename.tif  $RAM/tri_${filename}.tif
# gdal_translate   -srcwin 1 1 12000 12000   -co COMPRESS=LZW -co ZLEVEL=9  -co INTERLEAVE=BAND $RAM/tri_${filename}.tif  $OUTDIR/tri/tiles/${filename}.tif
# rm $RAM/tri_${filename}.tif
echo  generate a Topographic Position Index TPI  with file  $filename.tif

# gdaldem TPI  -co COMPRESS=LZW -co ZLEVEL=9 -co INTERLEAVE=BAND $OUTDIR/altitude/tiles/$filename.tif $RAM/tpi_${filename}.tif
# gdal_translate   -srcwin 1 1 12000 12000   -co COMPRESS=LZW -co ZLEVEL=9  -co INTERLEAVE=BAND $RAM/tpi_${filename}.tif  $OUTDIR/tpi/tiles/${filename}.tif
# rm $RAM/tpi_${filename}.tif

echo  generate roughness   with file   $filename.tif

# gdaldem  roughness   -co COMPRESS=LZW -co ZLEVEL=9  -co INTERLEAVE=BAND  $OUTDIR/altitude/tiles/$filename.tif  $RAM/roughness_${filename}.tif
# gdal_translate   -srcwin 1 1 12000 12000   -co COMPRESS=LZW -co ZLEVEL=9  -co INTERLEAVE=BAND $RAM/roughness_${filename}.tif  $OUTDIR/roughness/tiles/${filename}.tif
# rm $RAM/roughness_${filename}.tif


' _ 

exit 

# start the aggregation in automatic using the same list 

for km in 1 5 10 50 100 ; do qsub  -v km=$km,list=$list   /home/fas/sbsc/ga254/scripts/SRTM/sc3a_dem_variables_float_noMult_resKM.sh ; done 

checkjob -v $PBS_JOBID 

rm -f /dev/shm/* 

