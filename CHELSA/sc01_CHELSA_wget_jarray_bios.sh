#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 00:30:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_CHELSA_wget_jarray_bios.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_CHELSA_wget_jarray_bios.sh.%A_%a.err
#SBATCH --mem-per-cpu=8000M
#SBATCH --array=1-630%10

###############  1-630

module purge
source ~/bin/gdal

####  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/CHELSA/sc01_CHELSA_wget_jarray_bios.sh  
  
#### Create folders to store variables
#### cd /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/
#### mkdir bio01 bio03 bio04 bio05 bio06 bio07 bio08 bio09 bio10 bio11 bio12 bio13 bio14 bio15 bio16 bio17 bio18 bio19

#### Create file with the task array
#### for VAR in bio01 bio03 bio04 bio05 bio06 bio07 bio08 bio09 bio10 bio11 bio12 bio13 bio14 bio15 bio16 bio17 bio18 bio19 ; do for YEAR in {1979..2013} ; do echo ${VAR} ${YEAR} ; done ; done  > /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_bios_list.txt

####   VARIABLES
# # Check here for more details: http://chelsa-climate.org/wp-admin/download-page/CHELSA_tech_specification.pdf

# # BIO 01 Annual mean temperature as the mean of the monthly temperatures (°C)

# # BIO 03 Isothermality (BIO2/BIO7 * 100)
# # BIO 04 Temperature Seasonality (standard deviation * 100)
# # BIO 05 Max Temperature of Warmest Month (°C)
# # BIO 06 Min Temperature of Coldest Month (°C)
# # BIO 07 Temperature Annual Range (BIO5 - BIO6) (°C)
# # BIO 08 Mean Temperature of Wettest Quarter (°C)
# # BIO 09 Mean Temperature of Driest Quarter (°C)
# # BIO 10 Mean Temperature of Warmest Quarter (°C)
# # BIO 11 Mean Temperature of Coldest Quarter (°C)
# # BIO 12 Annual Precipitation (mm)
# # BIO 13 Precipitation of Wettest Month (mm)
# # BIO 14 Precipitation of Driest Month (mm)
# # BIO 15 Precipitation Seasonality (Coefficient of Variation * 100)
# # BIO 16 Precipitation of Wettest Quarter (mm)
# # BIO 17 Precipitation of Driest Quarter (mm)
# # BIO 18 Precipitation of Warmest Quarter (mm)
# # BIO 19 Precipitation of Coldest Quarter (mm)

   
LINE=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_bios_list.txt   | head -n $SLURM_ARRAY_TASK_ID | tail -1 )

VAR=$(echo $LINE | awk '{ print $1 }' )
YEAR=$(echo $LINE | awk '{ print $2 }' )

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA 
cd $INDIR/$VAR


  ## These variables come as floating Float32 with -99999 as NO-DATA
if [ $VAR = "bio01" ] || [ $VAR = "bio04" ] || [ $VAR = "bio03" ] || [ $VAR = "bio15" ] ; then

    wget https://www.wsl.ch/lud/chelsa/data/timeseries/bio/CHELSA_${VAR}_${YEAR}_V1.2.1.tif
    
    ## Fix properties, compress and repair
    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata -99999   -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    
    ## Make integer
    gdal_calc.py -A $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif --outfile=$INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new2.tif --calc="A*100" --type=UInt16 --co="COMPRESS=DEFLATE" --co="ZLEVEL=9"
   
    ## remove temporal files and rename final layer
    rm $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new2.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 

else

    wget https://www.wsl.ch/lud/chelsa/data/timeseries/bio/CHELSA_${VAR}_${YEAR}_V1.2.1.tif
    
    ## Fix properties, compress and repair; by assign Int32 the floating number will be truncated
    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata -99999 -ot Int32 -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    
    # remove temporal files and rename final layer
    rm $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 


fi

#################################################################
