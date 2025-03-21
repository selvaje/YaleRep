#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc01_wget.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc01_wget.sh.%J.err
#SBATCH --mem-per-cpu=500M

## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/TERRACLIMATE/sc01_terraclimate.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/TERRA

##  sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc01_wget.sh

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

# tmin  Offset: -60, Scale:0.1 so the variable tmin_real  = (tmin * 0.1 ) - 60    unit celsius 
# tmax  Offset: -60, Scale:0.1 so the variable tmax_real  = (tmax * 0.1 ) - 60  unit celsius 
# ppt   Offset: 0,   Scale:1   so the variable ppt_real  = ppt   unit mm
# swe   Offset: 0,   Scale:1 so the variable swe_real  = swe   unit mm
# soil  Offset: 0,   Scale:1 so the variable soil_real  = soil   unit mm

## be sure to have created a folder for each of the variables previously
## cd /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
## mkdir aet def pet ppt soil srad swe tmax tmin vap ws vpd pdsi

#####  create folder link where the data will be stored ---
export TERRAOUTDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
export RAM=/dev/shm

#####  DOWNLOAD DATA   ####-------------------

#  for VARTERRA in aet def pet ppt soil srad q swe tmax tmin vap ws vpd pdsi  ; do for YEAR in {1958..2019} ; do echo $VARTERRA $YEAR ; done ; done | xargs -n 2 -P 4 bash -c $'

for VARTERRA in swe ; do for YEAR in {1958..2019} ; do echo $VARTERRA $YEAR ; done ; done | xargs -n 2 -P 4 bash -c $'
VARTERRA=$1
YEAR=$2
cd $TERRAOUTDIR/$VARTERRA
if  [ $VARTERRA = pdsi ] ; then
   wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_PDSI_${YEAR}.nc
   mv $TERRAOUTDIR/$VARTERRA/TerraClimate_PDSI_${YEAR}.nc  $TERRAOUTDIR/$VARTERRA/TerraClimate_pdsi_${YEAR}.nc
else
   wget -nc -c -nd https://climate.northwestknowledge.net/TERRACLIMATE-DATA/TerraClimate_${VARTERRA}_${YEAR}.nc
fi

' _

exit 


#####  below old procedre for the tif creaation without displacement 
#####  EXTRACT variables with no subdatasets  ####---------------

# for VARTERRA in aet def pet pdsi q soil srad swe ws vpd ; do for YEAR in {1958..2018} ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 4 bash -c $'

for VARTERRA in aet  ; do for YEAR in 1958  ; do for MES in 01  ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 4 bash -c $'

VARTERRA=$1
YEAR=$2
MES=$3
OUTNAME=$TERRAOUTDIR/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif

gdal_translate -a_nodata -32768 -of GTiff -b $MES -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 $TERRAOUTDIR/$VARTERRA/TerraClimate_${VARTERRA}_${YEAR}.nc $RAM/${VARTERRA}_${YEAR}_${MES}.tif
gdal_edit.py  -tr 0.041666666666666666666666666  -0.041666666666666666666666666 $RAM/${VARTERRA}_${YEAR}_${MES}.tif 

echo   masking the west ### 
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata -32768  -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif  -o $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

echo   transpose west to east ## 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  -180 75 -169 60 $RAM/${VARTERRA}_${YEAR}_${MES}.tif    $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif  -msknodata 0 -nodata -32768 -i $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif -o $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_ullr 180 75 191 60 $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif 

echo  merge  #### 
gdalbuildvrt -srcnodata -32768 -vrtnodata -32768 -te -180 -60 191 85 $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif 

echo  enlarge #### 
##### -md controll the number of cell to grow  # -si 

gdal_fillnodata.py -nomask  -md 4 -si 1  $RAM/${VARTERRA}_${YEAR}_${MES}.vrt $RAM/${VARTERRA}_${YEAR}_${MES}.tif 
pksetmask -of GTiff -m $RAM/${VARTERRA}_${YEAR}_${MES}.tif -msknodata -32766 -nodata -9999 -p "<" -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif -o ${OUTNAME} 

rm $RAM/${VARTERRA}_${YEAR}_${MES}.tif $RAM/${VARTERRA}_${YEAR}_${MES}_temp1.tif $RAM/${VARTERRA}_${YEAR}_${MES}_cropwest.tif 
rm $RAM/${VARTERRA}_${YEAR}_${MES}_transpose2east.tif $RAM/${VARTERRA}_${YEAR}_${MES}.vrt  $RAM/${VARTERRA}_${YEAR}_${MES}_cropwestmsk.tif 

' _

exit 

#####  EXTRACT variables with subsets   ####------------------

for VARTERRA in ppt tmax tmin vap ; do for YEAR in {1958..2018} ; do for MES in {01..12} ; do echo $VARTERRA $YEAR $MES ; done ; done ; done | xargs -n 3 -P 4 bash -c $'

VARTERRA=$1
YEAR=$2
MES=$3
OUTNAME=$TERRAOUTDIR/${VARTERRA}/${VARTERRA}_${YEAR}_${MES}.tif

gdal_translate -of GTiff -b $MES NETCDF:"$TERRAOUTDIR/$VARTERRA/TerraClimate_${VARTERRA}_${YEAR}.nc":${VARTERRA} $RAM/${VARTERRA}_${YEAR}_${MES}.tif -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9

pksetmask  -m $RAM/${VARTERRA}_${YEAR}_${MES}.tif -msknodata -32766 -nodata -9999  -p "<" -co COMPRESS=DEFLATE -co ZLEVEL=9   -i $RAM/${VARTERRA}_${YEAR}_${MES}.tif  -o $OUTNAME
gdal_edit.py  -tr 0.041666666666666666666666666  -0.041666666666666666666666666   -a_nodata -9999 $OUTNAME
rm $RAM/${VARTERRA}_${YEAR}_${MES}.tif

' _

#####   REMOVE NC FILES   ####----------------
#####  rm $TERRAOUTDIR/*/TerraClimate_*_*.nc
