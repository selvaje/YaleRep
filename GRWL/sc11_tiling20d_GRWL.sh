#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_tiling20d_GRWL.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_tiling20d_GRWL.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=25G

####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116

#### sbatch --export=dir=GRWL_canal,tifname=GRWL_canal  --job-name=sc11_tiling20d_GRWL_canal.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc11_tiling20d_GRWL.sh
#### for var in water river lake delta canal; do sbatch --export=dir=GRWL_${var},tifname=GRWL_$var --job-name=sc11_tiling20d_GRWL_${var}.sh /gpfs/gibbs/pi/hydro/hydro/scripts/GRWL/sc11_tiling20d_GRWL.sh; done

ulimit -c 0


module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4

GRASS=/tmp
RAM=/dev/shm
GRWLSC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/GRWL
GRWLH=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRWL
HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +6  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +6  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###   SLURM_ARRAY_TASK_ID=111

dir=$dir
tifname=$tifname
tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

if [ $tile =  h16v10 ] ; then exit 1 ; fi ### tile h16v10 complitly empity 

ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

echo processing  $tifname 

GDAL_CACHEMAX=15000
GDAL_NUM_THREADS=2
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
#### create a vrt with the same list order (from 1 to 59) of the flow accumulation 
#### anyway gdalinfo gives another order list inside
#### gdalinfo /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles_intb1/all_tif_dis.vrt 
#### gdalinfo  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/GRWL/tmax_acc/2018/tmax_2018_04_intb.vrt
#### be sure that is always constant 

gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $GRWLSC/${dir}_acc/${tifname}_intb.vrt    $(for ID in $(seq 1 59) ; do ls  $GRWLSC/${dir}_acc/intb/${tifname}_*${ID}_acc.tif ; done) 

gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $GRWLSC/${dir}_acc/${tifname}_intb_5p.vrt $(for ID in $(seq 1 59) ; do ls  $GRWLSC/${dir}_acc/intb/${tifname}_*${ID}_acc_5p.tif ; done)
gdal_translate -a_nodata -9999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.008333333333333 0.008333333333333   $GRWLSC/${dir}_acc/${tifname}_intb_5p.vrt $GRWLSC/${dir}_acc/${tifname}_intb_5p.tif
rm -r $GRWLSC/${dir}_acc/${tifname}_intb_5p.vrt
else 
sleep 300
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -a_nodata -9999 -ot Int32 -projwin $ulx $uly $lrx $lry $GRWLSC/${dir}_acc/${tifname}_intb.vrt $GRWLH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif 

## gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tifname}_${tile}_acc.tif
## gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/${tifname}_${tile}_acc.tif
## gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/${tifname}_${tile}_acc.tif
## gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333    $RAM/${tifname}_${tile}_acc.tif

## pksetmask  -m $RAM/${tifname}_${tile}_acc.tif -msknodata -9999 -nodata -9999 -m  $RAM/flow_${tifname}_${tile}.tif  -msknodata -9999 -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot Int32 -i $RAM/${tifname}_${tile}_acc_tmp.tif -o $GRWLH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif

echo ${tifname}_${tile}_acc.tif $(pkstat -hist -src_min -9999.1 -src_max -9998.9 -i $GRWLH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc.nd 

#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc.nd   > $GRWLH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.nd

rm -f $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc_tmp.tif  $RAM/flow_${tifname}_${tile}_pos.tif  $RAM/flow_${tifname}_${tile}.tif /dev/shm/${tifname}_${tile}_acc.nd

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then
sleep 2000

gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $GRWLH/${dir}_acc/${tifname}.vrt $GRWLH/${dir}_acc/tiles20d/${tifname}_*_acc.tif
gdal_translate -a_nodata -9999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.0083333333333 0.0083333333333 $GRWLH/${dir}_acc/${tifname}.vrt $GRWLH/${dir}_acc/${tifname}.tif 

fi

