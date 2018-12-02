#!/bin/bash
#SBATCH -p day
#SBATCH -J sc01_Nemision_cdo.sh
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_Nemision_cdo.sh.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_Nemision_cdo.sh.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=5000

# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/NP/sc01_Nemision_cdo.sh

module load Tools/CDO/1.7.2
export DIR=/project/fas/sbsc/ga254/dataproces/FLO1K

# script piu lungo di 24 ore ..
# cdo -z zip_9  -P 8 timmax   $DIR/FLO1K.ts.1960.2015.qma.nc   $DIR/FLO1K.ts.1960.2015.qma_maxCDO.nc
# cdo -z zip_9  -P 8 timavg  $DIR/FLO1K.ts.1960.2015.qav.nc   $DIR/FLO1K.ts.1960.2015.qav_meanCDO.nc
# cdo -z zip_9  -P 8 timmin   $DIR/FLO1K.ts.1960.2015.qmi.nc   $DIR/FLO1K.ts.1960.2015.qmi_minCDO.nc

# cdo -z zip_9  -P 8  invertlat    $DIR/FLO1K.ts.1960.2015.qav.nc    $DIR/FLO1K.ts.1960.2015.qav_invertlatlong.nc 
# cdo -z zip_9  -P 8  invertlat    $DIR/FLO1K.ts.1960.2015.qma.nc    $DIR/FLO1K.ts.1960.2015.qma_invertlatlong.nc 
# cdo -z zip_9  -P 8  invertlat    $DIR/FLO1K.ts.1960.2015.qmi.nc    $DIR/FLO1K.ts.1960.2015.qmi_invertlatlong.nc 

# cdo -z zip_9  -P 1  invertlat    $DIR/FLO1K.ts.1960.2015.qav_meanCDO.nc   $DIR/FLO1K.ts.1960.2015.qav_meanCDO_invertlat.nc 
# cdo -z zip_9  -P 1  invertlat    $DIR/FLO1K.ts.1960.2015.qma_maxCDO.nc    $DIR/FLO1K.ts.1960.2015.qma_maxCDO_invertlat.nc  
# cdo -z zip_9  -P 1  invertlat    $DIR/FLO1K.ts.1960.2015.qmi_minCDO.nc    $DIR/FLO1K.ts.1960.2015.qmi_minCDO_invertlat.nc



# export GDAL_NETCDF_BOTTOMUP=NO 

# gdal_translate -a_srs   EPSG:4326  --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/FLO1K.ts.1960.2015.qav_meanCDO_invertlat.nc  $DIR/FLO1K.ts.1960.2015.qav_mean.tif  
# gdal_translate -a_srs   EPSG:4326  --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/FLO1K.ts.1960.2015.qma_maxCDO_invertlat.nc   $DIR/FLO1K.ts.1960.2015.qma_max.tif  
# gdal_translate -a_srs   EPSG:4326  --config GDAL_CACHEMAX 30000  -co NUM_THREADS=8  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/FLO1K.ts.1960.2015.qmi_minCDO_invertlat.nc   $DIR/FLO1K.ts.1960.2015.qmi_min.tif  

# pkgetmask -ot Byte -min -2 -max -0.5 --config GDAL_CACHEMAX 5000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -data 1 -nodata 0 -i $DIR/FLO1K.ts.1960.2015.qav_mean.tif -o $DIR/FLO1K.ts.1960.2015.qav_mean_bin.tif &

# pkgetmask -ot Byte -min -2 -max -0.5 --config GDAL_CACHEMAX 5000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -data 1 -nodata 0 -i $DIR/FLO1K.ts.1960.2015.qma_max.tif -o $DIR/FLO1K.ts.1960.2015.qma_max_bin.tif
 
# pkgetmask -ot Byte -min -2 -max -0.5 --config GDAL_CACHEMAX 5000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -data 1 -nodata 0 -i $DIR/FLO1K.ts.1960.2015.qmi_min.tif  -o $DIR/FLO1K.ts.1960.2015.qmi_min_bin.tif  

