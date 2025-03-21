#!/bin/bash

#So Jaime this is the script for the proxilimity /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc42_compUnit_stream_distance.sh  . see last few lines "after #### stream euclidian distance " . it is build for working on our computational unit so probably not good for Leen dataset. So just get the lines and do it for Leenn dataset . Probably it should be able to run without tailing... will take a day probably... but maybe less. If you do it in tiles you have to be sure to enlarge (e.g. 1 degree ) the tails and then cat back . Here the other scritpts that combine the comp unit river-distance in tiled river distance... but probablu you will not need.

#ok perfect just enlarge it... pointing to a vrt. see....  sc46_compUnit_stream_distance_tile20d.sh:     

#gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -projwin $(getCorners4Gtranslate $file | awk  '{print $1-1, $2+1, $3+1, $4-1}') $SCMH/stream_tiles_final20d_1p/all_stream_dis.vrt $RAM/priox_${tile}.tif


###########--------------------------------------------------------------------
###########--------------------------------------------------------------------

#gdal3
#pktools
#grass78m

#export DIR=/home/jg2657/project/stre_val
#export TMP=/home/jg2657/scratch60/stre_val

export DIR=/data/marquez/stre_val
mkdir /dev/shm/val
export TMP=/dev/shm/val
export hdpTiles=$DIR/hdpTiles  ## mkdir $DIR/hdpTiles   

###    Make the NHDP tiles
#  NHDplus
#e#xport fold=( $(echo /mnt/shared/stream_validation/NHDplus/shp/*/) )
##
#f#or file in ${fold[@]}
#d#o
#e#xport file
###export file=${fold[0]}
##
#g#dal_rasterize -a diss -l NHDFlowline -a_nodata 0  -ot 'Byte' \
# #       -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4269 \
# #       ${file}NHDFlowline.shp $TMP/$(basename $file /).tif
##
#g#dalwarp -s_srs EPSG:4269 -t_srs EPSG:4326 \
# #       -tr 0.000833333333333 -0.000833333333333 \
# #       -co COMPRESS=DEFLATE -co ZLEVEL=9 \
# #           $TMP/$(basename $file /).tif $hdpTiles/$(basename $file /)_WGS84.tif 
#d#one    
##
### remove temporal files
#r#m $TMP/*$(basename $file /)* 


#m#kdir $DIR/hdpMasked
##
#e#xport fold=( $(find /mnt/shared/stream_validation/NHDplus/tif/ -name "NHDPlus*") )
##
#f#or file in ${fold[@]}
#d#o
# #   export file
# #   
# #   pkfilter -i $file -d 41 -dx 41 -dy 41  -f sum \
# #       -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# #       -o $TMP/$(basename $file .tif)_sum41.tif
##
# #   pksetmask -i $file -m  $TMP/$(basename $file .tif)_sum41.tif \
# #       -o $TMP/$(basename $file .tif)_mask.tif  \
# #       -co COMPRESS=DEFLATE -co ZLEVEL=9  \
# #       --operator='<' -msknodata 70 -nodata 0
##
# #   gdalwarp -t_srs EPSG:4326 \
# #       -tr 0.000833333333333 -0.000833333333333 \
# #       -co COMPRESS=DEFLATE -co ZLEVEL=9 \
# #       $TMP/$(basename $file .tif)_mask.tif \
# #       $DIR/hdpMasked/$(basename $file .tif)_WGS84.tif
#d#one
##
### remove temporal files
#r#m $TMP/*$(basename $file .tif)* 


####
####   Download new NHDPlus hd
####   all download sources available in data.txt format
### initialy copied in server 1 /mnt/shared/NHDPhd
for file in $(cat data.txt);
do
    wget $file
done

mkdir /data/marquez/NHDP
export TMP=/data/marquez/NHDP

zipfiles=( $(find /mnt/shared/NHDPhd -name '*GDB.zip')  )

#file=${zipfiles[0]}

nhdpPrep(){

file=$1

unzip $file -d $TMP

gdal_rasterize -a FCode -l NHDFlowline -a_nodata 0  -ot 'UInt16' \
    -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4269 \
    -co COMPRESS=DEFLATE -co ZLEVEL=9 \
    $TMP/$(basename $file .zip).gdb $TMP/$(basename $file .zip)_NAD83.tif

gdalwarp -s_srs EPSG:4269 -t_srs EPSG:4326 \
    -tr 0.000833333333333 -0.000833333333333 \
    -co COMPRESS=DEFLATE -co ZLEVEL=9 \
    $TMP/$(basename $file .zip)_NAD83.tif $TMP/$(basename $file .zip)_WGS84.tif

rm  $TMP/$(basename $file .zip)_NAD83.tif 
rm -rf $TMP/$(basename $file .zip).{jpg,gdb,xml}

}

