#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_equi7_reproj_upa.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_equi7_reproj_upa.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc04_equi7_reproj_upa.sh

# for CT in EU AF AN AS NA OC SA ; do   sbatch --export=CT=$CT  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc04_equi7_reproj_upa.sh ; done 

export   DIR=/project/fas/sbsc/ga254/dataproces/MERIT
export INDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/upa
export EQUI7=/project/fas/sbsc/ga254/dataproces/EQUI7
export equi7=/project/fas/sbsc/ga254/dataproces/MERIT/equi7/upa
export KM=0.10
# shp extent ll ur 

export CT
echo $CT  $xmin $ymin $xmax $ymax
#  -te      xmin ymin xmax ymax 
#  -projwin ulx  uly  lrx  lry
# enlarge the tile 100 x  8 
paste <(ogrinfo -al -GEOM=NO  $EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep EASTINGLL  | awk '{ if(NR>1)   print $4 - 800  }' ) \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep NORTHINGLL | awk '{ if (NR>1)  print $4 - 800  }')  \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep EASTINGLL  | awk '{ if(NR>1) { print $4 + 600000 + 800 }}') \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep NORTHINGLL | awk '{ if(NR>1) { print $4 + 600000 + 800 }}') \
      <(ogrinfo -al -GEOM=NO  $EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T6.shp | grep "TILE "    | awk '{            print $4 }')  \
      >  $equi7/${CT}/tile_equi7_${CT}_warp_upa.txt 

cat $equi7/${CT}/tile_equi7_${CT}_warp_upa.txt  | xargs -n 5 -P 12  bash -c $' 

gdalwarp -te $1 $2 $3 $4 -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs "$EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE.prj" -tr 100 100 -r bilinear $INDIR/all_tif.vrt  /dev/shm/${CT}_${5}_upa.tif -overwrite
gdal_translate   -srcwin 8 8 6000 6000  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  /dev/shm/${CT}_${5}_upa.tif  /dev/shm/${CT}_${5}_upa_crop.tif
rm -f /dev/shm/${CT}_${5}_upa.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -ot Float32  -m $DIR/../EQUI7/grids_enlarge/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_ZONE_KM$KM.tif -msknodata 0 -nodata -9999 -i /dev/shm/${CT}_${5}_upa_crop.tif  -o /dev/shm/${CT}_${5}_upa_msk.tif 
rm -f /dev/shm/${CT}_${5}_upa_crop.tif 

MAX=$(pkstat -max -i  /dev/shm/${CT}_${5}_upa_msk.tif | awk \'{ print $2 }\')
if [ $MAX ==  "-9999" ] ; then 
rm -f /dev/shm/${CT}_${5}_upa_msk.tif 
else 
cp /dev/shm/${CT}_${5}_upa_msk.tif  $equi7/${CT}/${CT}_${5}.tif 
gdal_edit.py -a_nodata -9999 $equi7/${CT}/${CT}_${5}.tif 
rm -f /dev/shm/${CT}_${5}_upa_msk.tif 
fi


' _


gdalbuildvrt   -srcnodata -9999 -vrtnodata -9999    -overwrite  $equi7/${CT}/all_${CT}_tif.vrt  $equi7/${CT}/${CT}_???_???.tif
rm $equi7/${CT}/tile_equi7_${CT}_warp_upa.txt 
