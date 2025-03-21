#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 6:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc39_basin_global_uniq_tiling20d.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc39_basin_global_uniq_tiling20d.sh.%A_%a.err
#SBATCH --job-name=sc39_basin_global_uniq_tiling20d.sh
#SBATCH --array=1-116
#SBATCH --mem=40G

####  1-116   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt   final number of tiles 116

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc39_basin_global_uniq_tiling20d.sh
#### sbatch --dependency=afterany:$(myq | grep sc38_basin_global_uniq_CompUnit.sh | awk '{print $1}' | uniq) /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc39_basin_global_uniq_tiling20d.sh

#    number of global sub-basin

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

export tile=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  ulx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  uly=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  lrx=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)
export  lry=$(awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_land_noheader.txt)

if [ $(echo " $ulx < -180 " | bc ) -eq 1 ] ; then export ulx=-180 ; fi 
if [ $(echo " $uly >   85 " | bc ) -eq 1 ] ; then export uly=85   ; fi 
if [ $(echo " $lrx >  180 " | bc ) -eq 1 ] ; then export lrx=180  ; fi 
if [ $(echo " $lry <  -60 " | bc ) -eq 1 ] ; then export lry=-60  ; fi 

#### expand 2 tiles over 180
if [ $tile = "h34v00" ] ; then export ulx=160 ; export uly=85 ; export  lrx=191 ; export lry=65 ;  fi
if [ $tile = "h34v02" ] ; then export ulx=160 ; export uly=65 ; export  lrx=191 ; export lry=45 ;  fi 

echo $ulx $uly $lrx $lry   $SCMH/lbasin_tiles_final20d/lbasin_$tile.tif 
export GDAL_CACHEMAX=10000

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then 
time gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $SCMH/CompUnit_basin_lbasin_clump_reclas/all_tif_dis.vrt $SCMH/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_*.tif

wc=$(for file in $SCMH/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_*_rec.txt ; do tail -n 1 $file ; done | sort -g -k 2,2 | tail -1 | awk '{  print $2  }' ) 
time  paste -d " " <(seq 0 $wc) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0 ; shuf -i 1-255 -n  $wc -r) | awk '{if(NR==1) { print $0,0} else {print $0,255}}' >   $SCMH/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_rec_all_ct.txt 

else 
sleep 400
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9  -a_nodata 0 -ot UInt32 -projwin $ulx $uly $lrx $lry $SCMH/CompUnit_basin_lbasin_clump_reclas/all_tif_dis.vrt $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif 

gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif 
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif 
gdal_edit.py -a_ullr   $ulx $uly $lrx $lry  $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif 
gdal_edit.py  -tr 0.000833333333333333333333333 -0.000833333333333333333333333  $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif 

##### create a uniq global stream-segment ID  

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $SCMH/stream_tiles_final20d_1p/stream_${tile}.tif -msknodata 0 -nodata 0  -i $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif  -o $SCMH/CompUnit_stream_uniq_tiles20d/stream_${tile}.tif

echo gdaldem 
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif $SCMH/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_rec_all_ct.txt  $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ct.tif

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES -alpha $SCMH/CompUnit_stream_uniq_tiles20d/stream_${tile}.tif $SCMH/CompUnit_basin_lbasin_clump_reclas/basin_lbasin_clump_rec_all_ct.txt  $SCMH/CompUnit_stream_uniq_tiles20d_ct/stream_${tile}_ct.tif

echo pkfilter 
export ND=0
echo 5 10 20 40 | xargs -n 1 -P 2 bash -c $' 
P=$1
pkfilter -nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte   -of GTiff -dx $P  -dy  $P -d  $P -f mode -i  $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ct.tif -o $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_${P}p_ct.tif

pkfilter -nodata $ND -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot UInt32 -of GTiff -dx $P  -dy  $P -d  $P  -f mode -i $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif -o $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_${P}p.tif

' _ 

echo  building tif with the overview 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt                 $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ct.tif       
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt.ovr             $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_5p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt.ovr.ovr         $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_10p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt.ovr.ovr.ovr     $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_20p_ct.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt.ovr.ovr.ovr.ovr $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_40p_ct.tif 

gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt                   $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}.tif       
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt.ovr               $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_5p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt.ovr.ovr           $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_10p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt.ovr.ovr.ovr       $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_20p.tif 
gdalbuildvrt -srcnodata $ND -vrtnodata $ND -overwrite $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt.ovr.ovr.ovr.ovr   $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_40p.tif 

GDAL_CACHEMAX=30000  
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.vrt $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ovr.tif

gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_${tile}_ctovr.vrt $SCMH/CompUnit_basin_uniq_tiles20d/basin_${tile}_ct_ovr.tif

if [ $SLURM_ARRAY_TASK_ID -eq  116                 ] ; then
sleep 4000
gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0   $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_10p_ct.vrt  $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_*_ctovr.vrt.ovr.ovr
gdal_translate -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES  $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_10p_ct.vrt $SCMH/CompUnit_basin_tiles20d/basin_10p_ct.tif

rm -f $SCMH/CompUnit_basin_uniq_tiles20d/basin_*_ovr.vrt*  $SCMH/CompUnit_basin_uniq_tiles20d_ct/basin_*_ctovr.vrt* $SCMH/CompUnit_basin_uniq_tiles20d/basin_??????_*p.tif $SCMH/CompUnit_basin_uniq_tiles20d/basin_??????_*_ct.tif

fi
