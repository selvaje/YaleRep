#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 10  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_hysdrosheds_legthgrwl_aggregation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_hysdrosheds_legthgrwl_aggregation.sh.%J.err
#SBATCH --job-name=sc09_hysdrosheds_legthgrwl_aggregation.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc09_hysdrosheds_legthgrwl_aggregation.sh

export INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_vector_to_rast
export OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO
export RAM=/dev/shm

# # aggregate at 1km
ls  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GRWL/GRWL_vector_to_rast/*.tif  | xargs -n 1  -P 10 bash -c $'
file=$1 
filename=$(basename $file .tif )
echo $1 
rm -f  $RAM/${filename}_msk.tif  $RAM/$filename.tif   
pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -nodata 0  -data 1  -min -1 -max 99999999 -i $file -o $RAM/${filename}_msk.tif 
pkfilter   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Int16  -of GTiff -dx 30 -dy 30 -f sum -d 30 -i $RAM/${filename}_msk.tif    -o $RAM/${filename}.tif 
gdal_edit.py -a_nodata  0 $RAM/$filename.tif   
rm -f  $RAM/${filename}_msk.tif 
'  _ 



gdalbuildvrt   -overwrite -srcnodata  0   -vrtnodata 0  $RAM/all_tif.vrt $RAM/????.tif  
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9     -a_nodata 0  -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/all_tif.vrt    $OUTDIR/GRWL/grwl_pixnum_1km.tif 

rm $RAM/????.tif   


exit 

pkstat --hist -i   /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/grwl_pixnum_1km.tif | grep -v " 0" > grwl_pixnum_1km_hist.tif 

awk '{  if ($1>=31) { sum=sum+( $1*$2 ) ; sumP=sumP+( $2 )  }  } END { print 100 / 30 / ( ( sum/sumP ) - 30)  } ' grwl_pixnum_1km_hist.txt 
