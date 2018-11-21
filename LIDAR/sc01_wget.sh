#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 18  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc01_wget.sh.%J.out
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

export FOLD # =MT05_05Lorang  # =ME07_Snyder

mkdir $SC/$FOLD
mkdir $SC/$FOLD/las
mkdir $SC/$FOLD/laz 



if [ FOLD="ME07_Snyder" ]    ; then export  EPSG=26919 ; fi 
if [ FOLD="NH09_Finkelman" ] ; then export  EPSG=26919 ; fi 
if [ FOLD="MT05_05Lorang" ]  ; then export  EPSG=26912 ; fi 
if [ FOLD="ID09_Lloyd" ]     ; then export  EPSG=26911 ; fi 
if [ FOLD="OR07_MalheurNF" ] ; then export  EPSG=26911 ; fi 
if [ FOLD="ILC09_ClearCrk" ] ; then export  EPSG=26911 ; fi 

cd $SC/$FOLD/laz
# download the html list 
# wget -A .html  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/${FOLD} 
# grep .laz  $SC/$FOLD/laz/$FOLD  | awk -F '"'  '{ print $4 }'  > $SC/$FOLD/${FOLD}_lazlist.txt 
# rm -f $SC/$FOLD/laz/${FOLD}

# for file in $( cat $SC/$FOLD/${FOLD}_lazlist.txt) ; do
# wget    https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/${FOLD}/$file
# done 

# singularity exec /gpfs/home/fas/sbsc/ga254/scripts/LIDAR/Ubuntu_pktools_gdal2.simg  bash <<'EOF'    
# echo $SC
# #3  find $SC/${FOLD}/laz -name "*.laz" | xargs -n 1  -P 18 bash -c $' file=$1 ; filename=$(basename $file .laz ) ; if [ ! -f $SC/$FOLD/las/$filename.las  ] ; then  echo unlaszip $file ; laszip -i $file  -o $SC/$FOLD/las/$filename.las  ; fi   ' _ 
# ### rm -r   $SC/${FOLD}/cloud.sdsc.edu

# echo start to create DTM

# pklas2img   -nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9  $(find  $SC/$FOLD/las/ -name "*.las" -type f -exec echo "-i"  '{}' \;)  -o $SC/${FOLD}/dtm.tif -a_srs EPSG:$EPSG -fir all -comp percentile -min   -n z -dx 100 -dy 100 -ot Float32 

# echo filterdem 
# pkfilterdem -nodata -9999  -f promorph  -dim 3 -dim 11  -i  $SC/${FOLD}/dtm.tif  -o $SC/${FOLD}/dtm_morpho.tif

# echo start to create DSM
# pklas2img   -nodata -9999  -co COMPRESS=DEFLATE -co ZLEVEL=9  $(find  $SC/$FOLD/las/ -name "*.las" -type f -exec echo "-i"  '{}' \;)  -o $SC/${FOLD}/dsm.tif -a_srs EPSG:$EPSG -fir all -comp percentile -perc 95 -n z -dx 100 -dy 100 -ot Float32
# sleep 60

# EOF

echo start to warp 

gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 100 100 -s_srs EPSG:$EPSG -t_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $SC/$FOLD/dsm.tif $DIR/../equi/${FOLD}_dsm.tif -overwrite
gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 100 100 -s_srs EPSG:$EPSG -t_srs "$EQUI7/grids/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -r bilinear $SC/$FOLD/dtm.tif $DIR/../equi/${FOLD}_dtm.tif -overwrite 

rm -f    $DIR/../equi/${FOLD}_dsm_shp.* 
gdaltindex   $DIR/../equi/${FOLD}_dsm_shp.shp    $DIR/../equi/${FOLD}_dsm.tif 

gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.0008333333333333 0.0008333333333333   -s_srs EPSG:$EPSG -t_srs EPSG:4326 -r bilinear $SC/$FOLD/dsm.tif        $DIR/../equi/${FOLD}_dsm_wgs84.tif -overwrite
gdalwarp -tap -co COMPRESS=DEFLATE -co ZLEVEL=9 -tr 0.0008333333333333 0.0008333333333333   -s_srs EPSG:$EPSG -t_srs EPSG:4326 -r bilinear $SC/$FOLD/dtm.tif        $DIR/../equi/${FOLD}_dtm_wgs84.tif -overwrite 

rm -f      $DIR/../equi/${FOLD}_dsm_wgs84_shp.* 
gdaltindex $DIR/../equi/${FOLD}_dsm_wgs84_shp.shp    $DIR/../equi/${FOLD}_dsm_wgs84.tif 

exit 

wget --cut-dirs=3   -r -np -R "index.html*" https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/NH09_Finkelman/
wget --cut-dirs=3   -r -np -R "index.html*" https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/MT05_05Lorang/
wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/ID09_Lloyd/
wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/OR07_MalheurNF/ 
wget --cut-dirs=3   -r -np -R "index.html*"  https://cloud.sdsc.edu/v1/AUTH_opentopography/PC_Bulk/SC14_CZO/Part1/