export -f nhdpPrep
time parallel -j 5 nhdpPrep ::: ${zipfiles[@]}


scp /data/marquez/NHDP/* server2:/data/marquez/stre_val/hdpTiles

#https://nhd.usgs.gov/userGuide/Robohelpfiles/NHD_User_Guide/Feature_Catalog/Hydrography_Dataset/Complete_FCode_List.htm
#FCode = 46000 46003 46006 46007
echo "46000 46003 46006 46007 = 1
    * = NULL" > $DIR/streamsNHDP.txt


    
#############################################################
###### Amatulli, et al  PREPARATION   ########################
##############################################################


export FILES=( $(find /mnt/shared/data_from_yale/MERIT_HYDRO/stream_tiles_final20d_1p -name '*.tif' ! -name '*_ovr*' ! -name 'maiduguri_*' ! -name 'lagos_*') )
## create vrt global extensio
gdalbuildvrt -overwrite $DIR/OURstream.vrt $(echo ${FILES[@]}) 
export GLOBSTREAM=$DIR/OURstream.vrt

# mkdir $DIR/tables_Giuse
export OUT=$DIR/tables_Giuse

#  NHDplus
#export fold=( $(echo /mnt/shared/stream_validation/NHDplus/shp/*/) )
#export fold=( $(find $DIR/hdpMasked -name '*.tif')  )
export fold=(  $(find $DIR/hdpTiles -name '*.tif')  ) 
time for file in ${fold[@]}
do
export file
#export file=${fold[4]}

pkcrop -i $GLOBSTREAM \
        $(pkinfo -i $file -bb -dx -dy) \
        -o $TMP/stream_$(basename $file .tif).vrt

grass78 -f -text --tmp-location -c $file <<'EOF'

r.in.gdal --o input=$file output=nhdp_orig
r.reclass --o input=nhdp_orig output=nhdp rules=$DIR/streamsNHDP.txt
r.in.gdal input=$TMP/stream_$(basename $file .tif).vrt output=stream
r.mapcalc "streamBin = if(stream > 1, 1, 0)"

# create buffers
r.buffer --o input=nhdp output=buff_nhdp distances=100,200,300,400
r.stats -a input=buff_nhdp | awk 'NR < 6 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_bufs.txt

r.mapcalc --o "strBin5 = if(buff_nhdp < 6, streamBin, 0)"
r.stats -a input=strBin5 | awk '$1 == 1 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_area.txt

#r.mapcalc --o "onlyS = if(strBin5 == 1, buff_nhdp, 0)"
#r.stats -a input=onlyS | awk 'NR > 1 && NR < 7  {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_onlyS.txt

> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt
$(for i in 1 2 3 4 5
do
   r.mapcalc --o "over_$i = if(buff_nhdp == $i, streamBin, 0)"
   r.stats -a input=over_$i | awk '$1 == 1 {print $2/1000000}' >> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt 
done)
EOF

