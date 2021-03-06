# for tile in $(  awk '{  print $1 }'  /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt  ) ; do bash  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/GSHHG/sc1_rasterize.sh $tile   ; done  

# for tile in $(  awk '{  print $1 }'  /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt  ) ; do qsub -v tile=$tile  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/GSHHG/sc1_rasterize.sh    ; done  

# The geography data come in five resolutions:

#  F   full resolution: Original (full) data resolution.
#  H   high resolution: About 80 % reduction in size and quality.
#  I   intermediate resolution: Another ~80 % reduction.
#  L   low resolution: Another ~80 % reduction.
#  C   crude resolution: Another ~80 % reduction.

# Unlike the shoreline polygons at all resolutions, the lower resolution rivers are not guaranteed not to cross.
# Shorelines are furthermore organized into 4 hierarchical levels:

#     L1: boundary between land and ocean.
#     L2: boundary between lake and land.
#     L3: boundary between island-in-lake and lake.
#     L4: boundary between pond-in-island and island.

#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=1gb
#PBS -l walltime=1:00:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr


module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Libraries/OSGEO/1.10.0


# tile=$1

INPUT=/lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_shp/f/GSHHS_f_L1.shp
SHPOUT=/lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_shp_clip
TIFOUT=/lustre0/scratch/ga254/dem_bj/GSHHG/GSHHS_tif


xmin=$( awk -v tile=$tile '{ if($1==tile) print $4   }' /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt) 
ymin=$( awk -v tile=$tile '{ if($1==tile) print $9   }' /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt) 
xmax=$( awk -v tile=$tile '{ if($1==tile) print $10  }' /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt)  
ymax=$( awk -v tile=$tile '{ if($1==tile) print $5   }' /lustre0/scratch/ga254/dem_bj/GSHHG/geo_file/tile_lat_long_10d.txt)

rm -f $SHPOUT/$tile.*
echo  clip the shp by $tile
ogr2ogr -spat  $xmin   $ymin   $xmax   $ymax -skipfailures  $SHPOUT/$tile.shp     $INPUT  

echo rasterize 
rm -f  $TIFOUT/$tile.tif
gdal_rasterize -tr 0.00083333333333 0.00083333333333  -burn  1 -te  $xmin $ymin $xmax $ymax -co COMPRESS=LZW -co ZLEVEL=9  -ot Byte -l $tile  $SHPOUT/$tile.shp  $TIFOUT/$tile.tif

pkfilter    -co COMPRESS=LZW -ot Byte    -class 1  -dx 10  -dy 10   -f density -d 10  -i $TIFOUT/$tile.tif   -o ${TIFOUT}_1km/${tile}_1km.tif 

exit 

# in case of better resolution 

# gdal_rasterize -tr 0.000083333333333 0.000083333333333  -burn  1 -te  $xmin $ymin $xmax $ymax -co COMPRESS=LZW -co ZLEVEL=9  -ot Byte -l $tile  $SHPOUT/$tile.shp  $TIFOUT/$tile.tif
# pkfilter    -co COMPRESS=LZW -ot Float32    -class 1  -dx 100  -dy 100   -f density -d 10  -i $TIFOUT/$tile.tif   -o ${TIFOUT}_1km/${tile}_1km.tif 

# oft-calc -ot  Float32 ${TIFOUT}_1km/${tile}_1km.tif   ${TIFOUT}_1km/${tile}_1kmPerc.tif <<EOF
# 1
# #1 100 *
# EOF

# gdal_calc.py  -A ${TIFOUT}_1km/${tile}_1km.tif    --calc="(A * 100 )" --co=COMPRESS=LZW  --co=ZLEVEL=9    --overwrite  --outfile ${TIFOUT}_1km/${tile}_1kmPerc.tif
# gdal_translate -ot Byte  -co COMPRESS=LZW -co ZLEVEL=9  ${TIFOUT}_1km/${tile}_1kmPerc.tif ${TIFOUT}_1km/${tile}_1kmPercC.tif

# rm -f ${TIFOUT}_1km/${tile}_1kmPerc.tif ${TIFOUT}_1km/${tile}_1km.tif   $TIFOUT/$tile.tif $SHPOUT/$tile.*


