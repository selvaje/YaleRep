#!/bin/bash
#SBATCH -p day
#SBATCH -J sc01_wget_dissolve_country.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget_dissolve_country.sh.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget_dissolve_country.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=10000
# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/GADM/sc01_wget_dissolve_country.sh

# country shapefile 

# from https://gadm.org/download_world.html

INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_shp
OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GADM/gadm36_dis

# dissolve base on the country GID_O item

ogr2ogr $OUTDIR/gadm36_GID_0.shp  $INDIR/gadm36.shp  -dialect sqlite -sql "SELECT ST_Union(geometry), "GID_0"  FROM gadm36 GROUP BY "GID_0" "

# ERROR 1: In ExecuteSQL(): sqlite3_prepare(SELECT ST_Union(geometry), GID_0  FROM gadm36 GROUP BY GID_0 ):
#   wrong number of arguments to function ST_Union()
# da controllare 


paste -d " " <(ogrinfo -al -geom=NO    gadm36.shp | grep " ID_0" ) <(ogrinfo -al -geom=NO    gadm36.shp | grep " GID_0" ) <(ogrinfo -al -geom=NO    gadm36.shp | grep " NAME_0" ) |   awk  '{ print $4 , $8 , $12 , $13 , $14 , $15 , $16 , $17  }'  |   uniq | sort  -k 1,1 -g  | uniq > ../gadm36_tif/gadm36_ID_GID_NAME.txt
