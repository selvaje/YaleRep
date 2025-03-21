#!/bin/bash


## copy to scripts
#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/GranD/sc02_GranD_preprocess.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GRAND/

#####   NOT RUN IN GRACE YET!!!!!    DON'T KNOW HOW!!!!

module load R
source ~/bin/gdal

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND

#####    PREPROCESSING
####  many records with year = -99. In this case these records need to be deleted
####  and also all years before 1900

ogr2ogr -sql "SELECT CAP_MCM, YEAR  FROM  GRanD_dams_v1_3  WHERE ( YEAR  >= 1900 ) " $DIR/grand_dams_R.shp $DIR/GRanD_dams_v1_3.shp

###   FILE of teils based on MERIT
cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif_shp* $DIR

# ###  Add a new column to attribute table with id as a sequence integer
 myfile=$DIR/all_tif_shp.dbf
 name=$( basename $myfile .dbf )

ogrinfo $myfile -sql "ALTER TABLE $name ADD COLUMN id integer(1)"
ogrinfo $myfile -dialect SQLite -sql "UPDATE $name set id = rowid+1"

###  INTERSECTION

### run in R
#R --slave -f myscript.R
R --vanilla --no-readline -q  << "EOF"

library(rgdal)
library(sp)

DIR = Sys.getenv(c("DIR"))

dams = readOGR(DIR, "grand_dams_R")
teil = readOGR(DIR, "all_tif_shp")
# dams = readOGR("/home/jaime/Data/temp", "grand_dams_R")
# teil = readOGR("/home/jaime/Data/temp", "all_tif_shp")

####  CLEANING THE DAMS DATA

## multiply the dam capacity by 100 to work with integers
dams$CAP_MCM = dams$CAP_MCM *100

## remove dams with capacity less than zero (some records have a -99 value = NA)
dams = dams[-which(dams$CAP_MCM < 0),]

####  CLEANING THE TEIL DATA

#remove teils with no overlapping points
intrt = over(teil, dams)
indx = which(is.na(intrt))
teil = teil[-indx,]

####  INTERSECTING DATA

# intersect dams with teils and assign teil id to dams
intdams = over(dams, teil)
dams@data = cbind(dams@data, intdams[,2])
names(dams)[3] = "teil_id"

#### create shapes
# Dams
writeOGR(dams, DIR, "Grand_Dams", driver="ESRI Shapefile")
#writeOGR(dams, "/home/jaime/Data/temp", "Grand_Dams", driver="ESRI Shapefile")
# teils
writeOGR(teil, DIR, "Grid_Teil", driver="ESRI Shapefile")
#writeOGR(teil, "/home/jaime/Data/temp", "Grid_Teil", driver="ESRI Shapefile")

EOF


exit

scp -i ~/.ssh/JG_PrivateKeyOPENSSH  /home/jaime/Data/temp/Grand_Dams* jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND

scp -i ~/.ssh/JG_PrivateKeyOPENSSH  /home/jaime/Data/temp/Grid_Teil* jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GRAND