# remove temporal files
rm $TMP/*$(basename $file .tif)* 
done

# remove tables that did not work (something wrong with the shp files)
#rm $DIR/tables_Giuse/NHDPlusV21_CO_14_NHDSnapshot_07_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_CO_15_NHDSnapshot_04_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_GB_16_NHDSnapshot_06_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_GL_04_NHDSnapshot_08_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_MA_02_NHDSnapshot_04_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_PI_22AS_NHDSnapshot_01_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_PI_22GU_NHDSnapshot_01_*.txt
#rm $DIR/tables_Giuse/NHDPlusV21_PI_22MP_NHDSnapshot_01_*.txt

area=( $(find $DIR/tables_Giuse -name '*_area.txt') )
export SS=$(paste -d' ' ${area[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j }')

tables=( $(find $DIR/tables_Giuse -name '*_bufs.txt')  )
# total number of km² in each buffer category in NHDP
#NHT=$(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }')

buffers=( $(find $DIR/tables_Giuse -name '*_bufsStream.txt')  )
# total number of km² in each buffer in Testing stream
#STT=$(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    | awk '{print $2/$1}'

paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' | awk -v D="$SS" '{print $1/D}'


paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    > $DIR/table_gius.txt #| awk '{print $2/$1}'

awk 'BEGIN{print "TotAreaBuf AreaStre Prop"}; {print $0, $2/$1}' $DIR/table_gius.txt \
    > $DIR/table_gius2.txt && mv $DIR/table_gius2.txt $DIR/table_gius.txt


##############################################################
######  Allen, et al   PREPARATION  ##########################
##############################################################

export ALLEN=/mnt/shared/stream_validation/Allen_GRWL_2020/GRWL_mask_V01.01
export FILES=( $(find $ALLEN -name 'N[G-M][09-21]*.tif') )

mkdir $DIR/allen_rast

echo ${FILES[@]} | xargs -P 10 -n 1 bash -c $'

pkreclass -i $1 -o $DIR/allen_rast/$(basename $1 .tif)_recl.tif  -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -c 255 -r 1 -c 180 -r 1 -c 126 -r 1 -c 86 -r 1 -c 0 -r 0

gdalwarp -t_srs EPSG:4326 -tr 0.000833333333333 -0.000833333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 $DIR/allen_rast/$(basename $1 .tif)_recl.tif $DIR/allen_rast/$(basename $1 .tif)_WGS84.tif

#rm $DIR/allen_rast/$(basename $1 .tif)_recl.tif
' _

gdalbuildvrt -overwrite $DIR/allen_rast.vrt $(find $DIR/allen_rast -name '*WGS84.tif')

export ALLENSTREAM=$DIR/allen_rast.vrt

#mkdir $DIR/tables_allen
export OUT=$DIR/tables_allen    

####  NHDplus
#export fold=( $(echo /mnt/shared/stream_validation/NHDplus/shp/*/) )
#export fold=( $(find $DIR/hdpMasked -name '*.tif')  )
export fold=(  $(find $DIR/hdpTiles -name '*.tif')  )

time for file in ${fold[@]}
do
export file
#export file=${fold[0]}

pkcrop -i $ALLENSTREAM \
        $(pkinfo -i $file -bb -dx -dy) \
        -o $TMP/stream_$(basename $file .tif).vrt


grass78 -f -text --tmp-location -c $file  <<'EOF'

r.in.gdal --o input=$file output=nhdp_orig
r.reclass --o input=nhdp_orig output=nhdp rules=$DIR/streamsNHDP.txt
r.in.gdal input=$TMP/stream_$(basename $file .tif).vrt output=stream

r.buffer --o input=nhdp output=buff_nhdp distances=100,200,300,400
r.stats -a input=buff_nhdp | awk 'NR < 6 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_bufs.txt

r.mapcalc --o "strBin5 = if(buff_nhdp < 6, stream, 0)"
r.stats -a input=strBin5 | awk '$1 == 1 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_area.txt

> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt
$(for i in 1 2 3 4 5 
do
   r.mapcalc --o "over_$i = if(buff_nhdp == $i, stream, 0)"
   r.stats -a input=over_$i | awk '$1 == 1 {print $2/1000000}' >> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt 
done)
EOF

# remove temporal files
rm $TMP/*$(basename $file .tif)* 
done

# remove tables that did not work (something wrong with the shp files)
#rm $DIR/tables_allen/NHDPlusV21_CO_14_NHDSnapshot_07_*.txt
#rm $DIR/tables_allen/NHDPlusV21_CO_15_NHDSnapshot_04_*.txt
#rm $DIR/tables_allen/NHDPlusV21_GB_16_NHDSnapshot_06_*.txt
#rm $DIR/tables_allen/NHDPlusV21_GL_04_NHDSnapshot_08_*.txt
#rm $DIR/tables_allen/NHDPlusV21_MA_02_NHDSnapshot_04_*.txt
#rm $DIR/tables_allen/NHDPlusV21_PI_22AS_NHDSnapshot_01_*.txt
#rm $DIR/tables_allen/NHDPlusV21_PI_22GU_NHDSnapshot_01_*.txt
#rm $DIR/tables_allen/NHDPlusV21_PI_22MP_NHDSnapshot_01_*.txt

area=( $(find $DIR/tables_allen -name '*_area.txt') )
export SS=$(paste -d' ' ${area[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j }')

tables=( $(find $DIR/tables_allen -name '*_bufs.txt')  )
# total number of km² in each buffer category in NHDP
#NHT=$(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

buffers=( $(find $DIR/tables_allen -name '*_bufsStream.txt')  )
# total number of km² in each buffer in Testing stream
#STT=$(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    | awk '{print $2/$1}'

paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' | awk -v D="$SS" '{print $1/D}'


paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    > $DIR/table_allen.txt #| awk '{print $2/$1}'

awk 'BEGIN{print "TotAreaBuf AreaStre Prop"}; {print $0, $2/$1}' $DIR/table_allen.txt \
    > $DIR/table_allen2.txt && mv $DIR/table_allen2.txt $DIR/table_allen.txt

#############################################################
###### Hydro RIvers   PREPARATION   ##########################
##############################################################


export STRE=/mnt/shared/stream_validation/HydroRIVERS_v10_shp

# add new column to attribute table with value 1 to use for rasterization
ogrinfo ${STRE}/HydroRIVERS_v10.dbf -sql "ALTER TABLE HydroRIVERS_v10 ADD COLUMN diss integer(1)"
ogrinfo ${STRE}/HydroRIVERS_v10.dbf -dialect SQLite -sql "UPDATE HydroRIVERS_v10 SET diss = 1"

#time gdal_rasterize -a diss -l HydroRIVERS_v10 -a_nodata 0 \
#    -ot 'Byte' $(pkinfo -i $TILE -te) \
#    -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4326 \
#    $STRE/HydroRIVERS_v10.shp $TMP/streamCut_$tn.tif

#mkdir $DIR/tables_Hydro
export OUT=$DIR/tables_Hydro

####  NHDplus
#export fold=( $(echo /mnt/shared/stream_validation/NHDplus/shp/*/) )
#export fold=( $(find $DIR/hdpMasked -name '*.tif')  )
export fold=(  $(find $DIR/hdpTiles -name '*.tif')  ) 

