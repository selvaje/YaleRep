#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 3 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc55_SE_data_prep_GEDIV2.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc55_SE_data_prep_GEDIV2.sh.%J.err
#SBATCH --job-name=sc55_SE_data_prep_GEDIV2.sh
#SBATCH --mem=20G

## sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc55_SE_data_prep_GEDIV2.sh

source ~/bin/gdal3
source ~/bin/pktools

export SE=/vast/palmer/home.grace/ga254/SE_data/exercise/tree_height
export EU=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe

# geomorpho90m
# # dev.magnitude
# # convergence
# # northness 
# # eastness
# # elev

# pkstatprofile -f min -co COMPRESS=DEFLATE -co ZLEVEL=9 -of GTiff  -i $EU/glad_ard/glad_ard_min.vrt -o $EU/glad_ard/glad_ard_min_min.tif
# pkstatprofile -f min -co COMPRESS=DEFLATE -co ZLEVEL=9 -of GTiff  -i $EU/glad_ard/glad_ard_med.vrt -o $EU/glad_ard/glad_ard_med_min.tif
# pkstatprofile -f min -co COMPRESS=DEFLATE -co ZLEVEL=9 -of GTiff  -i $EU/glad_ard/glad_ard_max.vrt -o $EU/glad_ard/glad_ard_max_min.tif

# gdalbuildvrt -separate -overwrite $EU/glad_ard/glad_ard_all_min.vrt  $EU/glad_ard/glad_ard_min_min.tif $EU/glad_ard/glad_ard_med_min.tif $EU/glad_ard/glad_ard_max_min.tif

# pkstatprofile -f min -co COMPRESS=DEFLATE -co ZLEVEL=9 -of GTiff  -i $EU/glad_ard/glad_ard_all_min.vrt  -o $EU/glad_ard/glad_ard_all_min.tif 
# rm -f $EU/glad_ard/glad_ard_min_min.tif $EU/glad_ard/glad_ard_med_min.tif $EU/glad_ard/glad_ard_max_min.tif 

# pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  -min  -0.5 -max 0.5  -data 0 -nodata 1    -i $EU/glad_ard/glad_ard_all_min.tif   -o $EU/glad_ard/glad_ard_all_min_msk.tif 
# gdal_edit.py -a_nodata 0 $EU/glad_ard/glad_ard_all_min_msk.tif 

# pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 65534.5 -max 65535.5 -data 0 -nodata 1 -i $EU/soilgrids/BLDFIE_WeigAver.tif -o  $EU/soilgrids/BLDFIE_WeigAver_msk.tif 
# pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 65534.5 -max 65535.5 -data 0 -nodata 1 -i $EU/soilgrids/ORCDRC_WeigAver.tif -o  $EU/soilgrids/ORCDRC_WeigAver_msk.tif  
# pkgetmask -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  -min 65534.5 -max 65535.5 -data 0 -nodata 1 -i $EU/soilgrids/CECSOL_WeigAver.tif -o  $EU/soilgrids/CECSOL_WeigAver_msk.tif

# gdalbuildvrt -separate -overwrite  $EU/soilgrids/CECSOL.vrt $EU/soilgrids/CECSOL_WeigAver_msk.tif $EU/soilgrids/ORCDRC_WeigAver_msk.tif $EU/soilgrids/BLDFIE_WeigAver_msk.tif 
# pkstatprofile -f min -co COMPRESS=DEFLATE -co ZLEVEL=9 -of GTiff  -i  $EU/soilgrids/CECSOL.vrt  $EU/soilgrids/soilgrids_msk.tif 
# rm $EU/soilgrids/CECSOL.vrt 

# gdal_translate -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9  -tr 0.000250000000000 0.000250000000000 $EU/Forest_height/Forest_height_2019.tif $SE/geodata_raster/forestheight_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/forestheight_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/forestheight_r.tif
 
# gdal_translate -ot Byte -a_nodata 255 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000 $EU/treecover2000/treecover.tif $SE/geodata_raster/treecover_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/treecover_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/treecover_r.tif

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata 255 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata 255 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata 255 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata 255 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata 255 \
# -m  $SE/geodata_raster/forestheight_r.tif     -msknodata 100 -p ">"  -nodata 255 \
# -i  $SE/geodata_raster/forestheight_r.tif  -o  $SE/geodata_raster/forestheight.tif

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata 255 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata 255 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata 255 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata 255 \
# -m  $SE/geodata_raster/forestheight_r.tif     -msknodata 100 -p ">"  -nodata 255 \
# -m  $SE/geodata_raster/treecover_r.tif        -msknodata 0 -p =  -nodata 255 \
# -i  $SE/geodata_raster/treecover_r.tif        -o  $SE/geodata_raster/treecover.tif

