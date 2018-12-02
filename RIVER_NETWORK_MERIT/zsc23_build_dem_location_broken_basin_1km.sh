#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 168:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc23_build_dem_location_broken_basin.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc23_build_dem_location_broken_basin.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc23_build_dem_location_broken_basin.sh
#SBATCH --array=97-97
#SBATCH --mem-per-cpu=80000

# 98 UNIT 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc23_build_dem_location_broken_basin.sh

echo SLURM_JOB_ID $SLURM_JOB_ID
echo SLURM_ARRAY_JOB_ID $SLURM_ARRAY_JOB_ID
echo SLURM_ARRAY_TASK_ID $SLURM_ARRAY_TASK_ID
echo SLURM_ARRAY_TASK_COUNT $SLURM_ARRAY_TASK_COUNT
echo SLURM_ARRAY_TASK_MAX $SLURM_ARRAY_TASK_MAX
echo SLURM_ARRAY_TASK_MIN  $SLURM_ARRAY_TASK_MIN

module load Apps/GRASS/7.3-beta

MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
GRASS=/tmp
RAM=/dev/shm 

find  /tmp      -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

UNIT=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1 }' /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump_hist1_s.txt ) 

geo_string=$( oft-bb /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk1km/brokb_msk1km_clump.tif $UNIT | grep BB | awk '{ print $6,$7,$8,$9}') 

echo $geo_string for UNIT $UNIT

### take the coridinates from the orginal files and increment of 1 degree 

export ulxL=$( echo $geo_string | awk  '{ printf ("%.16f" , -180 + (($1 - 10 ) * 0.00833333333333)) }')
export ulyL=$( echo $geo_string | awk  '{ printf ("%.16f" ,   85 - (($2 - 10 ) * 0.00833333333333)) }')
export lrxL=$( echo $geo_string | awk  '{ printf ("%.16f" , -180 + (($3 + 10)  * 0.00833333333333)) }')
export lryL=$( echo $geo_string | awk  '{ printf ("%.16f" ,   85 - (($4 + 10)  * 0.00833333333333)) }')

echo  $ulxL $ulyL $lrxL  $lryL 

gdalbuildvrt -overwrite -te $ulxL $lryL $lrxL $ulyL $RAM/msk_brokb_UNIT$UNIT.vrt  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_brokb_msk/all_tif.vrt   
gdal_translate    -co COMPRESS=DEFLATE -co ZLEVEL=9  -a_ullr $ulxL $ulyL $lrxL $lryL  $RAM/msk_brokb_UNIT$UNIT.vrt    $RAM/msk_brokb_UNIT$UNIT.tif 

gdal_edit.py  -a_nodata 0  $RAM/msk_brokb_UNIT$UNIT.tif  ; $RAM/msk_brokb_UNIT$UNIT.vrt  
cp $RAM/msk_brokb_UNIT$UNIT.tif /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/tmp 

for var in msk elv dep upa ; do 
gdalbuildvrt -overwrite -te $ulxL $lryL $lrxL $ulyL $RAM/UNIT${UNIT}_${var}.vrt  $MERIT/${var}/all_tif.vrt   
gdal_translate  -co BIGTIFF=YES    -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -a_ullr $ulxL $ulyL $lrxL $lryL  $RAM/UNIT${UNIT}_${var}.vrt $RAM/UNIT${UNIT}_${var}.tif
#
if [ $var = "elv" ] || [ $var = "upa" ] ; then  
    gdal_edit.py  -a_nodata -9999  $RAM/UNIT${UNIT}_${var}.tif
else
    gdal_edit.py  -a_nodata 0      $RAM/UNIT${UNIT}_${var}.tif
fi
rm -f  $RAM/UNIT${UNIT}_${var}.vrt 
done 

rm -fr $GRASS/loc_$UNIT 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $GRASS loc_$UNIT $RAM/UNIT${UNIT}_msk.tif r.in.gdal

g.remove -f  type=raster name=UNIT${UNIT}_msk  
r.external  input=$RAM/UNIT${UNIT}_elv.tif     output=elv        --overwrite 
r.external  input=$RAM/msk_brokb_UNIT$UNIT.tif output=msk_brokb  --overwrite
r.external  input=$RAM/UNIT${UNIT}_msk.tif     output=msk        --overwrite
r.external  input=$RAM/UNIT${UNIT}_dep.tif     output=dep        --overwrite
r.external  input=$RAM/UNIT${UNIT}_upa.tif     output=upa        --overwrite

r.mask raster=msk  --o 

r.stream.extract elevation=elv  accumulation=upa threshold=0.5    depression=dep     direction=dir  stream_raster=stream memory=60000 --o --verbose  ;  r.colors -r stream
g.remove -f  type=raster name=upa,elv,dep ; rm $RAM/UNIT${UNIT}_upa.tif $RAM/UNIT${UNIT}_elv.tif  $RAM/UNIT${UNIT}_dep.tif 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l -m stream_rast=stream  direction=dir  basins=lbasin  memory=50000 --o --verbose  ;  r.colors -r lbasin

r.mask raster=msk_brokb   --o

r.out.gdal --overwrite -c -m   createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_unit_large/lbasin_brokb$UNIT.tif 
r.out.gdal --overwrite -c -m   createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/stream_unit_large/stream_brokb$UNIT.tif 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

rm -fr $GRASS/loc_$UNIT  $RAM/UNIT${UNIT}*.tif $RAM/msk_brokb_UNIT$UNIT.tif

exit 
