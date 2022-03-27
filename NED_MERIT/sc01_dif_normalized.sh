#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 2:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_dif_normalized.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_dif_normalized.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc01_dif_normalized.sh

# # bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc01_dif_normalized.sh /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_072_048.tif 
# # bash /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc01_dif_normalized.sh /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_072_018.tif 

# for file in /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_072_048.tif /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_072_018.tif /project/fas/sbsc/ga254/dataproces/NED/input_tif/NA_066_048.tif  ; do sbatch  --export=file=$file  /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc01_dif_normalized.sh ; done 

## create  vrt 
## cd /project/fas/sbsc/ga254/dataproces/NED
## for VAR in aspect aspect-cosine aspect-sine eastness northness  dx dxx dxy dy dyy pcurv roughness  tcurv  tpi  tri vrm spi cti convergence  ; do   gdalbuildvrt $VAR/tiles/all_NA_tif.vrt $VAR/tiles/NA*.tif ; done
## cd /project/fas/sbsc/ga254/dataproces/MERIT/gdrive100m  
## for VAR in aspect aspect-cosine aspect-sine eastness northness  slope  dx dxx dxy dy dyy pcurv roughness  tcurv  tpi  tri vrm spi cti convergence  ; do   gdalbuildvrt  -overwrite  /project/fas/sbsc/ga254/dataproces/MERIT/gdrive100m/$VAR/all_NA_tif.vrt  /project/fas/sbsc/ga254/dataproces/MERIT/gdrive100m/$VAR/*NA*.tif ; done

# file=$1

export  NED=/project/fas/sbsc/ga254/dataproces/NED
export  MERITG=/project/fas/sbsc/ga254/dataproces/MERIT/gdrive100m  
export  MERITP=/project/fas/sbsc/ga254/dataproces/MERIT
export  NM=/project/fas/sbsc/ga254/dataproces/NED_MERIT
export  RAM=/dev/shm

export filename=$(basename $file .tif )

echo filename  $filename 
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

### take the coridinates from the orginal files and increment on 8  pixels

export ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  - (8 * 100 )) }')
export uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  + (8 * 100 )) }')
export lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  + (8 * 100 )) }')
export lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  - (8 * 100 )) }')

# for the /home/fas/sbsc/ga254/scripts/NED_MERIT/sc10_plotNormDif_levelplot_equi7_for_annex2.R.sh   e = extent ( 6890000 , 6910000 ,  5200000 , 5218400 )
if [ $filename = "NA_066_048" ] ; then export ulx=6890000  ; export  uly=5218400  ;  export lrx=6910000 ;  export lry=5200000  ; fi   
                                               
echo slope aspect aspect-cosine aspect-sine eastness northness dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 8 bash -c $'

VAR=$1

echo MERITG translate  MERITG translate   MERITG translate  
gdal_translate  -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry   $MERITG/$VAR/all_NA_tif.vrt $RAM/${filename}_${VAR}_M.tif 
echo NET translate   NET translate  NET translate 
gdal_translate  -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry   $NED/$VAR/tiles/all_NA_tif.vrt $RAM/${filename}_${VAR}_N.tif  

echo slope with $filename

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A   $RAM/${filename}_${VAR}_M.tif -B   $RAM/${filename}_${VAR}_N.tif \
 --calc="( B.astype(float) - A.astype(float) )" --outfile   $NM/${VAR}/tiles/${filename}_dif.tif --overwrite --type=Float32
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif.tif 

if [ $filename != "NA_066_048" ] ; then 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $NM/${VAR}/tiles/${filename}_dif.tif  $NM/${VAR}/tiles/${filename}_dif1.tif  -a_nodata -9999
mv $NM/${VAR}/tiles/${filename}_dif1.tif $NM/${VAR}/tiles/${filename}_dif.tif
fi 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $NM/${VAR}/tiles/${filename}_dif.tif -p ">" -msknodata 0 -nodata 0 -i $NM/${VAR}/tiles/${filename}_dif.tif -o $NM/${VAR}/tiles/${filename}_dif_neg.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_neg.tif 