# source ~/bin/grass78m

# cp $SE/geodata_raster/treecover.tif  /tmp/treecover.tif
# grass78  -f -text --tmp-location  -c /tmp/treecover.tif   <<'EOF'

# r.external  input=/tmp/treecover.tif   output=treecover    --overwrite 

# r.latlong    input=treecover output=latitude 
# r.latlong -l input=treecover output=longitude

# r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32  format=GTiff  nodata=-9999  input=latitude   output=$SE/geodata_raster/latitude_tmp.tif 
# r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float32  format=GTiff  nodata=-9999  input=longitude  output=$SE/geodata_raster/longitude_tmp.tif 
# EOF

# rm /tmp/treecover.tif

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i  $SE/geodata_raster/latitude_tmp.tif      -o  $SE/geodata_raster/latitude.tif 

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i  $SE/geodata_raster/longitude_tmp.tif    -o  $SE/geodata_raster/longitude.tif


# echo dev-magnitude convergence northness eastness elev | xargs -n 1 -P 2 bash -c $'
# file=$1
# gdal_translate -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000  $EU/geomorpho90m/$file.tif   $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0   -p = -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0   -p = -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0   -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2   -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i   $SE/geodata_raster/${file}_r.tif      -o  $SE/geodata_raster/$file.tif
# ' _

# echo min med max | xargs -n 1 -P 3 bash -c $'
# var=$1
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $EU/glad_ard/glad_ard_SVVI_$var.tif
# gdal_edit.py -a_ullr 6 50 10 47 $EU/glad_ard/glad_ard_SVVI_$var.tif    
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i  $EU/glad_ard/glad_ard_SVVI_$var.tif       -o  $SE/geodata_raster/glad_ard_SVVI_${var}.tif
# ' _

# # chelsa 
# # # BIO 18 Precipitation of Warmest Quarter (mm)
# # # BIO 04 Temperature Seasonality (standard deviation * 100)

# echo CHELSA_bio4 CHELSA_bio18 | xargs -n 1 -P 2 bash -c $'
# file=$1
# gdal_translate -ot UInt16 -a_nodata 65535  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000 $EU/chelsa/$file.tif   $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p = -nodata 65535 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p = -nodata 65535 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata 65535 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata 65535 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata 65535 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata 65535 \
# -i  $SE/geodata_raster/${file}_r.tif          -o $SE/geodata_raster/$file.tif
# ' _

# # hydrography90m
# # outlet_dist_dw_basin
# # cti 


# file=outlet_dist_dw_basin
# gdal_translate -ot Int32 -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000 $EU/hydrography90m/$file.tif $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p = -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p = -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i  $SE/geodata_raster/${file}_r.tif            -o  $SE/geodata_raster/$file.tif 

# file=cti
# gdal_translate -ot Int32 -a_nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000 $EU/hydrography90m/$file.tif $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif

# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata -2147483648 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata -2147483648 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -2147483648 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -2147483648 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -2147483648 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -2147483648 \
# -i  $SE/geodata_raster/${file}_r.tif              -o  $SE/geodata_raster/$file.tif 

# # soilgrids
# ## BLDFIE_WeigAver    BLDFIE : Bulk density (fine earth) in kg / cubic-meter at depth 
# ## ORCDRC_WeigAver    ORCDRC : Soil organic carbon content (fine earth fraction) in g per kg at depth
# ## CECSOL_WeigAver    CECSOL : Cation exchange capacity of soil in cmolc/kg at depth

# echo BLDFIE_WeigAver ORCDRC_WeigAver CECSOL_WeigAver |  xargs -n 1 -P 2 bash -c $'
# file=$1
# gdal_translate -ot UInt16 -a_nodata 65535  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000  $EU/soilgrids/$file.tif $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata 65535 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata 65535 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata 65535 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata 65535 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata 65535 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata 65535 \
# -i  $SE/geodata_raster/${file}_r.tif          -o  $SE/geodata_raster/$file.tif 
# ' _

# # soiltemp
# # SBIO4_Temperature_Seasonality_5_15cm
# # SBIO3_Isothermality_5_15cm

