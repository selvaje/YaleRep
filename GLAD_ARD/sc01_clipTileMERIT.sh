#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 16 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_clipTileMERIT.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_clipTileMERIT.sh.%J.err
#SBATCH --mem=60G 
#SBATCH --job-name=sc01_clipTileMERIT.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools 

##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GLAD_ARD/sc01_clipTileMERIT.sh

##  -ulx=-180 --uly=85 --lrx=195 --lry=-60 

ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/msk/{s,n}??{w,e}???_msk.tif | xargs -n 1 -P 16 bash -c $' 
file=$1
name=$(basename $file .tif )
rm -f  /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/$name.*
ogr2ogr -spat $(getCorners4Gwarp $file) /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/$name.shp    /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/glad_landsat_tiles.shp

rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/MERIT_$name.shp 
pkextractogr -f "ESRI Shapefile" -srcnodata 0 -r max  -i $file  -s /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/$name.shp  -o /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/MERIT_$name.shp 

rm -f  /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/$name.*

' _ 


cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/tmp/
rm -f ./consolidated.{shp,shx,prj,dbf}

rm -f ./consolidated.*
consolidated_file="./consolidated.shp"
for i in $(find . -name 'MERIT_*.shp'); do
    if [ ! -f "$consolidated_file" ]; then
        # first file - create the consolidated output file
        ogr2ogr -f "ESRI Shapefile" $consolidated_file $i
    else
        # update the output file with new file content
        ogr2ogr -f "ESRI Shapefile" -update -append $consolidated_file $i
    fi
done

ogr2ogr  /gpfs/gibbs/pi/hydro/hydro/dataproces/GLAD_ARD/metadata/glad_landsat_tiles/MERIT_landsat_tiles.shp ./consolidated.shp 


