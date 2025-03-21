#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc41_europe_extract.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc41_europe_extract.sh.%J.err
#SBATCH --job-name=sc41_europe_extract.sh
#SBATCH --mem=10G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc41_europe_extract.sh

source ~/bin/gdal3
source ~/bin/pktools

EU=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe

paste -d " " $EU/eu_x_y_hight.txt <(gdallocationinfo -geoloc -wgs84 -valonly $EU/treecover2000/treecover.tif  <  $EU/eu_x_y.txt) \
                                  <(gdallocationinfo -geoloc -wgs84 -valonly $EU/ghs_built/ghs_built_LDSMT_epoc.tif  <  $EU/eu_x_y.txt ) \
                                   | awk '{ if ($4!=0 && $5==2) print $1 , $2 , $3 , $4 , $5 }'  > $EU/eu_x_y_hight_forest.txt
exit 
awk '{  print $1 , $2 }'  $EU/eu_x_y_hight_forest.txt > $EU/eu_x_y_forest.txt

gdalbuildvrt -overwrite -separate $EU/all_tif.vrt    $(ls $EU/*/*.tif | grep -v -e glad_ard -e ghs_built )
BB=$(ls $EU/*/*.tif | grep -v -e glad_ard -e ghs_built | wc -l  )
gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard.vrt  < $EU/eu_x_y_forest.txt | awk           'ORS=NR%6?FS:RS'  > $EU/eu_x_y_forest_glad_ard.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/all_tif.vrt            < $EU/eu_x_y_forest.txt | awk -v BB=$BB 'ORS=NR%BB?FS:RS' > $EU/eu_x_y_forest_all_tif.txt

