#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_rasterize.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_rasterize.sh.%A_%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_rasterize.sh 


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc03_rasterize.sh 

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

# 

export DIR=/project/fas/sbsc/ga254/dataproces/NHDplus

echo rasteri the full network 
rm -f $DIR/tmp/select.*  $DIR/tif/*.tif  

ls $DIR/shp/*/NHDFlowline.shp  | xargs -n 1 -P 2 bash -c  $'
file=$1
     dirname=$(basename $( dirname   $file ))  
     ogr2ogr  -where  " FTYPE=\'StreamRiver\' OR  FTYPE=\'Connector\' OR  FTYPE=\'ArtificialPath\' "   $DIR/tmp/$dirname.shp  $file
     gdal_rasterize  -ot  Byte -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -tap -tr   0.000833333333333  0.000833333333333   -burn 1  $DIR/tmp/$dirname.shp   $DIR/tif/$dirname.tif
     rm  -f  $DIR/tmp/$dirname.{dbf,prj,shp,shp.xml,shx}
' _

# echo start to merge the file 

gdalbuildvrt  -te  -126 25 -66 51   -overwrite   -srcnodata 0  -vrtnodata 0    -overwrite $DIR/output.vrt   $DIR/tif/*.tif
pkcreatect  -co COMPRESS=DEFLATE -co ZLEVEL=9   -min 0 -max 1 -i     $DIR/output.vrt  -o   $DIR/tif_merge/NHDplus_90m.tif 
rm $DIR/output.vrt 

exit 



echo raster river order number 1 
rm -f $DIR/tmp/select.*    $DIR/tif/*.tif    /gpfs/scratch60/fas/sbsc/ga254/dataproces/NHDplus/NHDplus_H_250m_order1.tif 

ls $DIR/shp/*/NHDFlowline.shp  | xargs -n 1 -P 4 bash -c  $'
file=$1
    dirname=$(basename $( dirname   $file ))  

    ogr2ogr  -where  "StreamOrde = 1 " $DIR/tmp/${dirname}_tmp.shp  $file
    ogr2ogr  -where  "FTYPE = \'ArtificialPath\' OR FTYPE = \'StreamRiver\' " $DIR/tmp/$dirname.shp   $DIR/tmp/${dirname}_tmp.shp 
    gdal_rasterize  -ot  Byte -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9 -tap -tr  0.002083333333333 0.002083333333333    -burn 1  $DIR/tmp/$dirname.shp   $DIR/tif/$dirname.tif
    rm  -f  $DIR/tmp/$dirname.{dbf,prj,shp,shp.xml,shx}   $DIR/tmp/${dirname}_tmp.{dbf,prj,shp,shp.xml,shx}
' _

echo start to merge the file 

gdalbuildvrt  -te  -126 25 -66 50.6312500  -overwrite   -srcnodata 0  -vrtnodata 0    -overwrite $DIR/output.vrt   $DIR/tif/*.tif

pkcreatect  -co COMPRESS=DEFLATE -co ZLEVEL=9   -min 0 -max 1 -i     $DIR/output.vrt  -o     $DIR/NHDplus_H_250m_order1.tif 
rm $DIR/output.vrt 