time for file in ${fold[@]}
do
export file
#export file=${fold[0]}

gdal_rasterize -a diss -l HydroRIVERS_v10 -a_nodata 0 -ot 'Byte' \
    $(pkinfo -i $file -te) \
    -co COMPRESS=DEFLATE -co ZLEVEL=9 \
    -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4326 \
    $STRE/HydroRIVERS_v10.shp $TMP/stream_$(basename $file .tif).vrt

grass78 -f -text --tmp-location -c $file  <<'EOF'

r.in.gdal --o input=$file output=nhdp_orig
r.reclass --o input=nhdp_orig output=nhdp rules=$DIR/streamsNHDP.txt
r.in.gdal input=$TMP/stream_$(basename $file .tif).vrt output=stream

r.buffer --o input=nhdp output=buff_nhdp distances=100,200,300,400
r.stats -a input=buff_nhdp | awk 'NR < 6 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_bufs.txt

r.mapcalc --o "strBin5 = if(buff_nhdp < 6, stream, 0)"
r.stats -a input=strBin5 | awk '$1 == 1 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_area.txt

> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt
$(for i in 1 2 3 4 5
do
   r.mapcalc --o "over_$i = if(buff_nhdp == $i, stream, 0)"
   r.stats -a input=over_$i | awk '$1 == 1 {print $2/1000000}' >> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt 
done)
EOF

# remove temporal files
rm $TMP/*$(basename $file .tif)* 
done

# remove tables that did not work (something wrong with the shp files)
#rm $DIR/tables_Hydro/NHDPlusV21_CO_14_NHDSnapshot_07_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_CO_15_NHDSnapshot_04_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_GB_16_NHDSnapshot_06_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_GL_04_NHDSnapshot_08_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_MA_02_NHDSnapshot_04_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_PI_22AS_NHDSnapshot_01_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_PI_22GU_NHDSnapshot_01_*.txt
#rm $DIR/tables_Hydro/NHDPlusV21_PI_22MP_NHDSnapshot_01_*.txt

area=( $(find $DIR/tables_Hydro -name '*_area.txt') )
export SS=$(paste -d' ' ${area[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j }')

tables=( $(find $DIR/tables_Hydro -name '*_bufs.txt')  )
# total number of km² in each buffer category in NHDP
#NHT=$(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

buffers=( $(find $DIR/tables_Hydro -name '*_bufsStream.txt')  )
# total number of km² in each buffer in Testing stream
#STT=$(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    | awk '{print $2/$1}'

paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' | awk -v D="$SS" '{print $1/D}'

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    > $DIR/table_hydro.txt #| awk '{print $2/$1}'

awk 'BEGIN{print "TotAreaBuf AreaStre Prop"}; {print $0, $2/$1}' $DIR/table_hydro.txt \
    > $DIR/table_hydro2.txt && mv $DIR/table_hydro2.txt $DIR/table_hydro.txt

###########################################################
###### Lin et al  PREPARATION  ############################
###########################################################


mkdir $DIR/LinRast
export STRE=/mnt/shared/stream_validation/Lin_SciData2021/river_network_variable_Dd
export Lins=( $(find $STRE -name '*.dbf') )

LinVal(){
export file=$1
# add new column to attribute table with value 1 to use for rasterization
#ogrinfo $file -sql "ALTER TABLE $(basename $file .dbf) ADD COLUMN diss integer(1)"
#ogrinfo $file -dialect SQLite -sql "UPDATE $(basename $file .dbf) SET diss = 1"

time gdal_rasterize -a diss -l $(basename $file .dbf) -a_nodata 0 \
    -ot 'Byte' \
    -tr 0.000833333333333 -0.000833333333333 -a_srs EPSG:4326 \
    -co COMPRESS=DEFLATE -co ZLEVEL=9 \
    $STRE/$(basename $file .dbf).shp $DIR/LinRast/Cut_$(basename $file .dbf).tif

}
export -f LinVal
time parallel -j 20 LinVal ::: ${Lins[@]}

export LR=( $(find $DIR/LinRast -name '*.tif') )
gdalbuildvrt -overwrite $DIR/LINstream.vrt $(echo ${LR[@]}) 

##--------------------

export GLOBLIN=$DIR/LINstream.vrt
#mkdir $DIR/tables_Lin
export OUT=$DIR/tables_Lin

####  NHDplus
#export fold=( $(echo /mnt/shared/stream_validation/NHDplus/shp/*/) )
#export fold=( $(find $DIR/hdpMasked -name '*.tif')  )
export fold=(  $(find $DIR/hdpTiles -name '*.tif')  ) 

