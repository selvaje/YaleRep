#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 18  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/grace0/stdout/sc03_equi7_reproj_dem.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/grace0/stderr/sc03_equi7_reproj_dem.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc03_equi7_reproj_dem.sh

# for CT in EU AF AN AS NA OC SA ; do   sbatch --export=CT=$CT  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc03_equi7_reproj_dem.sh ; done 

export   DIR=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT
export INDIR=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT/input_tif
export EQUI7=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/EQUI7
export equi7=/project/fas/sbsc/ga254/grace0.grace.hpc.yale.internal/dataproces/MERIT/equi7/dem

# file in  $EQUI7  from   https://github.com/TUW-GEO/Equi7Grid/tree/master/equi7grid/grids 

# shp extent ll ur 

echo afdad

export CT
echo $CT  $xmin $ymin $xmax $ymax
#  -te      xmin ymin xmax ymax 
#  -projwin ulx  uly  lrx  lry
# enlarge the tile 100 x  8 
paste <(ogrinfo -al -GEOM=NO  $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep EASTINGLL  | awk '{ if(NR>1)   print $4 - 800  }' ) \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep NORTHINGLL | awk '{ if (NR>1)  print $4 - 800  }')  \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep EASTINGLL  | awk '{ if(NR>1) { print $4 + 600000 + 800 }}') \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep NORTHINGLL | awk '{ if(NR>1) { print $4 + 600000 + 800 }}') \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep "TILE "    | awk '{            print $4 }')  \
      >  $equi7/${CT}/tile_equi7_${CT}_warp.txt 

cat $equi7/${CT}/tile_equi7_${CT}_warp.txt  | xargs -n 5 -P 18  bash -c $' 

gdalwarp -te $1 $2 $3 $4 -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs "$EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj" -tr 100 100 -r bilinear $INDIR/all_tif.vrt /dev/shm/${CT}_${5}_dem.tif -overwrite
gdal_translate   -srcwin 8 8 6000 6000 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND /dev/shm/${CT}_${5}_dem.tif    /dev/shm/${CT}_${5}_dem_crop.tif  
rm -f /dev/shm/${CT}_${5}_dem.tif  
MAX=$(pkstat -max -i  /dev/shm/${CT}_${5}_dem_crop.tif | awk \'{ print $2 }\')
if [ $MAX ==  "-9999" ] ; then 
rm -f /dev/shm/${CT}_${5}_dem_crop.tif 
else 
cp /dev/shm/${CT}_${5}_dem_crop.tif  $equi7/${CT}/${CT}_${5}.tif 
rm -f /dev/shm/${CT}_${5}_dem_crop.tif 
fi

' _ 

gdalbuildvrt -overwrite  $equi7/${CT}/all_${CT}_tif.vrt  $equi7/${CT}/${CT}_???_???.tif  
rm $equi7/${CT}/tile_equi7_${CT}_warp.txt 
