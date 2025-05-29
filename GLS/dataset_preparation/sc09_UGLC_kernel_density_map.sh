#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/sm3665/stdout/sc09_UGLC_kernel_density_map.sh.%j.out 
#SBATCH -e /vast/palmer/scratch/sbsc/sm3665/stderr/sc09_UGLC_kernel_density_map.sh.%j.err
#SBATCH --job-name=sc09_UGLC_kernel_density_map.sh 
#SBATCH --mem=40G
#### =======================================================================================
#### sbatch line: 
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GLS/sc09_UGLC_kernel_density_map.sh
#### =======================================================================================

#### info:
#### next step:
#### 1) gdalwarp a 90m (0.000833333333) del kernel density con extent del tile della slope ingrandito di 0.1
#### 2) gdaltranslate per ingrandire il vrt dei tiles della slope e lo ingrandisco di 0.1 (getCorners4Gtranslate  data4testing/test1.tif  | awk '{ print $1 - 0.1 , $2 + 0.1  ....    })
#### 3) usando gdallocationinfo controlla quali punti del dataset ricadono nel tile slope che sto usando
#### Questa linea select all the points that fall inside the tile
#### paste -d " " $QNT/x_y_ID.txt <( gdallocationinfo -geoloc -valonly $slope_tile  <  <(awk '{print $1, $2 }' $QNT/x_y_ID.txt) ) | awk '{if (NF==4) print $1, $2,$3 }'  > $RAM/x_y_ID_$TILE.txt


#### Dataset folder (check also the name)
export UGLC=/gpfs/gibbs/project/sbsc/sm3665/dataproces/GLS

#### Global Landslide Susceptbility general work files folder
export GLS=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLS
export FILENAME=U_x_y.txt

#### Modules load
source ~/bin/gdal3
source ~/bin/pktools

#module load foss/2020b
#module load PKTOOLS/2.6.7.6-foss-2020b


#### Get world extension as .gpkg from another global geospatial product (hydrography90m)  
rm -rf $GLS/geoarea/global_ext_EPSG4326.gpkg 

gdaltindex $GLS/geoarea/global_ext_EPSG4326.gpkg  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d/basin.tif 

#### Equidistant Cylindrical Projection (Equirectangular Projection)
#### Description:
#### In this projection, distances are preserved along meridians and parallels.
#### The projection is created by mapping latitudes and longitudes onto a regular grid,
#### and it's useful for mapping regions close to the equator. However, distortion increases  as you move away from the equator.
#### Common Uses: World maps, thematic maps.
#### WGS 84 Equidistant Cylindrical (Plate Carrée): EPSG: 32662 (for WGS 84 datum).

#### Convert epsg4326 .gpkg world extension into an epsg32662 .gpkg 
rm -rf $GLS/geoarea/global_ext_EPSG32662.gpkg 

ogr2ogr -t_srs EPSG:32662   $GLS/geoarea/global_ext_EPSG32662.gpkg   $GLS/geoarea/global_ext_EPSG4326.gpkg

#### Convert epsg4326 .txt catalog (UGLC) into an epsg32662 .gpkg
#### UGLC.txt has lon in col 2 and lat in col 3

rm -rf $UGLC/UGLC.gpkg

pkascii2ogr -a_srs epsg:4326 -x 1 -y 2 -i $UGLC/$FILENAME  -o $UGLC/UGLC.gpkg

ogr2ogr -t_srs EPSG:32662   $UGLC/UGLC_EPSG32662.gpkg  $UGLC/UGLC.gpkg

module load GRASS/8.2.0-foss-2022b

grass  --text --tmp-location $GLS/geoarea/global_ext_EPSG32662.gpkg    --exec <<'EOF'

for radius in 10000 50000 100000 200000 ; do 
g.region res=1000
v.in.ogr  input=$UGLC/UGLC_EPSG32662.gpkg output=presence  --o
#### verify the multiplier value
v.kernel input=presence output=kernel   radius=$radius  multiplier=10 --o
r.out.gdal --o -f -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" nodata=-9999 type=Float32 format=GTiff input=kernel output=$GLS/kernel/presence_kernel_EPSG32662.tif

EOF


gdalwarp -te $(getCorners4Gwarp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/hydrography90m_v.1.0/r.watershed/basin_tiles20d/basin.tif)\
	 -a_srs epsg:4326\
	 -tr 0.0083333333333 0.0083333333333\
	 -co COMPRESS=DEFLATE\
	 -co ZLEVEL=9\
	 $GLS/kernel/presence_kernel_EPSG32662.tif\
	 $GLS/kernel/presence_kernel_EPSG4326.tif

