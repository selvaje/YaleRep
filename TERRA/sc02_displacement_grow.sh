#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_displacement_grow.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_displacement_grow.sh.%J.err
#SBATCH --mem-per-cpu=2000M

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/TERRACLIMATE/sc01_terraclimate.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/TERRA

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc02_displacement_grow.sh

####   script lines to keep clean the /dev/shm RAM folder

find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr

## find  /dev/shm/  -user $USER | xargs -n 1 -P 4  rm -ifr 

# load modules

source ~/bin/gdal3
source ~/bin/pktools

# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_aet_2017.nc # aet (Actual Evapotranspiration)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_def_2017.nc # def (Climate Water Deficit)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_pet_2017.nc # pet (Potential evapotranspiration)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_ppt_2017.nc # ppt (Precipitation)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_q_2017.nc # q (Runoff) (useful for validation!!)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_soil_2017.nc # soil (Soil Moisture)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_srad_2017.nc # srad (Downward surface shortwave radiation)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_swe_2017.nc # swe (Snow water equivalent)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_tmax_2017.nc # tmax (Max Temperature)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_tmin_2017.nc # tmin (Min Temperature)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_vap_2017.nc # vap (Vapor pressure)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_ws_2017.nc # ws (Wind speed)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_vpd_2017.nc # vpd (Vapor Pressure Deficit)
# wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_PDSI_2017.nc # pdsi (Palmer Drought Severity Index)

## be sure to have created a folder for each of the variables previously
## cd /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
## mkdir aet def pet ppt soil srad swe tmax tmin vap ws vpd pdsi

#####  create folder link where the data will be stored ---
export TERRAOUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
export RAM=/dev/shm


#####  EXTRACT variables with subsets perform the displacement and the grow  ####---------------
# for VARTERRA in tmax ppt tmin vap ; do for YEAR in {2019..1958} ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 8 bash -c $'
# for VARTERRA in ppt  ; do for YEAR in {2019..1958} ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 8 bash -c $'

# VARTERRA=$1
# YEAR=$2
# MES=$3
# OUTNAME=$TERRAOUTDIR/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif

# gdal_translate -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9  -b $MES NETCDF:"$TERRAOUTDIR/$VARTERRA/TerraClimate_${VARTERRA}_${YEAR}.nc":${VARTERRA} $RAM/${VARTERRA}_${YEAR}_${MES}.tif 
# gdal_edit.py  -tr 0.041666666666666666666666666  -0.041666666666666666666666666 $RAM/${VARTERRA}_${YEAR}_${MES}.tif 

# echo   masking the west ### 
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata -32768  -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif  -o $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

# echo   transpose west to east ## 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  -180 75 -169 60 $RAM/${VARTERRA}_${YEAR}_${MES}.tif    $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif  -msknodata 0 -nodata -32768 -i $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif -o $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 
# gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr 180 75 191 60 $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif 

# echo  merge  #### 
# gdalbuildvrt -srcnodata -32768 -vrtnodata -32768 -te -180 -60 191 85 $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

# echo  enlarge #### 
# ##### -md controll the number of cell to grow  # -si 

# gdal_fillnodata.py -nomask  -md 10 -si 1  $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}.tif 
# pksetmask -of GTiff -m $RAM/${VARTERRA}_${YEAR}_${MES}.tif -msknodata -32766 -nodata -9999 -p "<" -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif -o ${OUTNAME} 

# rm -f $RAM/${VARTERRA}_${YEAR}_${MES}.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 
# rm -f $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}.vrt  $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 

# ' _

#####  EXTRACT variables with no subdatasets perform the displacement and the grow  ####---------------

### in caso di rerun add the ND and DT for the other variable
#### for VARTERRA in aet def pet pdsi q soil srad swe ws vpd ; do for YEAR in {1958..2019} ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 8 bash -c $'

for VARTERRA in swe  ; do for YEAR in $( seq 1958 2019 )    ; do for MES in 01 02 03 04 05 06 07 08 09 10 11 12 ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 4 bash -c $'

VARTERRA=$1
YEAR=$2
MES=$3
OUTNAME=$TERRAOUTDIR/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif

if [ $VARTERRA = soil ]  ; then  ND=-32768      ; DT=Int16 ;    fi 
if [ $VARTERRA = swe  ]  ; then  ND=-2147483648 ; DT=Int32 ;    fi 

gdal_translate -a_nodata $ND -ot $DT -of GTiff -b $MES -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 $TERRAOUTDIR/$VARTERRA/TerraClimate_${VARTERRA}_${YEAR}.nc $RAM/${VARTERRA}_${YEAR}_${MES}.tif
gdal_edit.py  -tr 0.041666666666666666666666666  -0.041666666666666666666666666 $RAM/${VARTERRA}_${YEAR}_${MES}.tif 

echo   masking the west ### 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata $ND  -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif  -o $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

echo   transpose west to east ## 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  -180 75 -169 60 $RAM/${VARTERRA}_${YEAR}_${MES}.tif    $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif  -msknodata 0 -nodata $ND -i $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif -o $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr 180 75 191 60 $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif 

echo  merge  #### 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -te -180 -60 191 85 $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

echo  enlarge #### 
##### -md controll the number of cell to grow  # -si 

gdal_fillnodata.py -nomask  -md 10 -si 1  $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}.tif 
gdalinfo -mm $RAM/${VARTERRA}_${YEAR}_${MES}.tif | grep Computed | awk -F , \'{ gsub(","," "); gsub("="," "); print $1}\' | awk \'{print int($3), int($4)}\' > ${OUTNAME}.mm
pksetmask -of GTiff -m $RAM/${VARTERRA}_${YEAR}_${MES}.tif -msknodata $ND  -nodata -9999  -p "=" -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif -o ${OUTNAME} 

rm -f $RAM/${VARTERRA}_${YEAR}_${MES}.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 
rm -f $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}.vrt  $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 

' _


exit 

#### several files has some pixel nodata in the sahara
cd  /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
ls  */*.tif |  xargs -n 1 -P 4 bash -c $'                                                                                          
file=$1
echo $file $(gdallocationinfo -valonly $file  5000 1438 )
' _   | grep 9999  | awk '{ print $1  }' > fill_tif.txt  


cat fill_tif.txt | xargs -n 1 -P 4 bash -c $'
file=$1
filename=$(basename $file .tif )
gdal_fillnodata.py -nomask -md 20 -si 1 /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/$file /dev/shm/$filename.tif
pksetmask -m /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/ppt/ppt_2000_03.tif -msknodata -9999 -nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -i /dev/shm/$filename.tif -o /dev/shm/${filename}_fill.tif 
rm -f /dev/shm/$filename.tif
mv /dev/shm/${filename}_fill.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/$file
' _


