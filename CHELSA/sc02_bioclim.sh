#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_bioclim.sh.%A_%a.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_bioclim.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_bioclim.sh
#SBATCH --array=1-14

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc02_bioclim.sh  

# array from 1 to 14    startin in 2000 ending in 2013

module load Apps/GRASS/7.3-beta

export CHELSA=/project/fas/sbsc/ga254/dataproces/CHELSA
export GRASS=/tmp
export RAM=/dev/shm

# 1979 2013 

# find  /tmp      -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
# find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# SLURM_ARRAY_TASK_ID=1

# BIO 01 Annual mean temperature as the mean of the monthly temperatures (°C)
# BIO 02 Mean diurnal range as the mean of monthly (max temp - min temp) (°C)
# BIO 03 Isothermality (BIO2/BIO7 * 100)
# BIO 04 Temperature Seasonality (standard deviation * 100)
# BIO 05 Max Temperature of Warmest Month (°C)
# BIO 06 Min Temperature of Coldest Month (°C)
# BIO 07 Temperature Annual Range (BIO5 - BIO6) (°C)
# BIO 08 Mean Temperature of Wettest Quarter (°C)
# BIO 09 Mean Temperature of Driest Quarter (°C)
# BIO 10 Mean Temperature of Warmest Quarter (°C)
# BIO 11 Mean Temperature of Coldest Quarter (°C)
# BIO 12 Annual Precipitation (mm)
# BIO 13 Precipitation of Wettest Month (mm)
# BIO 14 Precipitation of Driest Month (mm)
# BIO 15 Precipitation Seasonality (Coefficient of Variation * 100)
# BIO 16 Precipitation of Wettest Quarter (mm)
# BIO 17 Precipitation of Driest Quarter (mm)
# BIO 18 Precipitation of Warmest Quarter (mm)
# BIO 19 Precipitation of Coldest Quarter (mm)

# the value of precipitation is multiplied for 10 
# the value of temperature   is multiplied for 10 

export YEAR=$(expr $SLURM_ARRAY_TASK_ID + 1999  ) 
export YEAR=2000 

echo cp tif data to RAM

echo  tmax tmin prec | xargs -n 1 -P 3 bash -c $' 
VAR=$1
cp /project/fas/sbsc/ga254/dataproces/CHELSA/${VAR}/CHELSA_${VAR}_*_${YEAR}_V1.2.tif $RAM
' _ 

rm -fr $GRASS/loc_$YEAR 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $GRASS loc_$YEAR $RAM/CHELSA_prec_1_${YEAR}_V1.2.tif  r.in.gdal

g.region w=-120 e=-110  n=40 s=30

g.remove -f  type=raster name=CHELSA_prec_1_${YEAR}_V1.2  

for VAR in prec tmin tmax ; do 
export VAR
seq 1 12 | xargs -n 1 -P 6 bash -c $'  
MONTH=$1
r.external   input=$RAM/CHELSA_${VAR}_${MONTH}_${YEAR}_V1.2.tif output=${VAR}_${MONTH}_${YEAR}  --overwrite 

if [ $VAR = "prec"  ] ; then
r.mapcalc " ${VAR}_${MONTH}_${YEAR}f = float(${VAR}_${MONTH}_${YEAR}) / 10.0  " 
fi 

' _
done 

r.mask raster=prec_1_${YEAR}  --o 


for YEARR   in $( seq   1904   4  2196 ) ; do echo $YEARR   29  ; done  > $CHELSA/year${YEAR}_months_day29.txt 
for YEARR   in $( seq   1904   1  2196 ) ; do echo $YEARR   28  ; done  > $CHELSA/year${YEAR}_months_day28.txt 
cat $CHELSA/year${YEAR}_months_day29.txt $CHELSA/year${YEAR}_months_day28.txt | sort -k 1,1 -g | awk -f /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/max.awk >  $CHELSA/year${YEAR}_months_day.txt 

