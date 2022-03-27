#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_SumSaturation.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_SumSaturation.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_SumSaturation.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/SoilGrids/sc02_SumSaturation.sh

export DIR=/project/fas/sbsc/ga254/dataproces/SoilGrids/AWC
export RAM=/dev/shm

# Upper Left  (-180.0000000,  84.0000000) (180d 0' 0.00"W, 84d 0' 0.00"N)
# Lower Left  (-180.0000000, -56.0000000) (180d 0' 0.00"W, 56d 0' 0.00"S)
# Upper Right ( 180.0000000,  84.0000000) (180d 0' 0.00"E, 84d 0' 0.00"N)
# Lower Right ( 180.0000000, -56.0000000) (180d 0' 0.00"E, 56d 0' 0.00"S)

#    xmin ymin xmax ymax 

echo -180 10  -90 84 a >  $DIR/tile.txt
echo  -90 10    0 84 b >> $DIR/tile.txt
echo    0 10   90 84 c >> $DIR/tile.txt
echo   90 10  180 84 d >> $DIR/tile.txt

echo -180 -56  -90 10 e >> $DIR/tile.txt
echo  -90 -56    0 10 f >> $DIR/tile.txt
echo    0 -56   90 10 g >> $DIR/tile.txt
echo   90 -56  180 10 h >> $DIR/tile.txt

# AWCts = Saturated water content
# sl1 to sl7 are different depths in 0,5,15,30,60,100,200cm and need to be summed to obtain one grid with the total saturated water content from 0 to 2m. Information how to sum up is given here on p.3:
# http://gsif.isric.org/lib/exe/fetch.php?media=wiki:soilgrids250m_global_gridded_preprint.pdf


cat   $DIR/tile.txt | xargs -n 5  -P 8 bash -c $' 

for file in $DIR/*.tif ; do 
filename=$(basename $file .tif   )
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $1 $4 $3 $2   $file $RAM/${filename}_$5.tif
done 

gdal_calc.py -A $RAM/AWCtS_M_sl1_250m_$5.tif   -B $RAM/AWCtS_M_sl2_250m_$5.tif  -C $RAM/AWCtS_M_sl3_250m_$5.tif   -D $RAM/AWCtS_M_sl4_250m_$5.tif \
             -E $RAM/AWCtS_M_sl5_250m_$5.tif   -F $RAM/AWCtS_M_sl6_250m_$5.tif  -G $RAM/AWCtS_M_sl7_250m_$5.tif --format=GTiff   --outfile=$DIR/../AWC_sum/AWCtS_M_slsum_250m_$5.tif \
             --co=COMPRESS=DEFLATE --co=ZLEVEL=9  --co=BIGTIFF=YES    --overwrite --NoDataValue=65535   --type=UInt16   \
             --calc="(       (( 5     *  ((A.astype(float) + B.astype(float)) / 2.0) ) + \
                              (10     *  ((B.astype(float) + C.astype(float)) / 2.0) ) + \
                              (15     *  ((C.astype(float) + D.astype(float)) / 2.0) ) + \
                              (30     *  ((D.astype(float) + E.astype(float)) / 2.0) ) + \
                              (40     *  ((E.astype(float) + F.astype(float)) / 2.0) ) + \
                              (100    *  ((F.astype(float) + G.astype(float)) / 2.0) ))  )"

rm $DIR/AWCtS_M_sl*_250m_$5.vrt
' _ 

gdalbuildvrt  -overwrite    $DIR/../AWC_sum/AWCtS_M_slsum_250m.vrt   $DIR/../AWC_sum/AWCtS_M_slsum_250m_{a,b,c,d,e,f,g,h}.tif 
gdal_translate  -co BIGTIFF=YES   -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/../AWC_sum/AWCtS_M_slsum_250m.vrt  $DIR/../AWC_sum/AWCtS_M_slsum_250m_BIG.tif

echo -180 84   0  10 A >  $DIR/tile.txt 
echo -180 10   0 -56 B >>  $DIR/tile.txt 
echo    0 84 180  10 C >>  $DIR/tile.txt 
echo    0 10 180 -56 D >>  $DIR/tile.txt 

cat   $DIR/tile.txt | xargs -n 5  -P 4 bash -c $' 

gdal_translate -projwin $1 $2 $3 $4 -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/../AWC_sum/AWCtS_M_slsum_250m_BIG.tif $DIR/../AWC_sum/AWCtS_M_slsum_250m_tile$5.tif

' _ 

rm $DIR/tile.txt 

# rm  $DIR/../AWC_sum/AWCtS_M_slsum_250m.vrt  $DIR/AWCtS_M_sl?_250m_?.vrt   $DIR/../AWC_sum/AWCtS_M_slsum_250m_{a,b,c,d,e,f,g,h}.tif  $DIR/tile.txt 