echo "x y h B1 B2 B3 B4 B5 B6" $(for file in $(ls $EU/*/*.tif | grep -v -e glad_ard -e ghs_built ) ; do echo -n  $(basename $file .tif)" " ; done) > $EU/eu_x_y_hight_predictors.txt  
paste -d " " $EU/eu_x_y_hight_forest.txt  $EU/eu_x_y_forest_glad_ard.txt $EU/eu_x_y_forest_all_tif.txt  >> $EU/eu_x_y_hight_predictors.txt

rm -f $EU/eu_x_y_forest_all_tif.txt $EU/eu_x_y_forest_glad_ard.txt 

exit 


paste -d " " $EU/eu_x_y_forest.txt <(gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard.vrt  < $EU/eu_x_y_forest.txt) | awk 'ORS=NR%6?FS:RS' )
# rm -f $EU/eu_x_y.gpkg
# pkascii2ogr -f GPKG -a_srs EPSG:4326   -i $EU/eu_x_y.txt   -o $EU/eu_x_y.gpkg

# echo start the transfer 

# ssh transfer "
# rclone copy  remote:dataproces_old/GLAD_ARD/data/47N/006E_47N/006E_47N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/47N/007E_47N/007E_47N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/47N/008E_47N/008E_47N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/47N/009E_47N/009E_47N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/48N/006E_48N/006E_48N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/48N/007E_48N/007E_48N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/48N/008E_48N/008E_48N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/48N/009E_48N/009E_48N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/49N/006E_49N/006E_49N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/49N/007E_49N/007E_49N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/49N/008E_49N/008E_49N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/49N/009E_49N/009E_49N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/50N/006E_50N/006E_50N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/50N/007E_50N/007E_50N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/50N/008E_50N/008E_50N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# rclone copy  remote:dataproces_old/GLAD_ARD/data/50N/009E_50N/009E_50N_med.tif /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
# "
GLAD=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/glad_ard
gdalbuildvrt -overwrite $GLAD/glad_ard.vrt $GLAD/*_med.tif
gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9  $GLAD/glad_ard.vrt  $GLAD/glad_ard.tif

# GFC=/gpfs/gibbs/pi/hydro/hydro/dataproces/GFC
# gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9  $GFC/treecover2000/all_tif.vrt  $EU/treecover2000/treecover.tif


## GSHL
GSHL=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSHL/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10
# wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S2comp2018_GLOBE_R2020A/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10/V1-0/32U_PROB.tif
# wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S2comp2018_GLOBE_R2020A/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10/V1-0/33U_PROB.tif
# wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S2comp2018_GLOBE_R2020A/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10/V1-0/32T_PROB.tif
# wget https://cidportal.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S2comp2018_GLOBE_R2020A/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10/V1-0/33T_PROB.tif

BU=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSHL/GHS_BUILT_S2comp2018_GLOBE_R2020A_UTM_10

export GDAL_CACHEMAX=8000
# gdalwarp -t_srs  EPSG:32632 -co COMPRESS=DEFLATE -co ZLEVEL=9  $BU/33U_PROB.tif  $BU/33U_PROB_to32.tif   -overwrite
# gdalwarp -t_srs  EPSG:32632 -co COMPRESS=DEFLATE -co ZLEVEL=9  $BU/33T_PROB.tif  $BU/33T_PROB_to32.tif   -overwrite

# gdalbuildvrt -overwrite $BU/BU_prob.vrt $BU/33T_PROB_to32.tif  $BU/33U_PROB_to32.tif $BU/32T_PROB.tif $BU/32U_PROB.tif  
# gdalwarp -overwrite  -t_srs   EPSG:4326  -te 6 47 10 51 -tr 0.00008333333333 0.00008333333333   -co COMPRESS=DEFLATE -co ZLEVEL=9 $BU/BU_prob.vrt  $BUS/ghs_built_S2comp2018_prob.tif 

## https://ghsl.jrc.ec.europa.eu/ghs_bu2019.php

# 0 = no data
# 1 = water surface
# 2 = land no built-up in any epoch
# 3 = built-up from 2000 to 2014 epochs
# 4 = built-up from 1990 to 2000 epochs
# 5 = built-up from 1975 to 1990 epochs
# 6 = built-up up to 1975 epoch
gdalwarp -overwrite  -t_srs   EPSG:4326  -te 6 47 10 51 -tr 0.000250000000000 0.000250000000000  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
/gpfs/gibbs/pi/hydro/hydro/dataproces/GSHL/GHS_BUILT_LDSMT_GLOBE_R2018A_3857_30/GHS_BUILT_LDSMT_GLOBE_R2018A_3857_30_V2_0_14_7.tif $BUS/ghs_built_LDSMT_epoc.tif

exit 


MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT/geomorphometry_90m_wgs84

for TOPO in geom aspect aspect-sine cti dev-scale dxx dy eastness pcurv roughness slope tcurv tri aspect-cosine convergence dev-magnitude dx dxy dyy elev-stdev northness rough-magnitude rough-scale spi tpi vrm ; do 
    gdalbuildvrt -overwrite $MERIT/${TOPO}/all_${TOPO}_90M.vrt $MERIT/${TOPO}/${TOPO}_90M_???????.tif 
    gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $MERIT/${TOPO}/all_${TOPO}_90M.vrt $EU/geomorpho90m/${TOPO}.tif 
done 

HYDRO=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0

for HYDROD in   flow.index  r.stream.channel  r.stream.distance  r.stream.order  r.stream.slope  r.watershed  ; do 
for DIR in $(ls $HYDRO/$HYDROD ) ; do 
    gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $HYDRO/$HYDROD/$DIR/$(basename $DIR _tiles20d).vrt $EU/hydrography90m/$(basename $DIR _tiles20d).tif 
done 
done 

CHELSA=/gpfs/gibbs/pi/hydro/hydro/dataproces/CHELSA/climatologies/bio

for CHELSAD  in $CHELSA/CHELSA_bio*_1981-2010_V.2.1.tif  ; do
    filename=$(basename $CHELSAD _1981-2010_V.2.1.tif )
    gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $CHELSAD  $EU/chelsa/${filename}.tif
done

SOILT=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILTEMP/input

for SOIL  in $SOILT/*.tif  ; do
     filename=$(basename  $SOIL .tif)
     gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $EU/soiltemp/${filename}.tif
done

SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS

for SOIL in $(ls $SOILGRIDS/*/*_WeigAver.tif | grep  -e _acc  )  ; do
     filename=$(basename  $SOIL  .tif)
     gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $EU/soilgrids/${filename}_acc.tif
done


for SOIL in $(ls $SOILGRIDS/*/*_WeigAver.tif |  grep -v  -e _acc -e out_  )  ; do
     filename=$(basename  $SOIL  .tif)
     gdal_translate -projwin 6 51 10 47 -co COMPRESS=DEFLATE -co ZLEVEL=9   $SOIL  $EU/soilgrids/${filename}.tif
done

