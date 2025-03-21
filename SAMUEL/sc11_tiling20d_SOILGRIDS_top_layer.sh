#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 10 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /home/st929/output/sc11_tiling20d_SOILGRIDS.sh.%A_%a.out  
#SBATCH -e /home/st929/output/sc11_tiling20d_SOILGRIDS.sh.%A_%a.err
#SBATCH --array=1-116   ## usa
#SBATCH --mem=20G
SLURM_ARRAY_TASK_MIN=1  #1
SLURM_ARRAY_TASK_MAX=116  #116
####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116
#### sbatch --export=dir=AWCtS,tifname=AWCtS_WeigAver --job-name=sc11_tiling20d_SOILGRIDS_AWCtS_WeigAver.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc11_tiling20d_SOILGRIDS.sh
#### AWCtS_acc CLYPPT_acc SLTPPT_acc SNDPPT_acc WWP_acc
ulimit -c 0

VAR=$var
dir=$VAR
tifname=${VAR}_0-5cm


module load GDAL
module load GSL
module load Boost
module load PKTOOLS
module load Armadillo

#module load GDAL/3.1.0-foss-2018a-Python-3.6.4
#module load GSL/2.3-GCCcore-6.4.0
#module load Boost/1.66.0-foss-2018a
#module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
#module load Armadillo/8.400.0-foss-2018a-Python-3.6.4

GRASS=/tmp
RAM=/dev/shm
#SOILGRIDSSC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/SOILGRIDS
#SOILGRIDSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO


SOILGRIDSH=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess
SOILGRIDSSC=/gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess



find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

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

GDAL_CACHEMAX=30000
GDAL_NUM_THREADS=2
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [  $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MIN ] ; then 
#### create a vrt with the same list order (from 1 to 59) of the flow accumulation 
#### anyway gdalinfo gives another order list inside
#### gdalinfo /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles_intb1/all_tif_dis.vrt 
#### gdalinfo  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/SOILGRIDS/tmax_acc/2018/tmax_2018_04_intb.vrt
#### be sure that is always constant 
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSSC/${dir}_acc/${tifname}_intb.vrt \
$(ls $SOILGRIDSSC/${dir}_acc/${tifname}_*_acc.tif)

# Build VRT for all *_acc_5p.tif files in the folder
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSSC/${dir}_acc/${tifname}_intb_5p.vrt \
$(ls $SOILGRIDSSC/${dir}_acc/${tifname}_*_acc_5p.tif)

gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.0083333333333 0.0083333333333   $SOILGRIDSSC/${dir}_acc/${tifname}_intb_5p.vrt $SOILGRIDSSC/${dir}_acc/${tifname}_intb_10p.tif
rm -r $SOILGRIDSSC/${dir}_acc/${tifname}_intb_5p.vrt
else 
sleep 300
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata -9999999 -ot Float32 -projwin $ulx $uly $lrx $lry $SOILGRIDSSC/${dir}_acc/${tifname}_intb.vrt $RAM/${tifname}_${tile}_acc.tif

cp $HYDROSC/flow_tiles/flow_${tile}.tif $RAM/flow_${tifname}_${tile}.tif

### invert negative values of the flow accumulation
oft-calc -ot Float32   $RAM/flow_${tifname}_${tile}.tif  $RAM/flow_${tifname}_${tile}_pos.tif   <<EOF
1
#1 0 > #1 -1 * #1 ?
EOF

gdalbuildvrt -separate -overwrite $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc.tif $RAM/flow_${tifname}_${tile}_pos.tif
#### variable accumulation divided  flow accumulation
oft-calc -ot Float32  $RAM/${tifname}_${tile}_acc.vrt  $RAM/${tifname}_${tile}_acc_tmp.tif  <<EOF
1
#1 #2 /
EOF

mkdir -p $SOILGRIDSH/${dir}_acc/tiles20d

pksetmask  -m $RAM/${tifname}_${tile}_acc.tif -msknodata -9999999 -nodata -9999999 -m  $RAM/flow_${tifname}_${tile}.tif  -msknodata -9999999 -nodata -9999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot Int32 -i $RAM/${tifname}_${tile}_acc_tmp.tif -o $SOILGRIDSH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif

echo ${tifname}_${tile}_acc.tif  $( pkstat -hist   -src_min -9999999.1 -src_max -9999998.9 -i $SOILGRIDSH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc.nd 

#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc.nd   > $SOILGRIDSH/${dir}_acc/tiles20d/${tifname}_${tile}_acc.nd

rm -f $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc_tmp.tif  $RAM/flow_${tifname}_${tile}_pos.tif  $RAM/flow_${tifname}_${tile}.tif /dev/shm/${tifname}_${tile}_acc.nd

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then
sleep 1000
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSH/${dir}_acc/${tifname}.vrt $SOILGRIDSH/${dir}_acc/tiles20d/${tifname}_*_acc.tif
gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.0083333333333 0.0083333333333 $SOILGRIDSH/${dir}_acc/${tifname}.vrt $SOILGRIDSH/${dir}_acc/${tifname}.tif 
fi

