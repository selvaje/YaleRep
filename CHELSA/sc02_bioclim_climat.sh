#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_bioclim_climat.sh.%A_%a.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_bioclim_climat.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_bioclim_climat.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/CHELSA/sc02_bioclim_climat.sh  



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

echo cp tif data to RAM

echo  tmax tmin prec | xargs -n 1 -P 3 bash -c $' 
VAR=$1
cp /project/fas/sbsc/ga254/dataproces/CHELSA/${VAR}_clim/CHELSA_${VAR}_*_V1.2.tif $RAM
' _ 


rm -fr $GRASS/loc_clim
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $GRASS loc_clim $RAM/CHELSA_prec_1_V1.2.tif  r.in.gdal

g.region w=-120 e=-80  n=50 s=20 

g.remove -f  type=raster name=CHELSA_prec_1_V1.2  

for VAR in tmax tmin prec ; do 
export VAR
seq 1 12 | xargs -n 1 -P 6 bash -c $'  
MONTH=$1
r.external   input=$RAM/CHELSA_${VAR}_${MONTH}_V1.2.tif output=${VAR}_${MONTH}  --overwrite 
### r.mapcalc " ${VAR}_${MONTH}_${YEAR}f = float(${VAR}_${MONTH}_${YEAR}) "
' _
done 

r.mask raster=prec_1    --o 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/scripts/r.bioclim tmin=$(g.list type=rast pat=tmin_* map=. sep=,) \
                                                           tmax=$(g.list type=rast pat=tmax_* map=. sep=,) \
                                                           prec=$(g.list type=rast pat=prec_* map=. sep=,) \
                                                           out=bio_ workers=6 tinscale=10 --overwrite

echo export data 

seq 10 19 | xargs -n 1 -P 6 bash -c $'  
BIO=$1
r.out.gdal --overwrite -c -f   -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=bio_bio${BIO}  output=$CHELSA/bio$BIO/bio${BIO}.tif 
' _

seq 1  9 | xargs -n 1 -P 6 bash -c $'  
BIO=$1
r.out.gdal --overwrite -c -f -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32 format=GTiff nodata=-9999  input=bio_bio0${BIO}   output=$CHELSA/bio$BIO/bio${BIO}.tif 
' _

# remove all tif 
for VAR in tmax tmin prec ; do 
export VAR
seq 1 12 | xargs -n 1 -P 6 bash -c $'  
MONTH=$1
rm -f $RAM/CHELSA_${VAR}_${MONTH}_V1.2.tif  
' _
done 



echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

# rm -fr $GRASS/loc_$YEAR  $RAM/CHELSA_${VAR}_*_1_${YEAR} 
