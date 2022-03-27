#!/bin/bash
#SBATCH -p scavenge
#SBATCH -J sc02_Nemision_tmean.sh
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_Nemision_tmean.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_Nemision_tmean.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=5000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc02_Nemision_tmean.sh 

export  INDIR=/project/fas/sbsc/sd566/global_wsheds/global_results_merged/filled_str_ord_maximum_max50x_lakes_manual_correction/climate
export OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NP/global_wsheds 

echo  -145 15  -90 60 a >  $OUTDIR/tile.txt
echo   -90 15    0 60 b >> $OUTDIR/tile.txt
echo     0 15   90 60 c >> $OUTDIR/tile.txt
echo    90 15  180 60 d >> $OUTDIR/tile.txt

echo -145 -56  -90 15 e >> $OUTDIR/tile.txt
echo  -90 -56    0 15 f >> $OUTDIR/tile.txt
echo    0 -56   90 15 g >> $OUTDIR/tile.txt
echo   90 -56  180 15 h >> $OUTDIR/tile.txt

cat $OUTDIR/tile.txt   | xargs -n 5  -P 8 bash -c $'  

gdalbuildvrt -separate  -te  $1 $2 $3 $4   -overwrite  ${OUTDIR}/tmax_avg_$5.vrt  ${INDIR}/avg/tmax_*.tif  
gdalbuildvrt -separate  -te  $1 $2 $3 $4   -overwrite  ${OUTDIR}/tmin_avg_$5.vrt  ${INDIR}/avg/tmin_*.tif

gdalbuildvrt -separate  -te  $1 $2 $3 $4   -overwrite  ${OUTDIR}/tmax_wavg_$5.vrt  ${INDIR}/wavg/tmax_*.tif 
gdalbuildvrt -separate  -te  $1 $2 $3 $4   -overwrite  ${OUTDIR}/tmin_wavg_$5.vrt  ${INDIR}/wavg/tmin_*.tif 

pkstatprofile  -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean  -i  ${OUTDIR}/tmax_avg_$5.vrt  -o ${OUTDIR}/tmax_avg_$5.tif 
pkstatprofile  -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean  -i  ${OUTDIR}/tmin_avg_$5.vrt  -o ${OUTDIR}/tmin_avg_$5.tif 
pkstatprofile  -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean  -i  ${OUTDIR}/tmax_wavg_$5.vrt -o ${OUTDIR}/tmax_wavg_$5.tif 
pkstatprofile  -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean  -i  ${OUTDIR}/tmin_wavg_$5.vrt -o ${OUTDIR}/tmin_wavg_$5.tif

' _ 

rm -f $OUTDIR/tile.txt   

gdalbuildvrt  ${OUTDIR}/tmax_avg.vrt  ${OUTDIR}/tmax_avg_?.tif -overwrite
gdalbuildvrt  ${OUTDIR}/tmin_avg.vrt  ${OUTDIR}/tmin_avg_?.tif -overwrite
gdalbuildvrt  ${OUTDIR}/tmax_wavg.vrt ${OUTDIR}/tmax_wavg_?.tif -overwrite
gdalbuildvrt  ${OUTDIR}/tmin_wavg.vrt ${OUTDIR}/tmin_wavg_?.tif -overwrite

gdal_translate --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9 ${OUTDIR}/tmax_avg.vrt  ${OUTDIR}/tmax_avg.tif 
gdal_translate --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9 ${OUTDIR}/tmin_avg.vrt  ${OUTDIR}/tmin_avg.tif 

gdal_translate --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9 ${OUTDIR}/tmax_wavg.vrt  ${OUTDIR}/tmax_wavg.tif 
gdal_translate --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9 ${OUTDIR}/tmin_wavg.vrt  ${OUTDIR}/tmin_wavg.tif 

gdalbuildvrt -separate  ${OUTDIR}/tmean_avg.vrt   ${OUTDIR}/tmax_avg.tif   ${OUTDIR}/tmin_avg.tif    -overwrite
gdalbuildvrt -separate  ${OUTDIR}/tmean_wavg.vrt  ${OUTDIR}/tmax_wavg.tif  ${OUTDIR}/tmin_wavg.tif   -overwrite

pkstatprofile -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean -i  ${OUTDIR}/tmean_avg.vrt -o   ${OUTDIR}/tmean_avg.tif
pkstatprofile -of GTiff -co  COMPRESS=LZW -nodata -9999 -f mean -i  ${OUTDIR}/tmean_wavg.vrt -o   ${OUTDIR}/tmean_wavg.tif

rm  ${OUTDIR}/*.vrt ${OUTDIR}/tmax_avg_?.tif ${OUTDIR}/tmax_wavg_?.tif ${OUTDIR}/tmin_avg_?.tif ${OUTDIR}/tmin_wavg_?.tif
