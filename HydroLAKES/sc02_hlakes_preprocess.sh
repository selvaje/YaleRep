#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 00:05:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc02_hlakes_preprocess.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc02_hlakes_preprocess.sh.%J.err

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/HydroLAKES/sc02_hlakes_preprocess.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/HydroLAKES/sc02_hlakes_preprocess.sh

module purge
source ~/bin/gdal

###   Add a new column to the hydroLAKES vector file and calculate (Volume / Lake Area)

#DIR=/home/jaime/Data/hydroLAKES/HydroLAKES_polys_v10_shp
DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/HydroLAKES

myfile=$DIR/HydroLAKES_polys_v10_shp/HydroLAKES_polys_v10.dbf
name=$( basename $myfile .dbf )

ogrinfo $myfile -sql "ALTER TABLE $name ADD COLUMN VolArea real(9,5)"
ogrinfo $myfile -dialect SQLite -sql "UPDATE $name set VolArea = Vol_total/Lake_area"

#-------------------------------------------------------------------------------


### Bring the vector FILE of teils based on MERIT
cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif_shp* $DIR
#/home/jaime/Data/temp/all_tif_shp.shp

# ###  Add a new column to attribute table with id as a sequence integer
 myfile=$DIR/all_tif_shp.dbf
 name=$( basename $myfile .dbf )

ogrinfo $myfile -sql "ALTER TABLE $name ADD COLUMN teil_id integer(1)"
ogrinfo $myfile -dialect SQLite -sql "UPDATE $name set teil_id = rowid+1"

#-------------------------------------------------------------------------------