# echo SBIO4_Temperature_Seasonality_5_15cm SBIO3_Isothermality_5_15cm |  xargs -n 1 -P 2 bash -c $'
# file=$1
# gdal_translate -ot Float32 -a_nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000  $EU/soiltemp/$file.tif   $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -tr 0.0002500000000000000000000 -0.0002500000000000000000000 $SE/geodata_raster/${file}_r.tif
# gdal_edit.py -a_ullr 6 50 10 47 $SE/geodata_raster/${file}_r.tif
# pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# -m  $EU/soilgrids/soilgrids_msk.tif           -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/soiltemp/soiltmp_msk.tif              -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/glad_ard/glad_ard_all_min_msk.tif     -msknodata 0 -p =  -nodata -9999 \
# -m  $EU/ghs_built/ghs_built_LDSMT_epoc.tif    -msknodata 2 -p !  -nodata -9999 \
# -m  $SE/geodata_raster/treecover.tif          -msknodata 255 -p =  -nodata -9999 \
# -m  $SE/geodata_raster/forestheight.tif       -msknodata 255 -p =  -nodata -9999 \
# -i  $SE/geodata_raster/${file}_r.tif         -o $SE/geodata_raster/$file.tif 
# ' _


# remove some northen part of the tif. 
for file in $SE/geodata_raster/*.tif ; do 
gdal_translate -projwin 6 50 10 47.9  -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.000250000000000 0.000250000000000  $file $file.tif 
mv $file.tif  $file
done 





exit 




awk '{ print $2, $1  }' $EU/txt/eu_y_x_height_6algorithms_fullTable.txt > $EU/txt/eu_x_y_from6algorithms_fullTable.txt

rm $SE/geodata_raster/*_r.tif
cd $SE/geodata_raster
for file in *.tif ; do 
gdallocationinfo -geoloc -valonly $file < $EU/txt/eu_x_y_from6algorithms_fullTable.txt   >   $SE/txt/$file.txt 
done

paste -d " " $EU/txt/eu_x_y_from6algorithms_fullTable.txt  $SE/txt/*.tif.txt > $SE/txt/eu_x_y_from6algorithms_fullTable_predictors.txt
rm $SE/txt/*.tif.txt  

grep -v -e  " \-9999 " -e  " \-2147483648 " -e " 65535 " -e " 255 " $SE/txt/eu_x_y_from6algorithms_fullTable_predictors.txt  > $SE/txt/eu_x_y_predictors_select_tmp.txt

echo "ID X Y BLDFIE_WeigAver CECSOL_WeigAver CHELSA_bio18 CHELSA_bio4 convergence cti dev-magnitude eastness elev forestheight glad_ard_SVVI_max glad_ard_SVVI_med glad_ard_SVVI_min northness ORCDRC_WeigAver outlet_dist_dw_basin SBIO3_Isothermality_5_15cm SBIO4_Temperature_Seasonality_5_15cm treecover" >  $SE/txt/eu_x_y_predictors_select.txt

awk '{ print $1"_"$2, $0}' $SE/txt/eu_x_y_predictors_select_tmp.txt | sort -k 1,1 | awk '{print NR,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23}' >> $SE/txt/eu_x_y_predictors_select.txt
rm  $SE/txt/eu_x_y_predictors_select_tmp.txt

rm $SE/txt/eu_x_y_from6algorithms_fullTable_predictors.txt
awk '{ if (NR>1) {print $2 , $3}}' $SE/txt/eu_x_y_predictors_select.txt > $SE/txt/eu_x_y_select.txt

join -1 1 -2 1 <(awk '{print $1 "_" $2}' $SE/txt/eu_x_y_select.txt | sort -k 1,1) \
               <(awk '{print $2 "_" $1, $0}' $EU/txt/eu_y_x_height_6algorithms_fullTable.txt | sort -k 1,1) >  $SE/txt/eu_y_x_select_6algorithms_fullTable_tmp.txt

echo "ID X Y a1_95 a2_95 a3_95 a4_95 a5_95 a6_95 min_rh_95 max_rh_95 BEAM digital_elev elev_low qc_a1 qc_a2 qc_a3 qc_a4 qc_a5 qc_a6 se_a1 se_a2 se_a3 se_a4 se_a5 se_a6 deg_fg solar_ele" >  $SE/txt/eu_y_x_select_6algorithms_fullTable.txt
awk '{print NR,  $3,$2,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28}' $SE/txt/eu_y_x_select_6algorithms_fullTable_tmp.txt >>  $SE/txt/eu_y_x_select_6algorithms_fullTable.txt

rm $SE/txt/eu_y_x_select_6algorithms_fullTable_tmp.txt

# recreate select  with the same order
awk '{ if (NR>1) {print $2 , $3}}'   $SE/txt/eu_y_x_select_6algorithms_fullTable.txt  > $EU/txt/eu_x_y_select.txt

echo "ID X Y h" > $SE/txt/eu_x_y_height_select.txt
awk '{ if (NR>1) {print $1, $2 , $3 , ($4 + $5 + $6 +  $7 + $8 + $9 - $10 - $11 )/4 }}' $SE/txt/eu_y_x_select_6algorithms_fullTable.txt  >> $SE/txt/eu_x_y_height_select.txt


paste -d " " $SE/txt/eu_x_y_height_select.txt  $SE/txt/eu_x_y_predictors_select.txt | awk '{print $1,$2,$3,$4,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26}'  > $SE/txt/eu_x_y_height_predictors_select.txt

rm -f $SE/geodata_vector/eu_x_y_height.gpkg
awk '{if (NR>1 ) {print $2 ,  $3 , $1, $3}}'      $SE/txt/eu_x_y_height_select.txt  > /tmp/eu_x_y_height.txt
pkascii2ogr -f GPKG -a_srs EPSG:4326 -n "ID" -ot Integer   -n "height" -ot Real  -i /tmp/eu_x_y_height.txt    -o $SE/geodata_vector/eu_x_y_height_select.gpkg
rm /tmp/eu_x_y_height.txt 





exit 

# cp /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/eu_y_x_forest_6algorithms_fullTable.txt  /vast/palmer/home.grace/ga254/SE_data/exercise/tree_height/txt/
# cp /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/eu_x_y_predictors_select.txt             /vast/palmer/home.grace/ga254/SE_data/exercise/tree_height/txt/
# cp /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/eu_x_y_height_forest.txt                 /vast/palmer/home.grace/ga254/SE_data/exercise/tree_height/txt/
# cp /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/eu_x_y_forest.txt                        /vast/palmer/home.grace/ga254/SE_data/exercise/tree_height/txt/






paste -d " " $EU/txt/eu_x_y.txt <(gdallocationinfo -geoloc -wgs84 -valonly $EU/treecover2000/treecover.tif         <  $EU/txt/eu_x_y.txt) \
                                      <(gdallocationinfo -geoloc -wgs84 -valonly $EU/ghs_built/ghs_built_LDSMT_epoc.tif  <  $EU/txt/eu_x_y.txt) \
                                      <(gdallocationinfo -geoloc -wgs84 -valonly $EU/soilgrids/soilgrids_msk.tif         <  $EU/txt/eu_x_y.txt) \
                                      <(gdallocationinfo -geoloc -wgs84 -valonly $EU/soiltemp/soiltmp_msk.tif            <  $EU/txt/eu_x_y.txt) \
 <(gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_min.vrt  < $EU/txt/eu_x_y.txt | awk 'ORS=NR%6?FS:RS') \
 <(gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_med.vrt  < $EU/txt/eu_x_y.txt | awk 'ORS=NR%6?FS:RS') \
 <(gdallocationinfo -geoloc -wgs84 -valonly $EU/glad_ard/glad_ard_max.vrt  < $EU/txt/eu_x_y.txt | awk 'ORS=NR%6?FS:RS') \
                                   | awk '{ if ( $3!=0 && $4==2 && $5==1 && $6==1 && $7!=0 && $8!=0 && $9!=0 && $10!=0 && $11!=0 && $12!=0 && $13!=0 && $14!=0 && $15!=0 && $16!=0 && $17!=0 && $18!=0 && $19!=0 && $20!=0 && $21!=0 && $22!=0 && $23!=0 && $24!=0 ) print $1 , $2 }'  > $EU/txt/eu_x_y_forest.txt

join -1 1 -2 1 <( awk '{ print $1"_"$2  }' $EU/txt/eu_x_y_forest.txt | sort -k 1,1  ) <( awk '{ print $2"_"$1, $0  }' $EU/txt/eu_y_x_height_6algorithms_fullTable.txt  | sort -k 1,1 ) >  $EU/txt/eu_y_x_forest_6algorithms_fullTable_tmp.txt

echo "X Y a1_95 a2_95 a3_95 a4_95 a5_95 a6_95 min_rh_95 max_rh_95 BEAM digital_elev elev_low qc_a1 qc_a2 qc_a3 qc_a4 qc_a5 qc_a6 se_a1 se_a2 se_a3 se_a4 se_a5 se_a6 deg_fg solar_ele" >  $EU/txt/eu_y_x_forest_6algorithms_fullTable.txt 
awk '{print $3,$2,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28}' $EU/txt/eu_y_x_forest_6algorithms_fullTable_tmp.txt >>  $EU/txt/eu_y_x_forest_6algorithms_fullTable.txt 
rm $EU/txt/eu_y_x_forest_6algorithms_fullTable_tmp.txt $EU/txt/eu_x_y.txt $EU/txt/eu_x_y_forest.txt






