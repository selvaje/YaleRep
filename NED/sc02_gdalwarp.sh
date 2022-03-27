#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 1:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_gdalwarp.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_gdalwarp.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_gdalwarp.sh 
#SBATCH --array=1-347
#SBATCH --mem-per-cpu=5000

# 347 
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NED/sc02_gdalwarp.sh 

NEDS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/NED/tif
NEDP=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED/input_tif

RAM=/dev/shm

file=$(ls /project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n??w???_dem.tif | head  -n  $SLURM_ARRAY_TASK_ID | tail  -1 )
# file=/project/fas/sbsc/ga254/dataproces/MERIT/input_tif/n30w125_dem.tif

filename=$(basename $file _dem.tif  )

echo filename  $filename 
echo file $filename.tif  SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID 

res=bilinear

gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -te $(getCorners4Gwarp $file  ) -tr 0.000833333333333 0.000833333333333   -overwrite -t_srs EPSG:4326 -s_srs EPSG:4269  -srcnodata -3.4028234663852886e+38   -dstnodata -9999 -r ${res} -wm 5000  $NEDS/all_tif.vrt   $NEDP/${filename}_${res}.tif  
max=$(pkinfo -max -i   $NEDP/${filename}_${res}.tif    | awk '{ print $2   }')
if [ $max = "-9999"  ] ; then 
rm -f   $NEDP/${filename}_${res}.tif 
else 
# mask base on the merit data and base on the NED data for very large negative values 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -m $file -msknodata -9999 -nodata -9999 -i  $NEDP/${filename}_${res}.tif  -o  $NEDP/${filename}.tif  
rm -f   $NEDP/${filename}_${res}.tif  
fi

exit 


# to select the best interpolation  results .... bilinear 

for res in bilinear cubic cubicspline lanczos average mode ; do 
 
gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -te $(getCorners4Gwarp $file  ) -tr 0.000833333333333 0.000833333333333   -overwrite -t_srs EPSG:4326 -s_srs EPSG:4269  -srcnodata -3.4028234663852886e+38   -dstnodata -9999 -r ${res} -wm 5000  $NEDS/all_tif.vrt   $NEDP/${filename}_${res}.tif  

max=$(pkinfo -max -i   $NEDP/${filename}_${res}.tif    | awk '{ print $2   }')

if [ $max -eq -9999  ] ; then 
rm   $NEDP/${filename}_${res}.tif 
exit 
else 
 
gdal_calc.py  --NoDataValue=-9999 --co=COMPRESS=LZW --co=ZLEVEL=9  --co=INTERLEAVE=BAND -A $NEDP/${filename}_${res}.tif -B $file  --calc="((A.astype(float) -  B.astype(float))**2)" --outfile  $NEDP/${filename}_${res}_dif.tif  --overwrite --type=Float32

pkinfo -nodata -9999   -stats  -i  $NEDP/${filename}_${res}_dif.tif > $NEDP/${filename}_${res}_dif.txt
rm $NEDP/${filename}_${res}_dif.tif.aux.xml
fi 

done 


# paste <(cat *_average_dif.txt | awk '{ print $6  }'  ) <(cat *_bilinear_dif.txt | awk '{ print $6  }'  ) | awk '{  print $1 - $2  }' 

