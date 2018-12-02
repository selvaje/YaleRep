#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 4  -N 1
#SBATCH -t 3:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_rasterize_4proximity.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_rasterize_4proximity.sh.%J.out
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_rasterize_4proximity.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc03_rasterize_4proximity.sh

# FCODE
# STREAM/RIVER  46000  feature type only: no attributes
# STREAM/RIVER  46003  Hydrographic Category|intermittent
# STREAM/RIVER  46006  Hydrographic Category|perennial
# STREAM/RIVER  46007  Hydrographic Category|ephemeral
# FType 460 
# FType 558   ARTIFICIAL PATH 

# NHDplus  https://nhd.usgs.gov/userGuide/Robohelpfiles/NHD_User_Guide/Feature_Catalog/Hydrography_Dataset/Complete_FCode_List.htm  

#   FTYPE (String) = ArtificialPath
#   FTYPE (String) = CanalDitch
#   FTYPE (String) = Connector
#   FTYPE (String) = Pipeline
#   FTYPE (String) = StreamRiver

# http://projectionwizard.org/ good tools to select projection 

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus

echo rasteri the full network 
rm -f $DIR/tmp/select.*  $DIR/tif/*.tif  $DIR/shp_nad83m/* 

ls $DIR/shp/*/NHDFlowline.shp  | xargs -n 1 -P 4 bash -c  $'
file=$1
     dirname=$(basename $( dirname   $file ))  

     ogr2ogr  -t_srs "+proj=eqdc +lat_1=28 +lat_2=45 +lon_0=-96  +ellps=GRS80 +datum=NAD83 +units=m no_defs"   -where  " FTYPE=\'StreamRiver\' OR  FTYPE=\'Connector\' OR  FTYPE=\'ArtificialPath\' "   $DIR/shp_nad83m/$dirname.shp  $file

     gdal_rasterize  -ot  Byte -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -tap -tr  90 90  -burn 1  $DIR/shp_nad83m/$dirname.shp   $DIR/tif/$dirname.tif
     # rm  -f  $DIR/tmp/$dirname.{dbf,prj,shp,shp.xml,shx}
' _


 
echo start to merge the file 
#             -te    xmin     ymin    xmax    ymax
gdalbuildvrt  -te -2400000   2800000  2300000 5700000  -overwrite   -srcnodata 0  -vrtnodata 0    -overwrite $DIR/output.vrt   $DIR/tif/*.tif
pkcreatect  -co COMPRESS=DEFLATE -co ZLEVEL=9   -min 0 -max 1 -i     $DIR/output.vrt  -o   $DIR/tif_merge/NHDplus_90m_NAD83m.tif 
rm $DIR/output.vrt 



sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc05_proximity.sh
