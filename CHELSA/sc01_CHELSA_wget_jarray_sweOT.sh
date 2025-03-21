#!/bin/bash

#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 00:30:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_CHELSA_wget_jarray_sweOT.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_CHELSA_wget_jarray_sweOT.sh.%A_%a.err
#SBATCH --mem-per-cpu=8000M
#SBATCH --array=1-770%10
 
###############  1-770

module purge
source ~/bin/gdal

####  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/CHELSA/sc01_CHELSA_wget_jarray_sweOT.sh  
  
#### Create folders to store variables
#### cd /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/
#### mkdir swe fcf gts0 gts5 gts10 gts30 gdd0 gdd5 gdd10 gdd30 end0 end5 end10 end30 1st0 1st5 1st10 1st30 lgd gst gsl fgd

#### Create file with the task array
#### for VAR in swe fcf gts0 gts5 gts10 gts30 gdd0 gdd5 gdd10 gdd30 end0 end5 end10 end30 1st0 1st5 1st10 1st30 lgd gst gsl fgd ; do for YEAR in {1979..2013} ; do echo ${VAR} ${YEAR} ; done ; done  > /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_sweOT_list.txt


####   VARIABLES
# # Check here for more details: http://chelsa-climate.org/wp-admin/download-page/CHELSA_tech_specification.pdf

# # swe --- snow water equivalent
# # lgd --- last day of the growing season TREELIM ((.sdat))
# # gts > 0 5 10 30 --- Growing degree days heat sum above [treshold_temperature]
# # gst --- Mean temperature of the growing season TREELIM ((.sdat))
# # gsl --- growing season length TREELIM ((.sdat))
# # gdd > 0 5 10 30 --- Number of days above [treshold_temperature]
# # fgd --- first day of the growing season TREELIM ((.sdat))
# # fcf --- Frost change frequency
# # end > 0 5 10 30 --- Last growing degree day [treshold_temperature]
# # 1st > 0 5 10 30 --- mean daily surface temperature where land
   
LINE=$( cat /gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/job_array_sweOT_list.txt   | head -n $SLURM_ARRAY_TASK_ID | tail -1 )

VAR=$(echo $LINE | awk '{ print $1 }' )
YEAR=$(echo $LINE | awk '{ print $2 }' )

INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA 
cd $INDIR/$VAR

    ## These 4 variables come as integer Int16 with -32767 as NO-DATA
if [ $VAR = "lgd" ] || [ $VAR = "gst" ] || [ $VAR = "gsl" ] || [ $VAR = "fgd" ] ; then
    
    wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_V1.2.1.sdat.tif
    ## Fix properties with gdal_edit
    gdal_edit.py -a_nodata -32767 -a_ullr -180 84 180 -90 -a_srs EPSG:4326  $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.sdat.tif
    ## rename
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.sdat.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif

fi

## These variables come as floating Float32 with -99999 as NO-DATA
if [ $VAR = "swe" ] || [ $VAR = "gts0" ] || [ $VAR = "gts5" ] || [ $VAR = "gts10" ] || [ $VAR = "gts30" ] ; then

    wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_V1.2.1.tif
    ## Fix properties, compress and repair
    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata -99999   -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    ## Make integer
    gdal_calc.py -A $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif --outfile=$INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new2.tif --calc="A*100" --type=UInt32 --co="COMPRESS=DEFLATE" --co="ZLEVEL=9"
    # remove temporal files and rename final layer
    rm $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new2.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
fi

## These variables come as floating Float32 but with integer values and with unexistant NO-DATA
if [ $VAR = "fcf" ] || [ $VAR = "gdd0" ] || [ $VAR = "gdd5" ] || [ $VAR = "gdd10" ] || [ $VAR = "gdd30" ] ; then

    wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_V1.2.1.tif
    ## Fix properties, compress and repair ----  NEED TO BE TRANSFORM TO INTEGER UINT16 AND NODATA TO 9999
    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata 9999 -ot UInt16  -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    # remove temporal files and rename final layer
    rm $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
fi

## These variables come as floating Float32 but with integer values and with -32767 NO-DATA
if [ $VAR = "end0" ] || [ $VAR = "end5" ] || [ $VAR = "end10" ] || [ $VAR = "end30" ] || [ $VAR = "1st0" ] || [ $VAR = "1st5" ] || [ $VAR = "1st10" ] || [ $VAR = "1st30" ] ; then

    wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_${YEAR}_V1.2.1.tif
    ## Fix properties, compress and repair ----  NEED TO BE TRANSFORM TO INTEGER UINT16 AND NODATA TO 9999
    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata -32767 -ot Int16  -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif 
    # remove temporal files and rename final layer
    rm $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
    mv $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1_new.tif $INDIR/$VAR/CHELSA_${VAR}_${YEAR}_V1.2.1.tif 
fi

exit


#################################################################
######  Check variables first

#echo swe fcf gts0 gts5 gts10 gts30 gdd0 gdd5 gdd10 gdd30 end0 end5 end10 end30 lgd gst gsl fgd | xargs -n 1 -P 5 bash -c $'

echo 1st0 1st5 1st10 1st30 | xargs -n 1 -P 5 bash -c $'

VAR=$1
if [ $VAR = "lgd" ] || [ $VAR = "gst" ] || [ $VAR = "gsl" ] || [ $VAR = "fgd" ] ; then
  wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_2013_V1.2.1.sdat.tif
  mv CHELSA_${VAR}_2013_V1.2.1.sdat.tif CHELSA_${VAR}_2013_V1.2.1.tif
else
  wget https://www.wsl.ch/lud/chelsa/data/timeseries/${VAR}/CHELSA_${VAR}_2013_V1.2.1.tif
fi 
' _

    gdal_translate --config GDAL_NUM_THREADS 2 --config GDAL_CACHEMAX 2000 -a_nodata -32767 -ot Int16  -co COMPRESS=DEFLATE  -co ZLEVEL=9  -a_ullr -180 84 180 -90 -a_srs EPSG:4326 CHELSA_end0_2013_V1.2.1.tif CHELSA_end0_2013_V1.2.1_new.tif
