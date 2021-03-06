
# awk '{ if ( NR > 1 ) print $1 }'  /lustre0/scratch/ga254/dem_bj/GMTED2010/geo_file/tiles-te_noOverlap.txt  | xargs -n 1  -P 10  bash /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/WDPA/sc1_rasterize_tile_all.sh 

# for tile in  $(awk '{ if ( NR > 1 ) print $1 }'  /lustre0/scratch/ga254/dem_bj/GMTED2010/geo_file/tiles-te_noOverlap.txt)  ; do qsub -v tile=$tile   /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/WDPA/sc1_rasterize_tile.sh  ; done 


# after compile gdal with the following set 
# ./configure   --with-fgdb=/usr/local/FileGDB_API  --with-geos=yes 


# DIR=/mnt/data2/scratch/WDPA
# apps/ogr2ogr  /mnt/data2/scratch/WDPA/shp_input/WDPA_Jan2014.shp  /mnt/data2/scratch/WDPA/shp_input/WDPA_Jan2014_Public/WDPA_Jan2014.gdb 



#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=10gb
#PBS -l walltime=4:00:00 
#PBS -l nodes=1:ppn=4
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr


# load moduels 

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Tools/PKTOOLS/2.4.2
module load Libraries/OSGEO/1.10.0



# export tile=$1
export tile=$1

export RASTERIZE=/lustre0/scratch/ga254/dem_bj/WDPA/rasterize_all/tiles
export SHP=/lustre0/scratch/ga254/dem_bj/WDPA


export geo_string=$( grep $tile /lustre0/scratch/ga254/dem_bj/GMTED2010/geo_file/tiles-te_noOverlap.txt  | awk '{ print $2,$3,$4,$5 }'  ) 

echo  clip the large shp by $geo_string

rm -f  $SHP/shp_input/WDPA_Jan2014.shp/shp_clip/WDPA_poly_Jan2014_$tile.shp

ogr2ogr -skipfailures   -spat   $geo_string  $SHP/shp_input/WDPA_Jan2014.shp/shp_clip/WDPA_poly_Jan2014_$tile.shp   $SHP/shp_input/WDPA_Jan2014.shp/WDPA_poly_Jan2014.shp



rm -f $RASTERIZE/${tile}.tif  
gdal_rasterize -ot Byte -a_srs EPSG:4326 -l  WDPA_poly_Jan2014_$tile  -burn 1   -a_nodata 0  -tr   0.008333333333333 0.008333333333333 \
-te  $geo_string  -co COMPRESS=LZW -co ZLEVEL=9  $SHP/shp_input/WDPA_Jan2014.shp/shp_clip/WDPA_poly_Jan2014_$tile.shp   $RASTERIZE/${tile}.tif 

exit 





