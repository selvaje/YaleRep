#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 20  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc30_equi7_distortion_assment.sh .%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc30_equi7_distortion_assment.sh .%J.err
#SBATCH --mem-per-cpu=2000


# sbatch  /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc30_equi7_distortion_assment.sh

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"


export MERIT=/project/fas/sbsc/ga254/dataproces/MERIT
export SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
export EQUI7=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/EQUI7/grids
export RAM=/dev/shm


gdal_translate -projwin  -83.158   8.808  -83.05   8.70   $MERIT/input_tif/n05w085_dem.tif            $SCRATCH/equi7val/n05w080_wgs84_south.tif 
# transpose from south to north 
gdal_translate  -a_ullr  -83.158  80.808  -83.05  80.70   $SCRATCH/equi7val/n05w080_wgs84_south.tif   $SCRATCH/equi7val/n05w080_wgs84_north.tif 

# create ogr shp 
rm -f $SCRATCH/equi7val/n05w080_wgs84_*_shp.*
gdaltindex  $SCRATCH/equi7val/n05w080_wgs84_south_shp.shp   $SCRATCH/equi7val/n05w080_wgs84_south.tif 
gdaltindex  $SCRATCH/equi7val/n05w080_wgs84_north_shp.shp   $SCRATCH/equi7val/n05w080_wgs84_north.tif 

ogr2ogr -s_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -t_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj  $SCRATCH/equi7val/n05w080_wgs84_south_toequi7_shp.shp   $SCRATCH/equi7val/n05w080_wgs84_south_shp.shp 
ogr2ogr -s_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -t_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj  $SCRATCH/equi7val/n05w080_wgs84_north_toequi7_shp.shp   $SCRATCH/equi7val/n05w080_wgs84_north_shp.shp 



# calculate slope and tri from the south wgs84  tile  

gdaldem slope -s 111120    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_wgs84_south.tif $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif  
gdal_translate   -srcwin 5 5 120 120  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif  $SCRATCH/equi7val/n05w080_wgs84_south_slope.tif  
rm $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif 

gdaldem tri -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_wgs84_south.tif $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif  
gdal_translate   -srcwin 5 5 120 120  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif  $SCRATCH/equi7val/n05w080_wgs84_south_tri.tif  
rm $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif 

# calculate slope and tri from the north wgs84 tile  

gdaldem slope -s 111120  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_wgs84_north.tif $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif  
gdal_translate   -srcwin 5 5 120 120  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif  $SCRATCH/equi7val/n05w080_wgs84_north_slope.tif  
rm $SCRATCH/equi7val/n05w080_wgs84_tmp_slope.tif 

gdaldem tri   -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_wgs84_north.tif $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif  
gdal_translate   -srcwin 5 5 120 120  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif  $SCRATCH/equi7val/n05w080_wgs84_north_tri.tif  
rm $SCRATCH/equi7val/n05w080_wgs84_tmp_tri.tif 


# change projection from wgs84 to equi7 for  south and north part 

gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs "$EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -tr 100 100 -r bilinear $SCRATCH/equi7val/n05w080_wgs84_north.tif $SCRATCH/equi7val/n05w080_equi7_north.tif   -overwrite
gdaldem slope  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_equi7_north.tif      $SCRATCH/equi7val/n05w080_equi7_north_slope.tif  
gdaldem tri    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_equi7_north.tif      $SCRATCH/equi7val/n05w080_equi7_north_tri.tif  

gdalwarp -co COMPRESS=DEFLATE -co ZLEVEL=9 -t_srs "$EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj" -tr 100 100 -r bilinear $SCRATCH/equi7val/n05w080_wgs84_south.tif $SCRATCH/equi7val/n05w080_equi7_south.tif   -overwrite
gdaldem slope  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_equi7_south.tif      $SCRATCH/equi7val/n05w080_equi7_south_slope.tif  
gdaldem tri    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND   $SCRATCH/equi7val/n05w080_equi7_south.tif      $SCRATCH/equi7val/n05w080_equi7_south_tri.tif  


# reproject back the slope and tri from equi to wgs84 

gdalwarp  -te $(getCorners4Gwarp  $SCRATCH/equi7val/n05w080_wgs84_north_slope.tif)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj    -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333     -r bilinear  -overwrite $SCRATCH/equi7val/n05w080_equi7_north_slope.tif    $SCRATCH/equi7val/n05w080_equi7_north_slope_towgs84.tif  
gdalwarp  -te $(getCorners4Gwarp  $SCRATCH/equi7val/n05w080_wgs84_north_tri.tif)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj    -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333     -r bilinear  -overwrite $SCRATCH/equi7val/n05w080_equi7_north_tri.tif    $SCRATCH/equi7val/n05w080_equi7_north_tri_towgs84.tif  

gdalwarp  -te $(getCorners4Gwarp  $SCRATCH/equi7val/n05w080_wgs84_north_slope.tif)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj    -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333     -r bilinear  -overwrite $SCRATCH/equi7val/n05w080_equi7_north_slope.tif    $SCRATCH/equi7val/n05w080_equi7_north_slope_towgs84.tif  
gdalwarp  -te $(getCorners4Gwarp  $SCRATCH/equi7val/n05w080_wgs84_north_tri.tif)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -s_srs  $EQUI7/NA/PROJ/EQUI7_V13_NA_PROJ_ZONE.prj    -t_srs $EQUI7/NA/GEOG/EQUI7_V13_NA_GEOG_ZONE.prj -tr 0.000833333333333333333  0.000833333333333333333     -r bilinear  -overwrite $SCRATCH/equi7val/n05w080_equi7_north_tri.tif    $SCRATCH/equi7val/n05w080_equi7_north_tri_towgs84.tif  

exit 
