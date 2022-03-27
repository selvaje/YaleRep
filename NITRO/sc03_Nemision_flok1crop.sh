#!/bin/bash
#SBATCH -p day
#SBATCH -J sc03_Nemision_flok1crop.sh
#SBATCH -n 1 -c 3 -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_Nemision_flok1crop.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_Nemision_flok1crop.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=20000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc03_Nemision_flok1crop.sh

export  INDIR=/project/fas/sbsc/ga254/dataproces/FLO1K
export  OUTDIR=/project/fas/sbsc/ga254/dataproces/NP
export  RAM=/tmp

rm -rf $RAM/*.tif  $INDIR/grassdb/loc_${filename}

echo FLO1K.ts.1960.2015.qma_max_msk.tif FLO1K.ts.1960.2015.qmi_min_msk.tif FLO1K.ts.1960.2015.qav_mean_msk.tif | xargs -P 3 -n 1 bash -c $' 

file=$1 
if [ $file = "FLO1K.ts.1960.2015.qma_max.tif" ] ; then 
filename=$(basename $file _msk.tif)
else 
filename=$(basename $file _cor.tif)
fi

gdal_translate --config GDAL_CACHEMAX 5000    -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_srs EPSG:4326 -projwin $(getCorners4Gtranslate $OUTDIR/global_wsheds/global_grid_ID.tif ) $INDIR/$file  $RAM/crop_$file 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $OUTDIR/global_prediction/map_pred_NO3_mask.tif   -msknodata -1   -nodata -9999 -i $RAM/crop_$file  -o  $OUTDIR/FLO1K/${filename}_msk.tif 

pkgetmask  -ot Byte  -min -2 -max -0.5  -co COMPRESS=DEFLATE -co ZLEVEL=9    -data 0 -nodata 1  -i   $RAM/crop_$file   -o   $RAM/msk_$file  
pkfillnodata  -m   $RAM/msk_$file  -d 10    -i $RAM/crop_$file -o $RAM/${filename}_fill1.tif 

for n in $(seq 2 8) ; do 
prvn=$(expr $n - 1 )
pkgetmask  -ot Byte  -min -2 -max -0.5  -co COMPRESS=DEFLATE -co ZLEVEL=9    -data 0 -nodata 1  -i $RAM/${filename}_fill$prvn.tif   -o $RAM/${filename}_mask$prvn.tif 
pkfillnodata -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES -m $RAM/${filename}_mask$prvn.tif -d 10 -i $RAM/${filename}_fill$prvn.tif -o $RAM/${filename}_fill$n.tif
rm $RAM/${filename}_fill$prvn.tif
done 

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  $RAM/${filename}_fill$n.tif  $OUTDIR/FLO1K/${filename}_fill.tif 

rm -f $RAM/crop_$file $RAM/msk_$file   
' _ 


# force the mean to be less than the max 
# gdal_calc.py --NoDataValue=-1 --overwrite --co=COMPRESS=DEFLATE --co=ZLEVEL=9 -A $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qma_max_fill.tif  -B $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill.tif  --calc="A*(B>A)+B*(B<A)"  --NoDataValue=-1  --overwrite  --outfile=$OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill_cor1.tif 

# gdal_calc.py --NoDataValue=-1 --overwrite --co=COMPRESS=DEFLATE --co=ZLEVEL=9 -A $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qma_max_fill.tif  -B $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill_cor1.tif -C $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qmi_min_fill.tif --calc="((A+C)/2)*logical_and(B==0,C<A)+(A/2)*logical_and(B==0,C>A)+B*(B>0)" --NoDataValue=-1 --overwrite --outfile=$OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill_cor.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $OUTDIR/global_prediction/map_pred_NO3_mask.tif   -msknodata -1   -nodata -9999 -i $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qmi_min_fill.tif      -o $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qmi_min_fill_msk.tif &
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $OUTDIR/global_prediction/map_pred_NO3_mask.tif   -msknodata -1   -nodata -9999 -i $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill.tif -o $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qav_mean_fill_msk.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $OUTDIR/global_prediction/map_pred_NO3_mask.tif   -msknodata -1   -nodata -9999 -i $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qma_max_fill.tif      -o $OUTDIR/FLO1K/FLO1K.ts.1960.2015.qma_max_fill_msk.tif

sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc05_Nemision_table.sh 

exit 