seq 1 12 | xargs -n 1 -P 6 bash -c $'  
MONTH=$1

DD=$(grep $YEAR  $CHELSA/year${YEAR}_months_day.txt  | awk -v MONTH=$MONTH   \'{ print $( MONTH +1 ) }\')  

r.mapcalc "gdd20_$MONTH = if ((( tmin_${MONTH}_${YEAR} + tmax_${MONTH}_${YEAR} ) / 2 ) > 0 , (( tmin_${MONTH}_${YEAR} + tmax_${MONTH}_${YEAR} ) / 2 ) * $DD , 0) " 
r.mapcalc "gdd21_$MONTH = if ((( tmin_${MONTH}_${YEAR} + tmax_${MONTH}_${YEAR} ) / 2 ) > 5 , (( tmin_${MONTH}_${YEAR} + tmax_${MONTH}_${YEAR} ) / 2 ) * $DD , 0) " 

' _ 

r.mapcalc "gdd20 = ( gdd20_1 +  gdd20_2 +  gdd20_3 +  gdd20_4 +  gdd20_5 +  gdd20_6 + gdd20_7 +  gdd20_8 +  gdd20_9 +  gdd20_10 +  gdd20_11 + gdd20_12 )"   
r.mapcalc "gdd21 = ( gdd21_1 +  gdd21_2 +  gdd21_3 +  gdd21_4 +  gdd21_5 +  gdd21_6 + gdd21_7 +  gdd21_8 +  gdd21_9 +  gdd21_10 +  gdd21_11 + gdd21_12 )"   


exit 


seq 1 12 | xargs -n 1 -P 6 bash -c $'  
r.mapcalc "mean$mont  =  tmin_${MONTH}_${YEAR} + tmax_${MONTH}_${YEAR} ) / 2 "   
' _ 

# Mean temperature of the coldest month
r.series input=mean1,mean2,mean3,mean4,mean5,mean6,mean7,mean8,mean9,mean10,mean11,mean12  output=gdd22 method=min_raster 





r.mapcalc "gdd22 =  min (
# Mean temperature of the warmest month
r.mapcalc "gdd23 =  max ( mean1 ,  mean2 +  mean3 +  mean4 +  mean5 +  mean6 + mean7 +  mean8 +  mean9 +  mean10 +  mean11 + mean12 )"   


#  Minimum June July August precipitation
#  Maximum June July August precipitation
#  Minimum December January February precipitation
#  Maximum December January February precipitation
#  Total precipitation for months with a mean monthly temperature is above 0°C 
#  Number of months with a mean temperature > 10°C








/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.bioclim tmin=$(g.list type=rast pat=tmin_*  map=. sep=,) \
                                                           tmax=$(g.list type=rast pat=tmax_*  map=. sep=,) \
                                                           prec=$(g.list type=rast pat=prec_*f map=. sep=,) \
                                                           out=bio_ workers=6 tinscale=1  --overwrite







echo export data 

seq 10 19 | xargs -n 1 -P 6 bash -c $'  
BIO=$1
r.out.gdal --overwrite -c -f   -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=bio_bio${BIO}  output=$CHELSA/bio$BIO/bio${BIO}_${YEAR}.tif 
' _

seq 1  9 | xargs -n 1 -P 6 bash -c $'  
BIO=$1
r.out.gdal --overwrite -c -f   -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=bio_bio0${BIO}   output=$CHELSA/bio$BIO/bio${BIO}_${YEAR}.tif 
' _

# remove all tif 
for VAR in tmax tmin prec ; do 
export VAR
seq 1 12 | xargs -n 1 -P 6 bash -c $'  
MONTH=$1
rm -f $RAM/CHELSA_${VAR}_${MONTH}_${YEAR}_V1.2.tif  
' _
done 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID         --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

# rm -fr $GRASS/loc_$YEAR  $RAM/CHELSA_${VAR}_*_1_${YEAR} 
