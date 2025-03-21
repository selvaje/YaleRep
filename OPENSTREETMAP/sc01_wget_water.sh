#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 24:00:00   
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_water.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_water.sh.%J.err
#SBATCH --job-name=sc01_wget_water.sh
#SBATCH --mem=20G

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/OPENSTREETMAP/sc01_wget_water.sh

source ~/bin/gdal

export INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/OPENSTREEMAP/water
cd $INDIR

echo camerica,central-america-latest.osm.pbf > OSM_regions.txt
echo africa,africa-latest.osm.pbf >> OSM_regions.txt
echo asia,asia-latest.osm.pbf >> OSM_regions.txt
echo australia,australia-oceania-latest.osm.pbf >> OSM_regions.txt
echo europe,europe-latest.osm.pbf >> OSM_regions.txt
echo namerica,north-america-latest.osm.pbf >> OSM_regions.txt
echo samerica,south-america-latest.osm.pbf >> OSM_regions.txt


for NUM in {1..7}; do

export Foname=$(awk -F, 'FNR == '$NUM' {print $1}' OSM_regions.txt)
export Finame=$(awk -F, 'FNR == '$NUM' {print $2}' OSM_regions.txt)

mkdir $Foname

echo
echo ----------------------------------------------------
echo Downloading $Foname
echo ----------------------------------------------------
echo

### wget https://download.geofabrik.de/${Finame} -P ${Foname}

echo waterways water reservoir | xargs -n 1 -P 3 bash -c $'

if [ $1 = "waterways"   ] ; then 

echo
echo ----------------------------------------------------
echo Extracting waterways of $Foname
echo ----------------------------------------------------
echo

ogr2ogr -overwrite -f "ESRI Shapefile" ${Foname}/${Foname}_osm_$1.shp ${Foname}/${Finame} -progress -sql "SELECT osm_id,name,waterway from lines WHERE waterway is not null"

fi 

if [ $1 = "water" ] ; then 
echo
echo ----------------------------------------------------
echo Extracting water of $Foname
echo ----------------------------------------------------
echo

ogr2ogr -overwrite -f "ESRI Shapefile" ${Foname}/${Foname}_osm_$2.shp ${Foname}/${Finame} -progress -sql "SELECT osm_id,name,natural from multipolygons WHERE natural = \'water\'"

fi 

if [ $1 = "reservoir" ] ; then 

echo
echo ----------------------------------------------------
echo Extracting reservoirs of $Foname
echo ----------------------------------------------------
echo

ogr2ogr -overwrite -f "ESRI Shapefile" ${Foname}/${Foname}_osm_$3.shp ${Foname}/${Finame} -progress -sql "SELECT osm_id,name,landuse from multipolygons WHERE landuse = \'reservoir\'"

fi

' _

done
