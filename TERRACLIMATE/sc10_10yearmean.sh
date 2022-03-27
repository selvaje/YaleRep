#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_10yearmean.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_10yearmean.sh.%J.err

# http://www.climatologylab.org/terraclimate.html 

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/TERRACLIMATE/sc10_10yearmean.sh

# Select Variable(s):                          hydro model 
# aet (Actual Evapotranspiration)                  
# def (Climate Water Deficit)                     
# pet (Potential evapotranspiration)              
# ppt (Precipitation) 
# q (Runoff) 
# soil (Soil Moisture) 
# srad (Downward surface shortwave radiation) 
# swe (Snow water equivalent) 
# tmax (Max Temperature) 
# tmin (Min Temperature) 
# vap (Vapor pressure) 
# ws (Wind speed) 
# vpd (Vapor Pressure Deficit) 
# pdsi (Palmer Drought Severity Index) 

for VAR in aet def pet ppt q soil srad swe  vap ws vpd pdsi tmax tmin   ; do  

export VAR
export INDIR=/project/fas/sbsc/ga254/dataproces/TERRACLIMATE/$VAR 
export RAM=/dev/shm

echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs -n 1 -P 12 bash -c $' 
MM=$1

gdalbuildvrt -srcnodata -32768 -vrtnodata -32768 $RAM/${VAR}_2008-2017_${MM}.vrt $INDIR/${VAR}_20{08,09,10,11,12,13,14,15,16,17}_${MM}.tif 
pkstatprofile   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -nodata -32768 -f mean  -i $RAM/${VAR}_2008-2017_${MM}.vrt -o  $RAM/${VAR}_2008-2017_${MM}.tif 
gdal_translate -a_nodata -32768 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $RAM/${VAR}_2008-2017_${MM}.tif $INDIR/${VAR}_2008-2017_${MM}.tif 
rm -f  $RAM/${VAR}_2008-2017_${MM}.tif  $RAM/${VAR}_${YEAR}_${MM}.vrt  
' _ 
done  

