#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_dem_variables_float_noMult_equi7_4HyperScaleRoughness.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_dem_variables_float_noMult_equi7_4HyperScaleRoughness.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc05_dem_variables_float_noMult_equi7_4HyperScaleRoughness.sh
#SBATCH --array=1-831
#SBATCH --mem-per-cpu=20000

# 831    number of files   special tile 415     176,177,178,415,416  
# bash    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc05_dem_variables_float_noMult_equi7_4HyperScaleRoughness.sh
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc05_dem_variables_float_noMult_equi7_4HyperScaleRoughness.sh

# AS_006_042 AS_006_048 AS_006_054 EU_078_006 EU_078_012 file with negative number ...it create problem in the multiscale 

# check for errors 
# ls /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT/{multirough,deviation}/tiles/??_???_???_????_???.tif   | xargs -n 1 -P 10  bash -c $' pkstat -f -nodata -9999 -mm  -i $1    ' _  | grep 32768

# file=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/EU/EU_048_000.tif

file=$(ls /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/equi7/dem/??/??_???_???.tif | head -n $SLURM_ARRAY_TASK_ID | tail -1 )
# use this if one file is missing

MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
SCRATCH=/gpfs/loomis/scratch60/fas/sbsc/ga254/dataproces/MERIT
RAM=/dev/shm
filename=$(basename $file .tif )
CT=${filename:0:2}
echo filename  $filename
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

ulx=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  - (2010 * 100 )) }')
uly=$(gdalinfo $file | grep "Upper Left"  | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  + (2010 * 100 )) }')
lrx=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $3  + (2010 * 100 )) }')
lry=$(gdalinfo $file | grep "Lower Right" | awk '{ gsub ("[(),]"," ") ; printf ("%i" ,  $4  - (2010 * 100 )) }')

echo $ulx $uly $lrx $lry
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin  $ulx $uly $lrx $lry  $MERIT/equi7/dem/${CT}/all_${CT}_tif.vrt  $RAM/$filename.tif 
pksetmask   -m $RAM/$filename.tif   -msknodata -9999 -nodata 0 -i $RAM/$filename.tif -o $RAM/${filename}_0.tif
gdal_edit.py  -a_nodata 0  $RAM/${filename}_0.tif 

# ./whitebox_tools   --toolhelp="MultiscaleRoughness" 
# ./whitebox_tools   --toolhelp="MaxElevationDeviation" 

if [ $filename = "AS_006_042" ] || [ $filename = "AS_006_048" ] || [ $filename = "AS_006_054" ] || [ $filename = "EU_078_012" ] || [ $filename = "EU_078_006" ] ; then 
pksetmask -m  $RAM/${filename}_0.tif  -msknodata  -20  -nodata  -20  -p  "<"  -i $RAM/${filename}_0.tif -o $RAM/${filename}_00.tif
mv $RAM/${filename}_00.tif  $RAM/${filename}_0.tif  
fi

singularity exec /gpfs/home/fas/sbsc/ga254/scripts/MERIT/UbuntuWB.simg  bash <<EOF
/WBT/whitebox_tools  -r=MultiscaleRoughness  -v --wd="$RAM"  --dem=${filename}_0.tif --out_mag=${filename}_rough-magnitude.tif  --out_scale=${filename}_rough-scale.tif --min_scale=1 --max_scale=2000 --step=3
EOF

for PAR in rough-magnitude rough-scale   ; do
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -m $RAM/$filename.tif -nodata -9999 -msknodata -9999 -i $RAM/${filename}_$PAR.tif -o  $RAM/${filename}_${PAR}_msk.tif 

# to mask    #   -32768  of some files 
if [ $filename = "AS_006_042" ] || [ $filename = "AS_006_048" ] || [ $filename = "AS_006_054" ] || [ $filename = "EU_078_012" ] || [ $filename = "EU_078_006" ] ; then 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -m $RAM/${filename}_$PAR.tif -nodata -32768 -msknodata -9999 -i $RAM/${filename}_${PAR}_msk.tif -o  $RAM/${filename}_${PAR}_msk2.tif 
mv  $RAM/${filename}_${PAR}_msk2.tif   $RAM/${filename}_${PAR}_msk.tif 
fi 

rm -f  $RAM/${filename}_${PAR}.tif    
gdal_translate   -projwin $( getCorners4Gtranslate $file  )     -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_${PAR}_msk.tif  $MERIT/${PAR}/tiles/${PAR}_100M_MERIT_${filename}.tif 
rm -f  $RAM/${filename}_${PAR}_msk.tif 
done 

singularity exec /gpfs/home/fas/sbsc/ga254/scripts/MERIT/UbuntuWB.simg  bash <<EOF
/WBT/whitebox_tools -r=MaxElevationDeviation  -v --wd="$RAM"  --dem=${filename}_0.tif --out_mag=${filename}_dev-magnitude.tif --out_scale=${filename}_dev-scale.tif --min_scale=1 --max_scale=2000 --step=3
EOF

for PAR in  dev-magnitude dev-scale   ; do 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  -m $RAM/$filename.tif -nodata -9999 -msknodata -9999 -i  $RAM/${filename}_$PAR.tif -o  $RAM/${filename}_${PAR}_msk.tif 
rm -f  $RAM/${filename}_${PAR}.tif    
gdal_translate   -projwin $( getCorners4Gtranslate $file  )     -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $RAM/${filename}_${PAR}_msk.tif  $MERIT/${PAR}/tiles/${PAR}_100M_MERIT_${filename}.tif 
rm -f  $RAM/${filename}_${PAR}_msk.tif 
done 