# gdal_edit.py -a_nodata -1   $DIR/FLO1K.ts.1960.2015.qma_max_bin.tif ; gdal_edit.py -a_nodata -1   $DIR/FLO1K.ts.1960.2015.qav_mean_bin.tif 
# gdal_edit.py -a_nodata -1   $DIR/FLO1K.ts.1960.2015.qmi_min_bin.tif

#### pkstat --hist -i FLO1K.ts.1960.2015.qma_max_bin.tif  ; 0 212665896   , 1 720454104
#### pkstat --hist -i FLO1K.ts.1960.2015.qmi_min_bin.tif  ; 0 212665896   , 1 720454104
#### pkstat --hist -i FLO1K.ts.1960.2015.qav_mean_bin.tif ; 0 206471277   , 1 726648723  ; there are more pixel labeled as -1 

# gdal_calc.py --overwrite --co=COMPRESS=DEFLATE --co=ZLEVEL=9 -A $DIR/FLO1K.ts.1960.2015.qma_max_bin.tif -B $DIR/FLO1K.ts.1960.2015.qav_mean_bin.tif \
#  -C $DIR/FLO1K.ts.1960.2015.qmi_min_bin.tif  --calc="(A+B+C)" --outfile=$DIR/FLO1K.ts.1960.2015.q_bin_msk.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/FLO1K.ts.1960.2015.q_bin_msk.tif -msknodata 0.5 --operator='>'  -nodata -1 -i $DIR/FLO1K.ts.1960.2015.qav_mean.tif -o $DIR/FLO1K.ts.1960.2015.qav_mean_msk.tif &
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/FLO1K.ts.1960.2015.q_bin_msk.tif -msknodata 0.5 --operator='>'  -nodata -1 -i $DIR/FLO1K.ts.1960.2015.qma_max.tif  -o $DIR/FLO1K.ts.1960.2015.qma_max_msk.tif
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/FLO1K.ts.1960.2015.q_bin_msk.tif -msknodata 0.5 --operator='>'  -nodata -1 -i $DIR/FLO1K.ts.1960.2015.qmi_min.tif  -o $DIR/FLO1K.ts.1960.2015.qmi_min_msk.tif

exit 

# correction non piu implementata. 

# rm  $DIR/FLO1K.ts.1960.2015.qav_meanCDO_invertlat.nc $DIR/FLO1K.ts.1960.2015.qma_maxCDO_invertlat.nc  $DIR/FLO1K.ts.1960.2015.qmi_minCDO_invertlat.nc 

# correct the average for value very small value 

gdal_calc.py -A $DIR/FLO1K.ts.1960.2015.qma_max_msk.tif -B $DIR/FLO1K.ts.1960.2015.qmi_min_msk.tif --outfile=$DIR/FLO1K.ts.1960.2015.qmi_min_cor.tif   --calc="A*(B>A)+B*(B<A)"  --NoDataValue=-1  --overwrite  --co=COMPRESS=DEFLATE --co=ZLEVEL=9  &

gdal_calc.py -A $DIR/FLO1K.ts.1960.2015.qma_max_msk.tif -B $DIR/FLO1K.ts.1960.2015.qav_mean_msk.tif \
--outfile=$DIR/FLO1K.ts.1960.2015.qav_mean_cor1.tif --calc="A*(B>A)+B*(B<A)"  --NoDataValue=-1  --overwrite  --co=COMPRESS=DEFLATE --co=ZLEVEL=9 

gdal_calc.py -A $DIR/FLO1K.ts.1960.2015.qma_max_msk.tif -B $DIR/FLO1K.ts.1960.2015.qav_mean_cor1.tif --outfile=$DIR/FLO1K.ts.1960.2015.qav_mean_cor.tif \
                                           --calc="A*(B==0)+B*(B>0)"  --NoDataValue=-1  --overwrite  --co=COMPRESS=DEFLATE --co=ZLEVEL=9 

sbatch /gpfs/home/fas/sbsc/ga254/scripts/NP/sc03_Nemision_flok1crop.sh

exit 
