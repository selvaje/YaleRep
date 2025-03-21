#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 4:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc24_tiling20d_lbasin.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc24_tiling20d_lbasin.sh.%A_%a.err
#SBATCH --job-name=sc24_tiling20d_lbasin.sh
#SBATCH --array=1-126
#SBATCH --mem=50G

####  1-126   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt   final number of tiles 116

#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc24_tiling20d_lbasin.sh
#### sbatch  --dependency=afterany:$(myq | grep sc21_reclass_lbasin_stream_intb.sh  | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc22_tiling20d_lbasin_sieve2.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

###   SLURM_ARRAY_TASK_ID=111

export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )

if [ $(echo " $ulx < -180 " | bc ) -eq 1 ] ; then export ulx=-180 ; fi 
if [ $(echo " $uly >   85 " | bc ) -eq 1 ] ; then export uly=85   ; fi 
if [ $(echo " $lrx >  180 " | bc ) -eq 1 ] ; then export lrx=180  ; fi 
if [ $(echo " $lry <  -60 " | bc ) -eq 1 ] ; then export lry=-60  ; fi 

#### expand 2 tiles over 180
if [ $tile = "h34v00" ] ; then export ulx=160 ; export uly=85 ; export  lrx=191 ; export lry=65 ;  fi
if [ $tile = "h34v02" ] ; then export ulx=160 ; export uly=65 ; export  lrx=191 ; export lry=45 ;  fi 

echo $ulx $uly $lrx $lry   $SCMH/lbasin_tiles_final20d/lbasin_$tile.tif 
export GDAL_CACHEMAX=30000
export GDAL_NUM_THREADS=2

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $SCMH/lbasin_tiles_intb_reclass2/all_tif_dis.vrt $SCMH/lbasin_tiles_intb_reclass2/lbasin_???.tif $SCMH/lbasin_tiles_intb_reclass2/lbasin_????.tif

echo lbasin basin stream outlet | xargs -n 1 -P 2 bash -c $'
var=$1
gdalbuildvrt -overwrite -srcnodata 0  -vrtnodata 0  $SCMH/${var}_tiles_intb2/all_tif_dis.vrt $SCMH/${var}_tiles_intb2/${var}_???.tif $SCMH/${var}_tiles_intb2/${var}_????.tif
' _ 

gdalbuildvrt -overwrite -srcnodata -10  -vrtnodata -10  $SCMH/dir_tiles_intb2/all_tif_dis.vrt  $SCMH/dir_tiles_intb2/dir_rs_???.tif   $SCMH/dir_tiles_intb2/dir_rs_????.tif
else 
sleep 300
fi

rm -f $SCMH/lbasin_tiles_final20d/lbasin_$tile.tif                                                                                                               # -projwin  ulx  uly  

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -co NUM_THREADS=2 -a_nodata 0 -ot UInt32 -projwin $ulx $uly $lrx $lry $SCMH/lbasin_tiles_intb_reclass2/all_tif_dis.vrt $RAM/lbasin_${tile}.tif 

gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $RAM/lbasin_${tile}.tif 
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $RAM/lbasin_${tile}.tif
gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $RAM/lbasin_${tile}.tif 
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $RAM/lbasin_${tile}.tif


MAX=$(pkstat -max  -i $RAM/lbasin_${tile}.tif    | awk '{ print int($2)  }' )
if [ $MAX -eq 0   ] ; then 
rm -f $RAM/lbasin_${tile}.tif 
else
pkstat --hist -i $RAM/lbasin_${tile}.tif | grep -v " 0" > $SCMH/lbasin_tiles_final20d/lbasin_${tile}.hist
mv  $RAM/lbasin_${tile}.tif  $SCMH/lbasin_tiles_final20d/lbasin_${tile}.tif # follow up with another reclass and save in lbasin_tiles_final20d_1p


### directly save in *_tiles_final20d_1p

echo basin stream outlet dir | xargs -n 1 -P 2 bash -c $'
var=$1
if [ $var = basin  ]  ; then ND=0   ; TYPE=UInt32 ; fi
if [ $var = stream ]  ; then ND=0   ; TYPE=UInt32 ; fi
if [ $var = outlet ]  ; then ND=0   ; TYPE=Byte   ; fi
if [ $var = dir    ]  ; then ND=-10 ; TYPE=Int16  ; fi

GDAL_CACHEMAX=20000
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES -a_nodata $ND -ot $TYPE -projwin $ulx $uly $lrx $lry $SCMH/${var}_tiles_intb2/all_tif_dis.vrt $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif   

gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif   
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif   
gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif   
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif   

pkstat --hist -i $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.tif | grep -v " 0" > $SCMH/${var}_tiles_final20d_1p/${var}_${tile}.hist
' _ 

fi

if [ $SLURM_ARRAY_TASK_ID -eq  $SLURM_ARRAY_TASK_MAX  ] ; then
sbatch  --dependency=afterany:$(squeue -u $USER -o "%.9F %.10K %.4P %.80j %3D%2C%.8T %.9M  %.9l  %.S  %R" | grep sc24_tiling20d_lbasin.sh | awk '{ print $1  }' | uniq )  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc25_tiling20d_ct_table_create.sh 
sleep 30
fi
