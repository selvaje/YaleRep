#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc11_tiling20d_SOILGRIDS.sh.%A_%a.out  
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc11_tiling20d_SOILGRIDS.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=20G

### --array=1-116

####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116
#### sbatch --export=dir=clay,tifname=clay_60-100cm --job-name=sc11_tiling20d_SOILGRIDS_clay_60-100cm.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc11_tiling20d_SOILGRIDS.sh
#### for vrt  in /gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2/*/wgs84_250m_grow/clay_30-60cm.vrt ; do  dir=$(basename "$vrt" | cut -d'_' -f1) ;  tifname=$(basename "$vrt" .vrt) ; sbatch --export=dir=$dir,tifname=$tifname --job-name=sc11_tiling20d_SOILGRIDS_$tifname.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS2/sc11_tiling20d_SOILGRIDS.sh  ; done 


ulimit -c 0

source ~/bin/gdal3 &> /dev/null

export GRASS=/tmp
export RAM=/dev/shm
export SOILGRIDSSC=/vast/palmer/scratch/sbsc/hydro/dataproces/SOILGRIDS2  
export SOILGRIDSH=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS2
export HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###   SLURM_ARRAY_TASK_ID=111

export dir=$dir
export tifname=$tifname
export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

mkdir -p $SOILGRIDSH/${dir}/${dir}_acc/tiles20d
mkdir -p $SOILGRIDSSC/${dir}/${dir}_acc/intb

if [ $tile =  h16v10 ] ; then exit 1 ; fi ### tile h16v10 complitly empity 

ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

echo processing  $tifname 

GDAL_CACHEMAX=10000
GDAL_NUM_THREADS=2
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
#### create a vrt with the same list order (from 1 to 59) of the flow accumulation 
#### anyway gdalinfo gives another order list inside
#### gdalinfo /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles_intb1/all_tif_dis.vrt 
#### gdalinfo  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/SOILGRIDS/tmax_acc/2018/tmax_2018_04_intb.vrt
#### be sure that is always constant 
    
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb.vrt $(for ID in $(seq 1 59) ; do ls  $SOILGRIDSSC/${dir}/${dir}_acc/intb/${tifname}_*${ID}_acc.tif ; done) 

gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb_5p.vrt $(for ID in $(seq 1 59) ; do ls  $SOILGRIDSSC/${dir}/${dir}_acc/intb/${tifname}_*${ID}_acc_5p.tif ; done)
gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.0083333333333 0.0083333333333   $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb_5p.vrt $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb_10p.tif
rm -r $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb_5p.vrt
else 
sleep 300
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata -9999999 -ot Float32 -projwin $ulx $uly $lrx $lry $SOILGRIDSSC/${dir}/${dir}_acc/${tifname}_intb.vrt $RAM/${tifname}_${tile}_acc.tif

cp $HYDROSC/flow_tiles/flow_${tile}_pos.tif $RAM/flow_pos_${tifname}_${tile}.tif

### invert negative values of the flow accumulation

module load GRASS/8.2.0-foss-2022b &> /dev/null

grass  -f --text --tmp-location $RAM/flow_pos_${tifname}_${tile}.tif    <<'EOF' 
r.external  input=$RAM/flow_pos_${tifname}_${tile}.tif   output=flow_pos        --overwrite 
r.external  input=$RAM/${tifname}_${tile}_acc.tif        output=var_acc        --overwrite 

r.mapcalc 'acc_tmp =  float( var_acc / flow_pos)'

r.out.gdal --o -c -m -f  createopt="COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES" type=Int32  format=GTiff nodata=-9999999  input=acc_tmp  output=$RAM/${tifname}_${tile}_acc_tmp.tif  

EOF

source ~/bin/pktools &> /dev/null

pksetmask  -m $RAM/${tifname}_${tile}_acc.tif -msknodata -9999999 -nodata -9999999 -m  $RAM/flow_pos_${tifname}_${tile}.tif  -msknodata -9999999 -nodata -9999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot Int32 -i $RAM/${tifname}_${tile}_acc_tmp.tif -o $SOILGRIDSH/${dir}/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif

echo ${tifname}_${tile}_acc.tif  $( pkstat -hist   -src_min -9999999.1 -src_max -9999998.9 -i $SOILGRIDSH/${dir}/${dir}_acc/tiles20d/${tifname}_${tile}_acc.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc.nd 

#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc.nd   > $SOILGRIDSH/${dir}/${dir}_acc/tiles20d/${tifname}_${tile}_acc.nd

rm -f $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc_tmp.tif  $RAM/flow_${tifname}_${tile}_pos.tif  $RAM/flow_${tifname}_${tile}.tif /dev/shm/${tifname}_${tile}_acc.nd

if [ $SLURM_ARRAY_TASK_ID -eq 116  ] ; then
sleep 2000
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SOILGRIDSH/${dir}/${dir}_acc/${tifname}.vrt $SOILGRIDSH/${dir}/${dir}_acc/tiles20d/${tifname}_*_acc.tif
gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r nearest  -tr 0.0083333333333 0.0083333333333 $SOILGRIDSH/${dir}/${dir}_acc/${tifname}.vrt $SOILGRIDSH/${dir}/${dir}_acc/${tifname}_1km.tif 
fi

