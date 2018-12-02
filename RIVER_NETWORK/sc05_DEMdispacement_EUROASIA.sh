#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_DEMdispacement_EUROASIA.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_DEMdispacement_EUROASIA.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc05_DEMdispacement_EUROASIA.sh

DIR=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK

# dem displacement 
                # 
# EUROASIA      13496    3562
# island-east    1191     333
# camptacha       497     497 
# island-west    1215     338

xminEAo=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3  )}')
ymaxEAo=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxEAo=180
yminEAo=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 40209 )) }')

echo $xminEAd $ymaxEAd $xmaxEAd $yminEAd  3562_333.tif EUROASIA original 
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin  $xminEAo $ymaxEAo $xmaxEAo $yminEAo   $DIR/dem/be75_grd_LandEnlarge.tif  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_3562_333.tif  # EUROASIA  

xminCAo=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3  )}')  # -180
ymaxCAo=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxCAo=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3 + ( 0.002083333333333 * 4990)) }')
yminCAo=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 3575)) }')

echo  $xminCAd $ymaxCAd $xmaxCAd $yminCAd 497_338.tif  camptacha original
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin $xminCAo $ymaxCAo $xmaxCAo $yminCAo   $DIR/dem/be75_grd_LandEnlarge.tif  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_497_338.tif  # camptacha 

# start the displacement EUROASIA 

xminEAd=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $3 -50 )}')
ymaxEAd=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  )}')
xmaxEAd=$( expr 180 - 50 )
yminEAd=$(gdalinfo $DIR/unit/UNIT3562_333msk.tif   | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 40209 ))    }')

echo $xminEAd $ymaxEAd $xmaxEAd $yminEAd  3562_333.tif EUROASIA displacement                                             
gdal_edit.py -a_ullr $xminEAd $ymaxEAd $xmaxEAd $yminEAd  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_3562_333.tif # EUROASIA    

xminCAd=$(expr 180 - 50 )
ymaxCAd=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4  ) }')
xmaxCAd=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" , 130 + 180 +   $3 + ( 0.002083333333333 * 4990)) }')
yminCAd=$(gdalinfo $DIR/unit/UNIT497_338msk.tif | grep "Origin" | awk '{ gsub ("[(),]"," ") ; printf ("%.14f\n" ,  $4 - ( 0.002083333333333 * 3575  ))    }')

echo  $xminCAd $ymaxCAd $xmaxCAd $yminCAd 497_338.tif  camptacha displacement 
gdal_edit.py -a_ullr  $xminCAd $ymaxCAd $xmaxCAd $yminCAd  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_497_338.tif  # camptacha  

rm -f  /tmp/out.vrt
gdalbuildvrt  /tmp/out.vrt   $DIR/dem_EUROASIA/be75_grd_LandEnlarge_497_338.tif  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_3562_333.tif  
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  /tmp/out.vrt   $DIR/dem_EUROASIA/be75_grd_LandEnlarge_EUROASIA.tif 
# rm -f  /tmp/out.vrt   $DIR/dem_EUROASIA/be75_grd_LandEnlarge_497_338.tif  $DIR/dem_EUROASIA/be75_grd_LandEnlarge_3562_333.tif  

# occurence displacement 

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $xminEAo $ymaxEAo $xmaxEAo $yminEAo $DIR/../GSW/input/occurrence_250m.tif  $DIR/GSW_unit/occurrence_250m_3562_333.tif # EUROASIA 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin  $xminCAo $ymaxCAo $xmaxCAo $yminCAo $DIR/../GSW/input/occurrence_250m.tif  $DIR/GSW_unit/occurrence_250m_497_338.tif  # camptacha  

gdal_edit.py -a_ullr   $xminEAd $ymaxEAd $xmaxEAd $yminEAd   $DIR/GSW_unit/occurrence_250m_3562_333.tif # EUROASIA
gdal_edit.py -a_ullr   $xminCAd $ymaxCAd $xmaxCAd $yminCAd   $DIR/GSW_unit/occurrence_250m_497_338.tif  # camptacha  

rm -f  /tmp/out.vrt
gdalbuildvrt  /tmp/out.vrt   $DIR/GSW_unit/occurrence_250m_3562_333.tif     $DIR/GSW_unit/occurrence_250m_497_338.tif
gdal_translate          -co COMPRESS=DEFLATE -co ZLEVEL=9    /tmp/out.vrt   $DIR/GSW_unit/occurrence_250m_EUROASIA.tif
rm -f  /tmp/out.vrt    $DIR/GSW_unit/occurrence_250m_3562_333.tif           $DIR/GSW_unit/occurrence_250m_497_338.tif

# mask displacement 

cp $DIR/unit/UNIT3562_333msk.tif $DIR/unit/UNIT3562_333msk_displace.tif # EUROASIA
cp $DIR/unit/UNIT497_338msk.tif  $DIR/unit/UNIT497_338msk_displace.tif  # camptacha  

gdal_edit.py -a_ullr $xminEAd $ymaxEAd $xmaxEAd $yminEAd  $DIR/unit/UNIT3562_333msk_displace.tif # EUROASIA
gdal_edit.py -a_ullr $xminCAd $ymaxCAd $xmaxCAd $yminCAd  $DIR/unit/UNIT497_338msk_displace.tif  # camptacha  

rm -f  /tmp/out.vrt
gdalbuildvrt  /tmp/out.vrt   $DIR/unit/UNIT3562_333msk_displace.tif   $DIR/unit/UNIT497_338msk_displace.tif  
gdal_translate -a_nodata 0   -co COMPRESS=DEFLATE -co ZLEVEL=9  /tmp/out.vrt    $DIR/unit/UNIT497_338_3562_333msk.tif 
rm -f  /tmp/out.vrt   $DIR/unit/UNIT3562_333msk_displace.tif   $DIR/unit/UNIT497_338msk_displace.tif  


sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_build_dem_location_EUROASIA.sh 