time for file in ${fold[@]}
do
export file
#export file=${fold[3]}

pkcrop -i $GLOBLIN \
        $(pkinfo -i $file -bb -dx -dy) \
        -o $TMP/stream_$(basename $file .tif).vrt

grass78 -f -text --tmp-location -c $file  <<'EOF'

r.in.gdal --o input=$file output=nhdp_orig
r.reclass --o input=nhdp_orig output=nhdp rules=$DIR/streamsNHDP.txt
r.in.gdal input=$TMP/stream_$(basename $file .tif).vrt output=stream

r.buffer --o input=nhdp output=buff_nhdp distances=100,200,300,400
r.stats -a input=buff_nhdp | awk 'NR < 6 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_bufs.txt

r.mapcalc --o "strBin5 = if(buff_nhdp < 6, stream, 0)"
r.stats -a input=strBin5 | awk 'NR == 2 {print $2/1000000}' > $OUT/$(basename $file _WGS84.tif)_area.txt

> $OUT/$(basename $file  _WGS84.tif)_bufsStream.txt
$(for i in 1 2 3 4 5
do
   r.mapcalc --o "over_$i = if(buff_nhdp == $i, stream, 0)"
   r.stats -a input=over_$i | awk '$1 == 1 {print $2/1000000}' >> $OUT/$(basename $file _WGS84.tif)_bufsStream.txt 
done)
EOF

# remove temporal files
rm $TMP/*$(basename $file .tif)* 
done

# remove tables that did not work (something wrong with the shp files)
#rm $DIR/tables_Lin/NHDPlusV21_CO_14_NHDSnapshot_07_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_CO_15_NHDSnapshot_04_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_GB_16_NHDSnapshot_06_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_GL_04_NHDSnapshot_08_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_MA_02_NHDSnapshot_04_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_PI_22AS_NHDSnapshot_01_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_PI_22MP_NHDSnapshot_01_*.txt
#rm $DIR/tables_Lin/NHDPlusV21_PI_22GU_NHDSnapshot_01_*.txt

area=( $(find $DIR/tables_Lin -name '*_area.txt') )
export SS=$(paste -d' ' ${area[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j }')

tables=( $(find $DIR/tables_Lin -name '*_bufs.txt')  )
# total number of km² in each buffer category in NHDP
#NHT=$(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

buffers=( $(find $DIR/tables_Lin -name '*_bufsStream.txt')  )
# total number of km² in each buffer in Testing stream
#STT=$(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j/1000000; j=0 }')

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    | awk '{print $2/$1}'

paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }' | awk -v D="$SS" '{print $1/D}'

paste -d' ' \
    <(paste -d' ' ${tables[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    <(paste -d' ' ${buffers[@]} | awk '{ for(i=1; i<=NF;i++) j+=$i; print j; j=0 }') \
    > $DIR/table_lin.txt #| awk '{print $2/$1}'

awk 'BEGIN{print "TotAreaBuf AreaStre Prop"}; {print $0, $2/$1}' $DIR/table_lin.txt \
    > $DIR/table_lin2.txt && mv $DIR/table_lin2.txt $DIR/table_lin.txt

################################################################################
###############################################################################
