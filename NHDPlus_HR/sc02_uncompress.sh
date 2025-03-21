#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 7-00:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_uncompress.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_uncompress.sh.%A_%a.err
#SBATCH --job-name=sc02_uncompress.sh
#SBATCH --mem=50G
#SBATCH --array=13,22,85,205,213,217

# 1-225 ; one week --array=13,22,85,205,213,217 
# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc02_uncompress.sh

source ~/bin/pktools
source ~/bin/gdal3

export NHDP=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR
export file=$(ls $NHDP/input/NHDPLUS_*_RASTER.7z   | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file _RASTER.7z )

#### extract the raster 

# mkdir  $NHDP/raster/$filename
# cd $NHDP/raster/$filename
# 7za e  $NHDP/input/${filename}_RASTER.7z   fac.* -r 

# pksetmask -m $NHDP/raster/$filename/fac.tif -msknodata -9999 -nodata -9999 -p "<"  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32 -i $NHDP/raster/$filename/fac.tif -o $NHDP/raster/${filename}_fac.tif

# gdalinfo -mm  $NHDP/raster/${filename}_fac.tif   >  $NHDP/raster/${filename}_fac.tif.info 
# rm -fr $NHDP/raster/$filename

# extract the vector 
cd $NHDP/gdb
rm -rf $NHDP/gdb/${filename}_GDB.*
unzip  $NHDP/input/${filename}_GDB.zip
rm -f $NHDP/gpkg/${filename}_NHDPlusFlowlineVAA.csv $NHDP/gpkg/${filename}_NHDFlowline.{dbf,shp,prj,shx}

rm -f $NHDP/gpkg/${filename}_NHDFlowline.{dbf,shp,prj,shx}  $NHDP/gpkg/${filename}_NHDPlusFlowlineVAA.csv 
ogr2ogr -sql "SELECT NHDPlusID  FROM NHDFlowline"                   -overwrite $NHDP/gpkg/${filename}_NHDFlowline.shp         $NHDP/gdb/${filename}_GDB.gdb  
ogr2ogr -sql "SELECT NHDPlusID, TotDASqKm FROM NHDPlusFlowlineVAA"  -overwrite $NHDP/gpkg/${filename}_NHDPlusFlowlineVAA.csv  $NHDP/gdb/${filename}_GDB.gdb

### example
### ogr2ogr -sql "select inshape.*, joincsv.* from inshape left join 'joincsv.csv'.joincsv on inshape.GISJOIN = joincsv.GISJOIN" shape_join.shp inshape.shp


rm -f $NHDP/shp_flow/${filename}_NHDFlowline_VAA.{dbf,shp,prj,shx}
cd $NHDP/gpkg/  # usefull to find the csv
# it works 
ogr2ogr  -t_srs EPSG:4326  -overwrite  -sql "select ${filename}_NHDFlowline.NHDPlusID, ${filename}_NHDPlusFlowlineVAA.TotDASqKm  from ${filename}_NHDFlowline left join '${filename}_NHDPlusFlowlineVAA.csv'.${filename}_NHDPlusFlowlineVAA on ${filename}_NHDFlowline.NHDPlusID = ${filename}_NHDPlusFlowlineVAA.NHDPlusID" $NHDP/shp_flow/${filename}_NHDFlowline_VAA.shp   $NHDP/gpkg/${filename}_NHDFlowline.shp

rm -f $NHDP/gpkg/${filename}_NHDFlowline.{dbf,shp,prj,shx}  $NHDP/gpkg/${filename}_NHDPlusFlowlineVAA.csv 

exit 



several test to avoid the shp 



ogr2ogr  -overwrite -f GPKG   NHDPLUS_H_0809_HU4_GDB.gpkg  NHDPLUS_H_0809_HU4_GDB.gdb "NHDFlowline" "NHDPlusFlowlineVAA" 

ogr2ogr -f GPKG joined_output.gpkg NHDPLUS_H_0809_HU4_GDB.gpkg  -sql "SELECT NHDFlowline.NHDPlusID, NHDPlusFlowlineVAA.TotDASqKm FROM  NHDFlowline  JOIN  'NHDPLUS_H_0809_HU4_GDB'.NHDPlusFlowlineVAA  ON NHDFlowline.NHDPlusID = NHDPlusFlowlineVAA.NHDPlusID"




ogr2ogr  -overwrite -f GPKG  NHDPLUS_H_0809_HU4_GDB.gpkg  NHDPLUS_H_0809_HU4_GDB.gdb   "NHDFlowline" 
ogr2ogr  -overwrite -f CSV   NHDPlusFlowlineVAA.csv       NHDPLUS_H_0809_HU4_GDB.gdb   "NHDPlusFlowlineVAA"  

sqlite3 NHDPLUS_H_0809_HU4_GDB.gpkg   --cmd '.mode csv' '.import NHDPlusFlowlineVAA.csv NHDPlusFlowlineVAA'



ogr2ogr -f GPKG joined_output.gpkg NHDPLUS_H_0809_HU4_GDB.gpkg -sql  "SELECT NHDFlowline.NHDPlusID, NHDPlusFlowlineVAA.TotDASqKm FROM  NHDFlowline shp JOIN NHDPlusFlowlineVAA csv  ON NHDFlowline.NHDPlusID = NHDPlusFlowlineVAA.NHDPlusID"


ogr2ogr -f GPKG myjoinshp.gpkg myjoinshp.shp 
sqlite3 myjoinshp.gpkg --cmd '.mode csv' '.import myjoincsv.csv myjoincsv'
ogr2ogr -f GPKG joined_output.gpkg myjoinshp.gpkg -sql "SELECT shp.*, csv.* FROM myjoinshp shp JOIN myjoincsv csv ON shp.joinfield = csv.joinfield"
 

ogr2ogr  -t_srs EPSG:4326  -overwrite  -sql "select NHDFlowline.NHDPlusID, NHDPlusFlowlineVAA.TotDASqKm  from NHDFlowline shp  JOIN  NHDFlowline shp NHDPlusFlowlineVAA csv  on NHDFlowline.NHDPlusID = NHDPlusFlowlineVAA.NHDPlusID" output.gpkg NHDPLUS_H_0809_HU4_GDB.gpkg 


ogr2ogr  -sql    "SELECT  NHDPLUS_H_2102_HU4_NHDFlowline.NHDPlusID   AS NHDPlusID,  NHDPLUS_H_2102_HU4_NHDPlusFlowlineVAA.TotDASqKm AS TotDASqKm  FROM 'NHDPLUS_H_2102_HU4_NHDFlowline'"  test.gpkg NHDPLUS_H_2102_HU4_NHDFlowline_VAA.gpkg 
