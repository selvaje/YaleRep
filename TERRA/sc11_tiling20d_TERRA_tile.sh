#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc11_tiling20d_TERRA.sh.%A_%a.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc11_tiling20d_TERRA.sh.%A_%a.err
#SBATCH --array=75,76
#SBATCH --mem=23G

### select only the tiles array...
####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116
#### sbatch   --export=dir=tmin,year=1958,tifname=tmin_1958_01 --job-name=sc11_tiling20d_TERRA_tmin_1958_01.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc11_tiling20d_TERRA.sh

ulimit -c 0

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4

GRASS=/tmp
RAM=/dev/shm
TERRASC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/TERRA
TERRAH=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
HYDROSC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###   SLURM_ARRAY_TASK_ID=111

dir=$dir
year=$year
tifname=$tifname
tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

if [ $tile =  h16v10 ] ; then exit 1 ; fi ### tile h16v10 complitly empity 

ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )
lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt )

echo processing  $tifname  $tile 

GDAL_CACHEMAX=15000
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [  $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MIN   ] ; then 
#### create a vrt with the same list order (from 1 to 59) of the flow accumulation 
#### anyway gdalinfo gives another order list inside
#### gdalinfo /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_noDep_tiles_intb1/all_tif_dis.vrt 
#### gdalinfo  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/TERRA/tmax_acc/2018/tmax_2018_04_intb.vrt
#### be sure that is always constant 

mkdir -p $TERRAH/${dir}_acc/$year/tiles20d 
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $TERRASC/${dir}_acc/$year/${tifname}_intb.vrt $(for ID in $(seq 1 59) ; do ls  $TERRASC/${dir}_acc/$year/intb/${tifname}_*${ID}_acc.tif ; done) 
else 
sleep 60
fi 

if [ $dir = "swe" ] ; then type=Int32 ; fi  
if [ $dir = "tmin" ] || [ $dir = "tmax" ] || [ $dir = "ppt" ] ; then type=Int16 ; fi  

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then
ls $TERRASC/${dir}_acc/$year/intb/${tifname}_*_acc.tif > $TERRASC/${dir}_acc/$year/${tifname}_acc.ls
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $TERRASC/${dir}_acc/$year/${tifname}_intb_5p.vrt $(for ID in $(seq 1 59) ; do ls  $TERRASC/${dir}_acc/$year/intb/${tifname}_*${ID}_acc_5p.tif ; done)
gdal_translate -ot $type -a_nodata -9999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.0083333333333333 0.0083333333333333   $TERRASC/${dir}_acc/$year/${tifname}_intb_5p.vrt $TERRASC/${dir}_acc/$year/${tifname}_intb_10p.tif
rm -r $TERRASC/${dir}_acc/$year/${tifname}_intb_5p.vrt 
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES -a_nodata -9999 -projwin $ulx $uly $lrx $lry $TERRASC/${dir}_acc/$year/${tifname}_intb.vrt $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif

gdal_edit.py -a_ullr  $ulx $uly $lrx $lry $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif

### pksetmask -m $RAM/${tifname}_${tile}_acc.tif -msknodata -9999999 -nodata -9999 -m  $RAM/flow_${tifname}_${tile}_pos.tif  -msknodata -9999999 -nodata -9999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Int16 -i $RAM/${tifname}_${tile}_acc_tmp.tif -o $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif

gdalinfo -mm $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0 ); print $3, $4}'  > $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.mm

#################  in caso  full tile produce "terminate called after" 
echo ${tifname}_${tile}_acc.tif  $(pkstat -hist -src_min -9999.1 -src_max -9998.9 -i $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif | awk '{ print $2 }') > /dev/shm/${tifname}_${tile}_acc.nd 

#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc.nd   > $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.nd

rm -f $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc_tmp.tif  $RAM/flow_${tifname}_${tile}_pos.tif  $RAM/flow_${tifname}_${tile}.tif /dev/shm/${tifname}_${tile}_acc.nd

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then

month=${tifname: -2}
yearless=$( expr $year - 1 )
echo rm previus year   $TERRASC/${dir}_acc/$yearless/intb/${dir}_${yearless}_${month}_*_acc.tif  
rm  -f $TERRASC/${dir}_acc/$yearless/intb/${dir}_${yearless}_${month}_*_acc.tif  ### rm accumualtion grass tiles of the previus 1 month  year
rm  -f $TERRASC/${dir}_acc/$yearless/intb/${dir}_${yearless}_${month}_*_acc_5p.tif  ### rm accumualtion grass tiles of the previus 1 month  year

if [ $year -lt 2019 ] ; then 
yearplus=$( expr $year + 1 )
for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}/${dir}_${yearplus}_${month}.tif ; do for ID  in 37 38 39 40 41 ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print int($4)   }' ) ;  sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_TERRA_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_forloop_tile.sh ; sleep 2 ; done ; done 
fi

sleep 4000  # to allow that the sc10 form other month are keep running.
gdalbuildvrt -overwrite -srcnodata -9999 -vrtnodata -9999 $TERRAH/${dir}_acc/$year/${tifname}.vrt $TERRAH/${dir}_acc/$year/tiles20d/${tifname}_*_acc.tif

gdal_translate -a_nodata -9999 -ot $type -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r average -tr 0.0083333333333333333333 0.0083333333333333333333 $TERRAH/${dir}_acc/$year/${tifname}.vrt $TERRAH/${dir}_acc/$year/${tifname}_10p.tif 

gdalinfo -mm  $TERRAH/${dir}_acc/$year/${tifname}_10p.tif  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print $3 , $4 }'  >  $TERRAH/${dir}_acc/$year/${tifname}_10p.mm

ls $TERRAH/${dir}_acc/$year/tiles20d/${dir}_${year}_${month}_*_acc.tif | wc -l  > $TERRAH/${dir}_acc/$year/${dir}_${year}_${month}_acc.ls

fi

