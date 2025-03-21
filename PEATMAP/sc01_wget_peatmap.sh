#!/bin/bash

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/PEATMAP/sc01_wget_peatmap.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP/SHP
cd $DIR

# Spatial reference system: Geographic coordinate system
# Datum: WGS84
# Projected Coordinate System: World Cylindrical Equal Area
# ESRI:54034 - World_Cylindrical_Equal_Area - Projected
# EPSG:3410???
# EPSG:9834???

###    extracted on the 20.04.2020
wget http://archive.researchdata.leeds.ac.uk/251/4/Africa.zip
wget http://archive.researchdata.leeds.ac.uk/251/5/Asia.zip
wget http://archive.researchdata.leeds.ac.uk/251/6/Europe.zip
wget http://archive.researchdata.leeds.ac.uk/251/11/North_America.zip
wget http://archive.researchdata.leeds.ac.uk/251/12/Oceania.zip
wget http://archive.researchdata.leeds.ac.uk/251/13/South_America.zip

unzip Africa.zip
unzip Asia.zip
unzip Europe.zip
unzip North_America.zip
unzip Oceania.zip
unzip South_America.zip

mv 'North America' North_America
mv 'South America' South_America

### some shapefiles have spaces in their names

cd $DIR/Asia
for f in Histosols_*; do mv "$f" "$(echo "$f" | sed s/" "/\_/)"; done

cd $DIR/Europe
for f in British*; do mv "$f" "$(echo "$f" | sed s/" "/\_/)"; done
for f in British_Isles*; do mv "$f" "$(echo "$f" | sed s/" "/\_/)"; done

cd ../..

exit

###  When running the for loop below the following warning appears for several layers:
## Warning 1: Value 68636.5 of field Area of feature 0 not successfully written. Possibly due to too larger number with respect to field width
## potential solution:
## https://trac.osgeo.org/gdal/ticket/6803

###  The code below did not work for ./South_America/SA_Peatland.dbf
### therefore script sc01b...

###  Add a new column to attribute table with code = 1, to create a binary layer when rasterizing
for FILE in $(find . -name '*.dbf')
do
  name=$( basename ${FILE} .dbf )
  ogrinfo ${FILE} -sql "ALTER TABLE $name ADD COLUMN diss integer(1)"
  ogrinfo ${FILE} -dialect SQLite -sql "UPDATE $name SET diss = 1"
done


######   merge all files into one
## Not RUN  #####
# file="Global/peatmapGlobal.shp"
#
# for i in $(find . -name '*.shp')
# do
#
#       if [ -f “$file” ]
#       then
#            echo 'creating peatmapGlobal.shp'
#            ogr2ogr -f 'ESRI Shapefile' -update -append $file $i -nln peatmapGlobal
#       else
#            echo 'merging……'
#       ogr2ogr -f 'ESRI Shapefile' $file $i
# fi
# done
