#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc01_wget.sh.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc01_wget.sh.%J.err

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc01_wget.sh  
# for FOLD  in ME07_Snyder NH09_Finkelman MT05_05Lorang ID09_Lloyd  OR07_MalheurNF ILC09_ClearCrk  ; do  sbatch  --export=FOLD=$FOLD   /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/sc01_wget.sh   ; done 

# http://opentopo.sdsc.edu/datasetMetadata?otCollectionID=OT.042013.26919.1    ME07_Snyder
#     Horizontal: UTM z19N NAD83 (CORS96)  [EPSG: 26919]  #     Vertical: NAVD88 (Geoid 03) [EPSG: 5703] 

# http://opentopo.sdsc.edu/datasetMetadata?otCollectionID=OT.012012.26919.2  NH09_Finkelman
#     Horizontal: UTM n19 N NAD83 (CORS96) [EPSG: 26919]  #     Vertical: NAVD88 (GEOID03) [EPSG: 5703] 


# http://opentopo.sdsc.edu/datasetMetadata.jsp?otCollectionID=OT.052013.26912.2     MT05_05Lorang
#     Horizontal: UTM z12 N NAD83 (CORS96) [EPSG: 26912]  #     Vertical: NAVD88 (Geoid 03) [EPSG: 5703] 


# http://opentopo.sdsc.edu/datasetMetadata.jsp?otCollectionID=OT.012012.26911.1     ID09_Lloyd
#     Horizontal: UTM z11 N NAD83 (CORS96) [EPSG: 26911]  #     Vertical: NAVD88 (GEOID03) [EPSG: 5703] 

# http://opentopo.sdsc.edu/datasetMetadata.jsp?otCollectionID=OT.032012.26911.3 OR07_MalheurNF
#     Horizontal: UTM z11N NAD83           [EPSG: 26911]  #     Vertical: NAVD88 (GEOID03) [EPSG: 5703] 


# http://opentopo.sdsc.edu/datasetMetadata?otCollectionID=OT.042012.26911.6    ILC09_ClearCrk
#     Horizontal: UTMz11N NAD83            [EPSG: 26911]  #     Vertical: NAVD88 [EPSG: 5703] 

export DIR=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/LIDAR/input
export EQUI7=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/EQUI7
export SC=/gpfs/loomis/scratch60/fas/sbsc/ga254/grace0/dataproces/LIDAR/input

export FOLD

mkdir $SC/$FOLD

cd $SC/$FOLD

if [ FOLD = "ME07_Snyder" ]    ; then export  EPSG=26919 ; fi 
if [ FOLD = "NH09_Finkelman" ] ; then export  EPSG=26919 ; fi 
if [ FOLD = "MT05_05Lorang" ]  ; then export  EPSG=26912 ; fi 
if [ FOLD = "ID09_Lloyd" ]     ; then export  EPSG=26911 ; fi 
if [ FOLD = "OR07_MalheurNF" ] ; then export  EPSG=26911 ; fi 
if [ FOLD = "ILC09_ClearCrk" ] ; then export  EPSG=26911 ; fi 


# wget --cut-dirs=4  -nv   -r -np -R "index.html*" https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/${FOLD}

