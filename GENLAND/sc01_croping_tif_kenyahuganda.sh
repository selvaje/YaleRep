#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_croping_tif_kenyahuganda.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_croping_tif_kenyahuganda.sh.%J.err



# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GENLAND/sc01_croping_tif_kenyahuganda.sh


export PR=/project/fas/sbsc/ga254/dataproces
export SC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GENLAND/crop 

# http://www.climatologylab.org/terraclimate.html

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


ls $PR/TERRACLIMATE/*/*_2008-2017_??.tif  | xargs -n 1 -P 8 bash -c $'

gdalwarp  -overwrite  -tr 0.0083333333333333333  0.0083333333333333333 -r bilinear -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -te 29 -5 42 5   $1   $SC/TC_$(basename $1) 

' _ 


# http://chelsa-climate.org/ 

ls $PR/CHELSA/*/*_2008-2017_??.tif  | xargs -n 1 -P 8 bash -c $'

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -te    -projwin 29 5 42 5  $1   $SC/CH_$(basename $1) 

' _


