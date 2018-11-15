#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12 -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc01_wget.sh.%J.err

# http://www.climatologylab.org/terraclimate.html 

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/TERRACLIMATE/sc01_wget.sh

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

# for VAR in aet def pet ppt q soil srad swe  vap ws vpd pdsi    ; do  
# export VAR 
# mkdir -p  /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR 
# cd /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR 
# for YEAR in $( seq 1958 2017 ) ; do 
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_${VAR}_$YEAR.nc 
# export YEAR
# echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs -n 1 -P 12 bash -c $' 
# MM=$1
# gdal_translate -a_srs EPSG:4326  -b $MM  -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND   /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR/TerraClimate_${VAR}_${YEAR}.nc /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR/${VAR}_${YEAR}_${MM}.tif 

# ' _ 
# rm  -f   /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR/TerraClimate_${VAR}_${YEAR}.nc 
# done  

# done 

## min and max have a subdataset 

for VAR in tmax tmin  ; do  
export VAR 
mkdir -p  /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR 
cd /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR 
for YEAR in $( seq 1958 2017 ) ; do 
wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_${VAR}_$YEAR.nc 
export YEAR
echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs -n 1 -P 12 bash -c $' 
MM=$1
gdal_translate -a_srs EPSG:4326  -b $MM  -co COMPRESS=DEFLATE -co ZLEVEL=9  -co INTERLEAVE=BAND  NETCDF:"TerraClimate_${VAR}_${YEAR}.nc":${VAR}  /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR/${VAR}_${YEAR}_${MM}.tif 

' _ 
rm  -f   /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/TERRACLIMATE/$VAR/TerraClimate_${VAR}_${YEAR}.nc 
done  

done 
