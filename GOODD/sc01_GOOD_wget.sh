#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 00:10:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_GOOD_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_GOOD_wget.sh.%J.err
#SBATCH --job-name=sc01_GOOD_wget.sh

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GOODD/sc01_GOOD_wget.sh

module purge
source ~/bin/gdal

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GOODD
#DIR=/data/shared/GOOD

wget https://ndownloader.figshare.com/files/17462066 -P $DIR
unzip -j $DIR/17462066 -d $DIR

###  Add a new column to attribute table with code = 1, to create a binary layer when rasterizing the points
myfile=$DIR/GOOD2_dams.dbf
name=$( basename $myfile .dbf )


ogrinfo $myfile -sql "ALTER TABLE $name ADD COLUMN diss integer(1)"
ogrinfo $myfile -dialect SQLite -sql "UPDATE $name SET diss = 1"

## the next to lines create a new field replicating the DAM_ID field but as an integer
#ogrinfo $myfile -sql "ALTER TABLE $name ADD COLUMN code_num integer(7)"
#ogrinfo $myfile -dialect SQLite -sql "UPDATE $name SET code_num = CAST(DAM_ID AS integer(7))"