singularity exec /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/Ubuntu_pktools_gdal2.simg  bash <<'EOF'    
echo $SC
ls   $SC/${FOLD}/cloud.sdsc.edu/*.laz  | xargs -n 1  -P 12 bash -c $' file=$1 ; filename=$(basename $file .laz )  ; echo unlaszip $file  ;  laszip -i $file  -o    $SC/$FOLD/$filename.las  ' _ 
rm -r   $SC/${FOLD}/cloud.sdsc.edu

echo start to create DTM 
pklas2img -co COMPRESS=DEFLATE -co ZLEVEL=9  $(for file in *.las; do echo " -i "$file;done)  -o $SC/${FOLD}/dtm.tif -a_srs EPSG:$EPSG -fir all -comp percentile -min   -n z -dx 100 -dy 100 -ot Float32 
pkfilterdem -f promorph -dim 3 -dim 11 -i  $SC/${FOLD}/dtm.tif  -o $SC/${FOLD}/dtm_morpho.tif

echo start to create DSM
pklas2img -co COMPRESS=DEFLATE -co ZLEVEL=9  $(for file in *.las; do echo " -i "$file;done)  -o $sc/${FOLD}/dsm.tif -a_srs EPSG:$EPSG -fir all -comp percentile -perc 95 -n z -dx 100 -dy 100 -ot Float32
sleep 60 

EOF

gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 100 100 -s_srs EPSG:$EPSG -t_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $SC/$FOLD/dsm.tif        $DIR/../equi/${FOLD}_dsm.tif -overwrite
gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 100 100 -s_srs EPSG:$EPSG -t_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $SC/$FOLD/dtm_morpho.tif $DIR/../equi/${FOLD}_dtm.tif -overwrite 

exit 









wget --cut-dirs=3   -r -np -R "index.html*" https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/NH09_Finkelman/
cd ~/tmp/lidar/cloud.sdsc.edu/NH09_Finkelman
for file in *.laz ; do filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file ; done

pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26919' -fir all -comp min -n z -dx 90 -dy 90  -ot Float32 
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26919' -fir all -comp max -n z -dx 90 -dy 90  -ot Float32

gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dsm.tif dsm_wgs84.tif -overwrite 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dtm.tif dtm_wgs84.tif -overwrite 

gdal_translate  -srcwin 10 10 125 60   -co COMPRESS=DEFLATE -co ZLEVEL=9  dtm_wgs84.tif dtm_wgs84_crop.tif
gdal_translate  -srcwin 10 10 125 60   -co COMPRESS=DEFLATE -co ZLEVEL=9  dsm_wgs84.tif dsm_wgs84_crop.tif





wget --cut-dirs=3   -r -np -R "index.html*" https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/MT05_05Lorang/

cd  ~/tmp/lidar/cloud.sdsc.edu/MT05_05Lorang
for file in *.laz ; do filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file ; done

pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26911' -fir all -comp min -n z -dx 90 -dy 90  -ot Float32 
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26911' -fir all -comp max -n z -dx 90 -dy 90  -ot Float32

gdal_translate  -srcwin 10 10 145 99    -co COMPRESS=DEFLATE -co ZLEVEL=9  dtm_wgs84.tif dtm_wgs84_crop.tif 





wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/ID09_Lloyd/
cd ~/tmp/lidar/cloud.sdsc.edu/ID09_Lloyd
for file in *.laz ; do filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file ; done

pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26911' -fir all -comp min -n z -dx 90 -dy 90  -ot Float32 
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26911' -fir all -comp max -n z -dx 90 -dy 90  -ot Float32

gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dsm.tif dsm_wgs84.tif -overwrite 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dtm.tif dtm_wgs84.tif -overwrite 

gdal_translate  -srcwin 280  10  100 38     -co COMPRESS=DEFLATE -co ZLEVEL=9  dtm_wgs84.tif  dtm_wgs84_crop.tif
gdal_translate  -srcwin 280  10  100 38     -co COMPRESS=DEFLATE -co ZLEVEL=9  dsm_wgs84.tif  dsm_wgs84_crop.tif

# gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -projwin  $(getCorners4Gtranslate dsm_wgs84.tif )       /project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT/input_tif/all_tif.vrt  merit.tif 






wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/OR07_MalheurNF/ 

cd ~/tmp/lidar/cloud.sdsc.edu/OR07_MalheurNF/ 

for file in *.laz ; do filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file ; done

pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26911' -fir all -comp min -n z -dx 90 -dy 90  -ot Float32 
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26911' -fir all -comp max -n z -dx 90 -dy 90  -ot Float32

gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dsm.tif dsm_wgs84.tif -overwrite 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dtm.tif dtm_wgs84.tif -overwrite 

gdal_translate  -srcwin 40  146 100 50     -co COMPRESS=DEFLATE -co ZLEVEL=9  dtm_wgs84.tif  dtm_wgs84_crop.tif
gdal_translate  -srcwin 40  146 100 50     -co COMPRESS=DEFLATE -co ZLEVEL=9  dsm_wgs84.tif  dsm_wgs84_crop.tif



# http://opentopo.sdsc.edu/datasetMetadata.jsp?otCollectionID=OT.122015.26917.1


# Coordinates System: 
#     Horizontal: NAD83 (2011), UTM Zone 17N [EPSG: 26917] 
#     Vertical: NAVD88 (GEOID 12a) [EPSG: 5703] 

wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/SC14_CZO/Part1/


cd ~/tmp/lidar/cloud.sdsc.edu/

for file in *.laz ; do filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file ; done

ls  *.laz | xargs -n 1 -P 3 bash -c $' file=$1 ;  filename=$(basename $file .laz )  ;  laszip -i $file    -o $filename.las ; rm $file  ' _


pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26917' -fir all -comp min -n z -dx 90 -dy 90  -ot Float32 
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26917' -fir all -comp max -n z -dx 90 -dy 90  -ot Float32

pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dsm.tif -a_srs 'epsg:26917' -fir all -comp percentile  -perc 95  -n z -dx 90 -dy 90  -ot Float32
pklas2img  -co COMPRESS=DEFLATE -co ZLEVEL=9   $(for file in *.las; do echo " -i "$file;done)    -o dtm.tif -a_srs 'epsg:26917' -fir all -comp percentile  -perc 5  -n z -dx 90 -dy 90  -ot Float32

gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dsm.tif dsm_wgs84.tif -overwrite 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear    dtm.tif dtm_wgs84.tif -overwrite 

gdal_translate  -srcwin 40  146 100 50     -co COMPRESS=DEFLATE -co ZLEVEL=9  dtm_wgs84.tif  dtm_wgs84_crop.tif
gdal_translate  -srcwin 40  146 100 50     -co COMPRESS=DEFLATE -co ZLEVEL=9  dsm_wgs84.tif  dsm_wgs84_crop.tif


# merge the differnt dsm and dtm 


gdalbuildvrt  dsm.vrt Part1/dsm.tif   Part2/dsm.tif Part3/dsm.tif Part4/dsm.tif Part5/dsm.tif 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear dsm.vrt  dsm_wgs84.tif -overwrite 

gdalbuildvrt  dtm.vrt Part1/dtm.tif   Part2/dtm.tif Part3/dtm.tif Part4/dtm.tif Part5/dtm.tif 
gdalwarp -tap  -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.000833333333333 0.000833333333333 -t_srs EPSG:4326 -r bilinear dtm.vrt  dtm_wgs84.tif -overwrite 

