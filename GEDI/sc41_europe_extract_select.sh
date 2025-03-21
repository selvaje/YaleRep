#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc41_europe_extract_select.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc41_europe_extract_select.sh.%J.err
#SBATCH --job-name=sc41_europe_extract_select.sh
#SBATCH --mem=5G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc41_europe_extract_select.sh

source ~/bin/gdal3
source ~/bin/pktools

export EU=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe

# gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_all_tif.vrt  < $EU/txt/eu_x_y_forest.txt | awk 'ORS=NR%6?FS:RS' > $EU/txt/eu_x_y_forest_glad_ard_sel.txt

gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_SVVI_min.tif  < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_glad_ard_SVVI_min.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_SVVI_med.tif  < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_glad_ard_SVVI_med.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_SVVI_max.tif  < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_glad_ard_SVVI_max.txt

gdallocationinfo -geoloc -wgs84 -valonly $EU/treecover2000/treecover.tif              < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_treecover.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/Forest_height/Forest_height_2019.tif     < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_forest_height.txt

# chelsa 
# # BIO 18 Precipitation of Warmest Quarter (mm)
# # BIO 04 Temperature Seasonality (standard deviation * 100)

gdallocationinfo -geoloc -wgs84 -valonly $EU/chelsa/CHELSA_bio18.tif  < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_chelsa_CHELSA_bio18.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/chelsa/CHELSA_bio4.tif   < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_chelsa_CHELSA_bio4.txt

# geomorpho
# dev.magnitude
# convergence
# northness 
# eastness
# elevation

gdallocationinfo -geoloc -wgs84 -valonly $EU/geomorpho90m/dev-magnitude.tif  < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_geomorpho90m_dev-magnitude.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/geomorpho90m/convergence.tif    < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_geomorpho90m_convergence.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/geomorpho90m/northness.tif      < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_geomorpho90m_northness.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/geomorpho90m/eastness.tif      < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_geomorpho90m_eastness.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/geomorpho90m/elev.tif           < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_geomorpho90m_elevation.txt
 
# hydrography90m
# outlet_dist_dw_basin
# cti 

gdallocationinfo -geoloc -wgs84 -valonly $EU/hydrography90m/outlet_dist_dw_basin.tif    < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_hydrography90m_outlet_dist_dw_basin.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/hydrography90m/cti.tif                     < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_hydrography90m_cti.txt

# soilgrids
## BLDFIE_WeigAver    BLDFIE : Bulk density (fine earth) in kg / cubic-meter at depth 
## ORCDRC_WeigAver    ORCDRC : Soil organic carbon content (fine earth fraction) in g per kg at depth
## CECSOL_WeigAver    CECSOL : Cation exchange capacity of soil in cmolc/kg at depth

gdallocationinfo -geoloc -wgs84 -valonly $EU/soilgrids/BLDFIE_WeigAver.tif    < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_soilgrids_BLDFIE_WeigAver.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/soilgrids/ORCDRC_WeigAver.tif    < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_soilgrids_ORCDRC_WeigAver.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/soilgrids/CECSOL_WeigAver.tif    < $EU/txt/eu_x_y_forest.txt  > $EU/txt/eu_x_y_forest_soilgrids_CECSOL_WeigAver.txt

# soiltemp
# "SBIO4_Temperature_Seasonality_5_15cm"
# "SBIO3_Isothermality_5_15cm"

gdallocationinfo -geoloc -wgs84 -valonly $EU/soiltemp/SBIO4_Temperature_Seasonality_5_15cm.tif  < $EU/txt/eu_x_y_forest.txt > $EU/txt/eu_x_y_forest_soiltemp_SBIO4_Temperature_Seasonality_5_15cm.txt
gdallocationinfo -geoloc -wgs84 -valonly $EU/soiltemp/SBIO3_Isothermality_5_15cm.tif  < $EU/txt/eu_x_y_forest.txt > $EU/txt/eu_x_y_forest_soiltemp_SBIO3_Isothermality_5_15cm.txt

echo "x y h minSVVI medSVVI maxSVVI treecover forest_height CHELSA_bio18 CHELSA_bio4 dev-magnitude convergence northness eastness elevation outlet_dist_dw_basin cti BLDFIE ORCDRC CECSOL SBIO4 SBIO3" > $EU/txt/eu_x_y_hight_predictors_select.txt

paste -d " " $EU/txt/eu_x_y_hight_forest.txt $EU/txt/eu_x_y_forest_glad_ard_SVVI_min.txt $EU/txt/eu_x_y_forest_glad_ard_SVVI_med.txt $EU/txt/eu_x_y_forest_glad_ard_SVVI_max.txt \
             $EU/txt/eu_x_y_forest_treecover.txt $EU/txt/eu_x_y_forest_forest_height.txt \
             $EU/txt/eu_x_y_forest_chelsa_CHELSA_bio18.txt $EU/txt/eu_x_y_forest_chelsa_CHELSA_bio4.txt \
             $EU/txt/eu_x_y_forest_geomorpho90m_dev-magnitude.txt $EU/txt/eu_x_y_forest_geomorpho90m_convergence.txt \
             $EU/txt/eu_x_y_forest_geomorpho90m_northness.txt  $EU/txt/eu_x_y_forest_geomorpho90m_eastness.txt $EU/txt/eu_x_y_forest_geomorpho90m_elevation.txt \
             $EU/txt/eu_x_y_forest_hydrography90m_outlet_dist_dw_basin.txt  $EU/txt/eu_x_y_forest_hydrography90m_cti.txt \
             $EU/txt/eu_x_y_forest_soilgrids_BLDFIE_WeigAver.txt $EU/txt/eu_x_y_forest_soilgrids_ORCDRC_WeigAver.txt $EU/txt/eu_x_y_forest_soilgrids_CECSOL_WeigAver.txt \
             $EU/txt/eu_x_y_forest_soiltemp_SBIO4_Temperature_Seasonality_5_15cm.txt $EU/txt/eu_x_y_forest_soiltemp_SBIO3_Isothermality_5_15cm.txt \
             >> $EU/txt/eu_x_y_hight_predictors_select.txt
awk '{ print $1="", $2="", $0  }' $EU/txt/eu_x_y_hight_predictors_select.txt  |  sed  's,    ,,g'  > $EU/txt/eu_x_y_hight_predictors_select4R.txt

exit 

