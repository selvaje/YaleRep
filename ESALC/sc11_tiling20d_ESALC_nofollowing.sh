#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_tiling20d_ESALC.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_tiling20d_ESALC.sh.%A_%a.err
#SBATCH --array=1-116
#SBATCH --mem=20G

####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt   final number of tiles 116

#### sbatch --export=dir=LC71,year=1992,tifname=LC71_Y1998 --job-name=sc11_tiling20d_ESALC_LC71_Y1998.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc11_tiling20d_ESALC.sh

ulimit -c 0

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4

GRASS=/tmp
RAM=/dev/shm
ESALCSC=/gpfs/loomis/scratch60/sbsc/$USER/dataproces/ESALC
ESALCH=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
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

echo processing  $tifname 

GDAL_CACHEMAX=30000
GDAL_NUM_THREADS=2
GDAL_DISABLE_READDIR_ON_OPEN=TRUE

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
#### create a vrt with the same list order (from 1 to 59) of the flow accumulation 
#### anyway gdalinfo gives another order list inside
#### gdalinfo /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles_intb1/all_tif_dis.vrt 
#### gdalinfo  /gpfs/loomis/scratch60/sbsc/ga254/dataproces/ESALC/tmax_acc/2018/tmax_2018_04_intb.vrt
#### be sure that is always constant 

gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $ESALCSC/${dir}_acc/$year/${tifname}_intb.vrt $(for ID in $(seq 1 59) ; do ls  $ESALCSC/${dir}_acc/$year/intb/${tifname}_*${ID}_acc.tif ; done) 

gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $ESALCSC/${dir}_acc/$year/${tifname}_intb_5p.vrt $(for ID in $(seq 1 59) ; do ls  $ESALCSC/${dir}_acc/$year/intb/${tifname}_*${ID}_acc_5p.tif ; done)
gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r mean -tr 0.008333333333333 0.008333333333333   $ESALCSC/${dir}_acc/$year/${tifname}_intb_5p.vrt $ESALCSC/${dir}_acc/$year/${tifname}_intb_5p.tif
rm -r $ESALCSC/${dir}_acc/$year/${tifname}_intb_5p.vrt
else 
sleep 300
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata -9999999 -ot Float32 -projwin $ulx $uly $lrx $lry $ESALCSC/${dir}_acc/$year/${tifname}_intb.vrt $RAM/${tifname}_${tile}_acc.tif

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

pksetmask  -m $RAM/${tifname}_${tile}_acc.tif -msknodata -9999999 -nodata -9999999 -m  $RAM/flow_${tifname}_${tile}.tif  -msknodata -9999999 -nodata -9999999 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -ot Int32 -i $RAM/${tifname}_${tile}_acc_tmp.tif -o $ESALCH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif

echo ${tifname}_${tile}_acc.tif  $( pkstat -hist   -src_min -9999999.1 -src_max -9999998.9 -i $ESALCH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.tif  | awk '{ print $2 }' ) > /dev/shm/${tifname}_${tile}_acc.nd 

#### in case of no data put 0 ; the tiles is cover by full data value
awk '{ if($2=="") { print $1 , 0 } else {print $1 , $2 } }' /dev/shm/${tifname}_${tile}_acc.nd   > $ESALCH/${dir}_acc/$year/tiles20d/${tifname}_${tile}_acc.nd

rm -f $RAM/${tifname}_${tile}_acc.vrt $RAM/${tifname}_${tile}_acc_tmp.tif  $RAM/flow_${tifname}_${tile}_pos.tif  $RAM/flow_${tifname}_${tile}.tif /dev/shm/${tifname}_${tile}_acc.nd

if [ $SLURM_ARRAY_TASK_ID -eq $SLURM_ARRAY_TASK_MAX  ] ; then
sleep 1000

## rm -f  $ESALCSC/${dir}_acc/$year/intb/${tifname}_???_acc.tif 
#### 
sleep 1000  # to allow that the sc10 form other month are keep running.


# yearless=$( expr $year - 1 )
# echo   $ESALCSC/${dir}_acc/$yearless/intb/${dir}_Y${yearless}_*_acc.tif  
# rm  -f $ESALCSC/${dir}_acc/$yearless/intb/${dir}_Y${yearless}_*_acc.tif  ### rm accumualtion grass tiles of the previus 1 month  year

# yearplus=$( expr $year + 1 )
# for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC/${dir}/${dir}_Y${yearplus}.tif ; do for ID in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt  )  ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print $4}' ) ;  sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_ESALC_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc10_variable_accumulation_intb1_ESALC_forloop.sh ; sleep 2 ; done ; done  

gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $ESALCH/${dir}_acc/$year/${tifname}.vrt $ESALCH/${dir}_acc/$year/tiles20d/${tifname}_*_acc.tif
gdal_translate -a_nodata -9999999 -a_srs EPSG:4326 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r bilinear -tr 0.0083333333333 0.0083333333333 $ESALCH/${dir}_acc/$year/${tifname}.vrt $ESALCH/${dir}_acc/$year/${tifname}.tif 

fi

