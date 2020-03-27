#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 168:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc23_build_dem_location_broken_basin.sh.%A_%a.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc23_build_dem_location_broken_basin.sh.%A_%a.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc23_build_dem_location_broken_basin.sh
#SBATCH --mem-per-cpu=110000
#SBATCH --array=1-157

# 157  UNIT 
# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc23_build_dem_location_broken_basin.sh
# sbatch  -d afterany:$(qmys | grep sc22_broken_basin_clumping.sh  | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc23_build_dem_location_broken_basin.sh

echo SLURM_JOB_ID           $SLURM_JOB_ID
echo SLURM_ARRAY_JOB_ID     $SLURM_ARRAY_JOB_ID
echo SLURM_ARRAY_TASK_ID    $SLURM_ARRAY_TASK_ID
echo SLURM_ARRAY_TASK_COUNT $SLURM_ARRAY_TASK_COUNT
echo SLURM_ARRAY_TASK_MAX   $SLURM_ARRAY_TASK_MAX
echo SLURM_ARRAY_TASK_MIN   $SLURM_ARRAY_TASK_MIN

module load Apps/GRASS/7.3-beta

export MERIT=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export SC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
export GRASS=/tmp
export RAM=/dev/shm 

find  /tmp      -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

export UNIT=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1 }' $SC/lbasin_tiles_brokb_msk/brokb_msk_clump_hist1_s.txt ) 
echo start the oft-bb UNIT $UNIT
geo_string=$(oft-bb  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump.tif $UNIT | grep BB  |  awk '{ print $6 - 100, $7 - 100, $8-$6 + 200, $9-$7 + 200 }' ) 

echo $geo_string for UNIT $UNIT

gdal_translate -ot UInt16  -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin $geo_string  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump.tif  $RAM/brokb_msk_clump${UNIT}_tmp.tif 
pkgetmask -ot UInt16 -co COMPRESS=DEFLATE -co ZLEVEL=9 -min $(echo $UNIT - 0.5 | bc) -max $(echo $UNIT + 0.5 | bc) -data $UNIT -nodata 0 -i $RAM/brokb_msk_clump${UNIT}_tmp.tif -o  $SC/lbasin_tiles_brokb_msk/brokb_msk_clump${UNIT}.tif 
gdal_edit.py  -a_nodata 0 $SC/lbasin_tiles_brokb_msk/brokb_msk_clump${UNIT}.tif ; rm  $RAM/brokb_msk_clump${UNIT}_tmp.tif 
cp   $SC/lbasin_tiles_brokb_msk/brokb_msk_clump${UNIT}.tif   $RAM/brokb_msk_clump${UNIT}.tif 

echo msk elv dep upa | xargs -n 1 -P 4 bash -c $' 
var=$1
gdal_translate -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -projwin $(getCorners4Gtranslate $SC/lbasin_tiles_brokb_msk/brokb_msk_clump${UNIT}.tif) $MERIT/${var}/all_tif.vrt $RAM/UNIT${UNIT}_${var}.tif
rm -f  $RAM/UNIT${UNIT}_${var}.vrt 
' _

gdal_edit.py  -a_nodata -9999  $RAM/UNIT${UNIT}_elv.tif ;     gdal_edit.py  -a_nodata -9999  $RAM/UNIT${UNIT}_upa.tif ; 
gdal_edit.py  -a_nodata 0      $RAM/UNIT${UNIT}_msk.tif ;     gdal_edit.py  -a_nodata 0      $RAM/UNIT${UNIT}_dep.tif ;

rm -fr $GRASS/loc_$UNIT 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh $GRASS loc_$UNIT $RAM/UNIT${UNIT}_msk.tif r.in.gdal

g.remove -f  type=raster name=UNIT${UNIT}_msk  
r.external  input=$RAM/UNIT${UNIT}_elv.tif     output=elv        --overwrite 
r.external  input=$RAM/brokb_msk_clump$UNIT.tif output=msk_brokb  --overwrite
r.external  input=$RAM/UNIT${UNIT}_msk.tif     output=msk        --overwrite
r.external  input=$RAM/UNIT${UNIT}_dep.tif     output=dep        --overwrite
r.external  input=$RAM/UNIT${UNIT}_upa.tif     output=upa        --overwrite

r.mask raster=msk  --o 

r.stream.extract elevation=elv accumulation=upa threshold=0.2 depression=dep  direction=dir  stream_raster=stream memory=90000 --o --verbose  ;  r.colors -r stream
g.remove -f  type=raster name=upa,elv,dep ; rm $RAM/UNIT${UNIT}_upa.tif $RAM/UNIT${UNIT}_elv.tif  $RAM/UNIT${UNIT}_dep.tif 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l -m stream_rast=stream  direction=dir  basins=lbasin  memory=98000 --o --verbose  ;  r.colors -r lbasin

g.region zoom=msk_brokb   --o  
r.mask raster=msk_brokb   --o

r.out.gdal --overwrite -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=lbasin  output=$SC/lbasin_unit_large/lbasin_brokb$UNIT.tif 
r.out.gdal --overwrite -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=stream  output=$SC/stream_unit_large/stream_brokb$UNIT.tif
r.out.gdal --overwrite -c -m createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int16  format=GTiff nodata=-10 input=dir   output=$SC/dir_unit_large/dir_brokb$UNIT.tif 

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

rm -fr $GRASS/loc_$UNIT  $RAM/UNIT${UNIT}*.tif $RAM/msk_brokb_clump$UNIT.tif

exit 
