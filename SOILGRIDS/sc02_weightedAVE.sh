#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 11 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_weightedAVE.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_weightedAVE.sh.%J.err
#SBATCH --job-name=sc02_weightedAVE.sh
#SBATCH --mem-per-cpu=15000M
#SBATCH --array=1-10

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc02_weightedAVE.sh

# AWCtS is eft out because it's been done
# for VAR in SLTPPT CLYPPT SNDPPT WWP TEXMHT PHIHOX ORCDRC BLDFIE CECSOL CRFVOL;do   echo $VAR >> /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/variableNames.txt; done

module purge
source ~/bin/gdal

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/
export OUT=/dev/shm

export FOLD=$(cat $DIR/variableNames.txt | head -n $SLURM_ARRAY_TASK_ID | tail -n 1)

for file in $DIR/$FOLD/*.tif ; do
filename=$(basename $file .tif )
echo $filename >> $DIR/${FOLD}_nombres.txt
done

mkdir $DIR/${FOLD}_WeAv

#    xmin ymin xmax ymax
# echo -180 10  -90 84 a >  tile.txt
# echo  -90 10    0 84 b >> tile.txt
# echo    0 10   90 84 c >> tile.txt
# echo   90 10  180 84 d >> tile.txt
#
# echo -180 -56  -90 10 e >> tile.txt
# echo  -90 -56    0 10 f >> tile.txt
# echo    0 -56   90 10 g >> tile.txt
# echo   90 -56  180 10 h >> tile.txt

cat  $DIR/tile.txt | xargs -n 5 -P 8 bash -c $'

for file in $DIR/$FOLD/*.tif ; do
filename=$(basename $file .tif )
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $1 $4 $3 $2   $file $OUT/${filename}_$5.tif
done
' _

export DEP1=$(cat $DIR/${FOLD}_nombres.txt | head -n1 | tail -n1)
export DEP2=$(cat $DIR/${FOLD}_nombres.txt | head -n2 | tail -n1)
export DEP3=$(cat $DIR/${FOLD}_nombres.txt | head -n3 | tail -n1)
export DEP4=$(cat $DIR/${FOLD}_nombres.txt | head -n4 | tail -n1)
export DEP5=$(cat $DIR/${FOLD}_nombres.txt | head -n5 | tail -n1)
export DEP6=$(cat $DIR/${FOLD}_nombres.txt | head -n6 | tail -n1)
export DEP7=$(cat $DIR/${FOLD}_nombres.txt | head -n7 | tail -n1)

cat  $DIR/tile.txt | xargs -n 5 -P 8 bash -c $'

##  sl1 = 0.00 m
##  sl2 = 0.05 m
##  sl3 = 0.15 m
##  sl4 = 0.30 m
##  sl5 = 0.60 m
##  sl6 = 1.00 m
##  sl7 = 2.00 m

gdal_calc.py -A $OUT/${DEP1}_$5.tif   -B $OUT/${DEP2}_$5.tif  -C $OUT/${DEP3}_$5.tif   -D $OUT/${DEP4}_$5.tif -E $OUT/${DEP5}_$5.tif   -F $OUT/${DEP6}_$5.tif  -G $OUT/${DEP7}_$5.tif  --format=GTiff   --outfile=$DIR/${FOLD}_WeAv/${FOLD}_WeAv_$5.tif  --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=BIGTIFF=YES    --overwrite --NoDataValue=65535   --type=UInt16   \
           --calc="(       (( 5     *  (A.astype(float) + B.astype(float)) ) + \
                            (10     *  (B.astype(float) + C.astype(float)) ) + \
                            (15     *  (C.astype(float) + D.astype(float)) ) + \
                            (30     *  (D.astype(float) + E.astype(float)) ) + \
                            (40     *  (E.astype(float) + F.astype(float)) ) + \
                            (100    *  (F.astype(float) + G.astype(float)) ))
                            / 400												  )"
' _

gdalbuildvrt  -overwrite   $DIR/${FOLD}_WeAv/${FOLD}_WeAv.vrt  $DIR/${FOLD}_WeAv/${FOLD}_WeAv_{a,b,c,d,e,f,g,h}.tif

gdal_translate  -co BIGTIFF=YES   -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/${FOLD}_WeAv/${FOLD}_WeAv.vrt $DIR/${FOLD}_WeAv/${FOLD}_WeigAver.tif

#rm $DIR/${FOLD}_WeAv/${FOLD}_WeAv_{a,b,c,d,e,f,g,h}.tif
rm $DIR/${FOLD}_WeAv/${FOLD}_WeAv.vrt
#rm $OUT/*.tif
#rm $DIR/*nombres.txt
exit

rm *_nombres.txt
rm soil_var_names.txt tile.txt variableNames.txt

for VAR in AWCtS SLTPPT CLYPPT SNDPPT WWP TEXMHT PHIHOX ORCDRC BLDFIE CECSOL CRFVOL; do
rm -rf $DIR/${VAR}_WeAv/*_WeAv*
done

scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/GLOWABIO/DataPreparation/SOILGRIDS/sc02_weightedAVE.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/