rm -f $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml    $NM/${VAR}/tiles/${filename}_dif_norm.tif.aux.xml   
gdalinfo  -stats $NM/${VAR}/tiles/${filename}_dif.tif 
MIN=$(grep MINIMUM $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml  | awk \'{ gsub ("[<>]"," ") ;  printf ("%.30f\\n", $3) }\' )

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -scale $MIN 0 -1 0 $NM/${VAR}/tiles/${filename}_dif_neg.tif $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif -ot Float32 -a_nodata -9999

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif 
rm -f $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif 
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $NM/${VAR}/tiles/${filename}_dif.tif -p "<" -msknodata 0 -nodata 0 -i $NM/${VAR}/tiles/${filename}_dif.tif -o $NM/${VAR}/tiles/${filename}_dif_pos.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_pos.tif 

MAX=$(grep MAXIMUM $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml  | awk \'{ gsub ("[<>]"," ") ;  printf ("%.30f\\n", $3 )}\' )
rm $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -scale 0 $MAX 0 1 $NM/${VAR}/tiles/${filename}_dif_pos.tif $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif -ot Float32 -a_nodata -9999

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif 
rm -f $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif 
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif 

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif -B $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif \
 --calc="( A.astype(float) + B.astype(float) )" --outfile $NM/${VAR}/tiles/${filename}_dif_norm1.tif --overwrite --type=Float32

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_norm.tif 
rm  -f $NM/${VAR}/tiles/${filename}_dif_norm1.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_norm.tif 

#  NED : dif = 100 : x   = where x is the bias in percentage
gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A  $RAM/${filename}_${VAR}_N.tif -B $NM/${VAR}/tiles/${filename}_dif.tif --calc="((B.astype(float) * 100)/(A.astype(float) + 0.01))"  --outfile   $NM/${VAR}/tiles/${filename}_bias.tif --overwrite --type=Float32
gdal_edit.py  -a_nodata -9999   $NM/${VAR}/tiles/${filename}_bias.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND \
       -m  $NM/${VAR}/tiles/${filename}_bias.tif -msknodata  100 -p ">" -nodata 100  \
       -m  $NM/${VAR}/tiles/${filename}_bias.tif -msknodata -100 -p "<" -nodata -100 \
       -i  $NM/${VAR}/tiles/${filename}_bias.tif -o  $NM/${VAR}/tiles/${filename}_bias_msk.tif
gdal_edit.py  -a_nodata -9999   $NM/${VAR}/tiles/${filename}_bias_msk.tif

rm -f  $RAM/${filename}_${VAR}_?.tif   $RAM/${filename}_${VAR}_dif.tif  $RAM/${filename}_${VAR}_der.tif  $NM/${VAR}/tiles/${filename}*.tif.aux.xml 

' _ 

VAR=elevation
  
gdal_translate  -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry  $MERITP/equi7/dem/NA/all_NA_tif.vrt  $RAM/${filename}_${VAR}_M.tif  
gdal_translate  -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $ulx $uly $lrx $lry  $NED/input_tif/all_NA_tif.vrt       $RAM/${filename}_${VAR}_N.tif    

echo slope with $filename

gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A   $RAM/${filename}_${VAR}_M.tif -B   $RAM/${filename}_${VAR}_N.tif \
 --calc="( B.astype(float) - A.astype(float) )" --outfile   $NM/${VAR}/tiles/${filename}_dif.tif --overwrite --type=Float32
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif.tif 

if [ $filename != "NA_066_048" ] ; then 
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $NM/${VAR}/tiles/${filename}_dif.tif  $NM/${VAR}/tiles/${filename}_dif1.tif  -a_nodata -9999
mv $NM/${VAR}/tiles/${filename}_dif1.tif $NM/${VAR}/tiles/${filename}_dif.tif
fi 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $NM/${VAR}/tiles/${filename}_dif.tif -p ">" -msknodata 0 -nodata 0 -i $NM/${VAR}/tiles/${filename}_dif.tif -o $NM/${VAR}/tiles/${filename}_dif_neg.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_neg.tif 

rm -f $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml    $NM/${VAR}/tiles/${filename}_dif_norm.tif.aux.xml   
gdalinfo  -stats $NM/${VAR}/tiles/${filename}_dif.tif 
MIN=$(grep MINIMUM $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml  | awk '{ gsub ("[<>]"," ") ;  printf ("%.30f\n", $3) }' )

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -scale $MIN 0 -1 0 $NM/${VAR}/tiles/${filename}_dif_neg.tif $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif -ot Float32 -a_nodata -9999

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif 
rm -f $NM/${VAR}/tiles/${filename}_dif_neg_norm1.tif 
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $NM/${VAR}/tiles/${filename}_dif.tif -p "<" -msknodata 0 -nodata 0 -i $NM/${VAR}/tiles/${filename}_dif.tif -o $NM/${VAR}/tiles/${filename}_dif_pos.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_pos.tif 

MAX=$(grep MAXIMUM $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml  | awk '{ gsub ("[<>]"," ") ;  printf ("%.30f\n", $3 )}' )
rm $NM/${VAR}/tiles/${filename}_dif.tif.aux.xml 

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -scale 0 $MAX 0 1 $NM/${VAR}/tiles/${filename}_dif_pos.tif $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif -ot Float32 -a_nodata -9999

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif 
rm -f $NM/${VAR}/tiles/${filename}_dif_pos_norm1.tif 
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif 

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A $NM/${VAR}/tiles/${filename}_dif_pos_norm.tif -B $NM/${VAR}/tiles/${filename}_dif_neg_norm.tif  --calc="( A.astype(float) + B.astype(float) )" --outfile $NM/${VAR}/tiles/${filename}_dif_norm1.tif --overwrite --type=Float32

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m  $NM/${VAR}/tiles/${filename}_dif.tif   -msknodata -9999 -nodata -9999 -i $NM/${VAR}/tiles/${filename}_dif_norm1.tif  -o $NM/${VAR}/tiles/${filename}_dif_norm.tif 
rm  -f $NM/${VAR}/tiles/${filename}_dif_norm1.tif  
gdal_edit.py  -a_nodata -9999  $NM/${VAR}/tiles/${filename}_dif_norm.tif 

gdal_calc.py --NoDataValue=-9999 --co=COMPRESS=DEFLATE --co=ZLEVEL=9 --co=INTERLEAVE=BAND -A  $RAM/${filename}_${VAR}_N.tif -B $NM/${VAR}/tiles/${filename}_dif.tif --calc="((B.astype(float) * 100)/(A.astype(float) + 0.01))"  --outfile   $NM/${VAR}/tiles/${filename}_bias.tif --overwrite --type=Float32
gdal_edit.py  -a_nodata -9999   $NM/${VAR}/tiles/${filename}_bias.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND \
       -m  $NM/${VAR}/tiles/${filename}_bias.tif -msknodata  100 -p ">" -nodata 100  \
       -m  $NM/${VAR}/tiles/${filename}_bias.tif -msknodata -100 -p "<" -nodata -100 \
       -i  $NM/${VAR}/tiles/${filename}_bias.tif -o  $NM/${VAR}/tiles/${filename}_bias_msk.tif
gdal_edit.py  -a_nodata -9999   $NM/${VAR}/tiles/${filename}_bias_msk.tif



rm -f  $RAM/${filename}_${VAR}_?.tif   $RAM/${filename}_${VAR}_dif.tif  $RAM/${filename}_${VAR}_der.tif     $NM/${VAR}/tiles/${filename}*.tif.aux.xml  
