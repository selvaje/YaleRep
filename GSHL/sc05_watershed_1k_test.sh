#!/bin/bash
#SBATCH -p day
#SBATCH -J sc03_watershed_1k.sh
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_watershed_1k.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_watershed_1k.sh.%J.err
#SBATCH --mail-user=email

# sbatch  --mem-per-cpu=50000  /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc05_watershed_1k.sh 
# following the example at http://insightsoftwareconsortium.github.io/SimpleITK-Notebooks/32_Watersheds_Segmentation.html

export DIR=/tmp/tmp
export PATH=/home/fas/sbsc/ga254/anaconda3/bin:$PATH

rm -f  $DIR/watershed_line_nogeo.tif  $DIR/watershed_poly_nogeo.tif  

python <<EOF
import os

import SimpleITK as sitk
print("importing image")
img  = sitk.ReadImage("/home/fas/sbsc/ga254/tmp/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_cost.tif" , sitk.sitkFloat32  )  

# # to check img.GetPixelIDTypeAsString 32-bit unsigned integer  
core = sitk.ReadImage("/home/fas/sbsc/ga254/tmp/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_peaka.tif")

marker_img  = sitk.ConnectedComponent(core, fullyConnected=True)

print("start watershed")
ws_line  = sitk.MorphologicalWatershedFromMarkers( img, marker_img, markWatershedLine=True,  fullyConnected=True)
sitk.WriteImage( sitk.Cast( ws_line  ,  sitk.sitkFloat32  ),        "/home/fas/sbsc/ga254/tmp/watershed_line_nogeo.tif" )
del(ws_line)

ws_poly  = sitk.MorphologicalWatershedFromMarkers( img, marker_img, markWatershedLine=False, fullyConnected=True)
sitk.WriteImage( sitk.Cast( ws_poly  ,  sitk.sitkFloat32  ),        "/home/fas/sbsc/ga254/tmp/watershed_poly_nogeo.tif" )
del(ws_poly)
EOF

exit 



# export PATH=/gpfs/apps/hpc/Apps/GRASS/7.0.2/bin:/gpfs/apps/hpc.rhel7/Tools/PKTOOLS/2.6.7/bin:/gpfs/apps/hpc/Libs/GSL/2.2/bin:/gpfs/apps/hpc/Libs/OSGEO/1.11.2/bin:/gpfs/apps/hpc/Langs/Python/2.7.10/bin:/gpfs/apps/hpc/Libs/WXPYTHON/3.0.0/bin:/gpfs/apps/hpc/Langs/GCC/5.2.0/bin:/gpfs/apps/hpc/Libs/NUMPY/1.9.2/bin:/gpfs/apps/hpc.rhel7/Libs/GDAL/1.11.2/bin:/gpfs/apps/hpc/Libs/GEOS/3.4.0/bin:/gpfs/apps/hpc.rhel7/Libs/GEOTIFF/1.4.0/bin:/gpfs/apps/hpc.rhel7/Libs/TIFF/4.0.7/bin:/gpfs/apps/hpc/Libs/NetCDF/4.2.1.1-hdf4/bin:/gpfs/apps/hpc/Libs/HDF4/4.2.9-nonetcdf-gcc/bin:/gpfs/apps/hpc/Libs/HDF5/1.8.13-gcc/bin:/gpfs/apps/hpc/Langs/TCLTK/8.5.14/bin:/usr/lib64/qt-3.3/bin:/usr/lib64/ccache:/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:/opt/ibutils/bin:/home/fas/sbsc/ga254/bin:/home/fas/sbsc/ga254/bin:/home/fas/sbsc/ga254/bin

# gdal_edit.py -a_srs EPSG:4326  -a_ullr $(getCorners4Gtranslate $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_cost.tif  ) $DIR/watershed_line_nogeo.tif 

# pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -min -1 -max 0.5  -i  $DIR/watershed_line_nogeo.tif -o  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_line.tif
# rm -f $DIR/watershed_line_nogeo.tif 

# gdal_edit.py  -a_srs EPSG:4326 -a_ullr $(getCorners4Gtranslate $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_cost.tif  ) $DIR/watershed_poly_nogeo.tif  


# pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9   -m $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT4ws.tif   -msknodata 0  -nodata 0 -i    $DIR/watershed_poly_nogeo.tif  -o   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif
# rm -f $DIR/watershed_poly_nogeo.tif  

# # fatti correre solo  una  volta 
# # pkfilter  -co COMPRESS=DEFLATE -co ZLEVEL=9  -dx 4 -dy 4 -d 4 -f mode   -i /project/fas/sbsc/ga254/dataproces/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  -o    $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  
# # cp   /project/fas/sbsc/ga254/dataproces/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  /project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_250_v1_0_watershad 

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -m $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  -msknodata 3767 -nodata 0 -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk.tif 

# # clumping operation to create unique poligons in areas where the mask split the plygons 

# pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 3766.5   -max 3767.5 -data 0 -nodata 1 -ot Byte  -i $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif -o $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT4ws_tmp.tif 
# gdal_translate  -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin  -180 80 180 -60    $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT4ws_tmp.tif  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT4ws.tif 
# rm  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT4ws_tmp.tif  

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/ cost1k_clump  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk.tif    r.in.gdal 

r.clump -d  --overwrite    input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk      output=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump
r.out.gdal --overwrite nodata=0 -c -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump  output=$DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif 

rm -fr /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/grassdb/cost1k_clump  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif.aux.xml 

cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif

DIR=/project/fas/sbsc/ga254/dataproces/GSHL/final_product_1k
bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.txt 
awk '{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }' $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.txt > $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump0.txt 
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.tif $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump0.txt $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_ct.tif

rm -f   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump0.txt  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.txt
exit 

# remove the below part 





rm -fr  $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core.{shp,prj,shx,dbf}
gdal_polygonize.py -f "ESRI Shapefile" $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core.tif  $DIR/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core.shp 

# final product 


cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.shp      $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.shp
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.prj      $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.prj
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.shx      $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.shx
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.dbf      $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump.dbf

cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.tif  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_bin_clump.tif
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.shp  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_bin_clump.shp
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.prj  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_bin_clump.prj
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.dbf  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_bin_clump.dbf
cp $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump_bin.shx  $DIR/../final_product_1k/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_bin_clump.shx


rm -f  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.{shp,prj,shx,dbf}
gdal_polygonize.py -f "ESRI Shapefile" $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_ws_clump_msk_clump.shp


# 

