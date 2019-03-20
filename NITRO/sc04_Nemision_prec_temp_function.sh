#!/bin/bash
#SBATCH -p day
#SBATCH -J sc04_Nemision_prec_temp_function.sh
#SBATCH -n 1 -c 12  -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_Nemision_prec_temp_function.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_Nemision_prec_temp_function.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=5000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc04_Nemision_prec_temp_function.sh

export  INDIR=/project/fas/sbsc/ga254/dataproces/STREAMVAR1K/nc 
export  OUTDIR=/project/fas/sbsc/ga254/dataproces/STREAMVAR1K/tif_from_nc
export  RAM=/dev/shm 

module load Libs/GDAL/2.2.4  


echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs -n 1 -P 12 bash -c $' 
MM=$1
band=$(expr $MM  \*  1) 
gdal_translate --config GDAL_CACHEMAX 4000 -ot Int32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -b $band   $INDIR/monthly_prec_sum.nc      $OUTDIR/monthly${MM}_prec_sum.tif 
' _ 

echo  1 2  | xargs -n 1 -P 2 bash -c $' 
MM=$1
band=$(expr $MM  \*  1)
gdal_translate --config GDAL_CACHEMAX 8000 -ot Int32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -b $band   $INDIR/flow_acc.nc     $OUTDIR/flow_acc_${MM}.tif 
' _ 

mv   $OUTDIR/flow_acc_2.tif     $OUTDIR/flow_acc_fa.tif  # flow accumulation  
mv   $OUTDIR/flow_acc_1.tif     $OUTDIR/flow_acc_sl.tif  # stream length 


module load Libs/GDAL/1.11.2  
pkstatprofile   -f mean -i $OUTDIR/monthly??_prec_sum.tif   -o     $OUTDIR/monthly_prec_sum_mean_tmp.tif  
gdal_translate --config GDAL_CACHEMAX 8000 -ot Int32 -a_nodata -9999   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $OUTDIR/monthly_prec_sum_mean_tmp.tif $OUTDIR/monthly_prec_sum_mean.tif 


pkgetmask -ot Byte   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   -min -1 -max 9999999999999 -data 1 -nodata 0 -i   $OUTDIR/flow_acc_fa.tif -o     $OUTDIR/stream_0_1.tif 
gdalbuildvrt -separate   -overwrite  -srcnodata -9999  -vrtnodata -9999   $OUTDIR/mean_flow_acc_${MM}.vrt  $OUTDIR/monthly_prec_sum_mean.tif   $OUTDIR/flow_acc_fa.tif 

oft-calc -ot Int16  -um    $OUTDIR/stream_0_1.tif      $OUTDIR/mean_flow_acc_${MM}.vrt      $OUTDIR/monthly_prec_mean_tmp.tif  <<EOF
1
#1 #2 /
EOF

pksetmask -m    $OUTDIR/stream_0_1.tif  -msknodata 0 -nodata -1  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Int16 -i   $OUTDIR/monthly_prec_mean_tmp.tif -o  $OUTDIR/monthly_prec_mean.tif
rm -f  $OUTDIR/monthly_prec_mean_tmp.tif  $OUTDIR/mean_flow_acc_${MM}.vrt

