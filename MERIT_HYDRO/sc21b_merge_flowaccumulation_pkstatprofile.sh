#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 20:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21b_merge_flowaccumulation_pkstatprofile.sh.%A_%a.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21b_merge_flowaccumulation_pkstatprofile.sh.%A_%a.err
#SBATCH --job-name=sc21b_merge_flowaccumulation_pkstatprofile.sh
#SBATCH --array=1-126
#SBATCH --mem=50G

####  1-126   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt   final number of tiles 116
              
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc20b_merge_flowaccumulation.sh
#### sbatch  --dependency=afterany:$(myq | grep sc21_reclass_lbasin_stream_intb.sh  | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc20b_merge_flowaccumulation.sh

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

## SLURM_ARRAY_TASK_ID=111

export tile=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print $1      }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  ulx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($2) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  uly=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($3) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lrx=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($4) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )
export  lry=$( awk -v AR=$SLURM_ARRAY_TASK_ID '{ if(NR==AR)  print int($5) }' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt )

#### expand 2 tiles over 180

if [ $tile = "h34v00" ] ; then export ulx=160 ; export uly=85 ; export  lrx=191 ; export lry=65 ;  fi
if [ $tile = "h34v02" ] ; then export ulx=160 ; export uly=65 ; export  lrx=191 ; export lry=45 ;  fi 
### if [ $tile = "h34v02" ] ; then export ulx=160 ; export uly=60 ; export  lrx=170 ; export lry=50 ;  fi   ### for testing 

ls $SCMH/flow_tiles_intb/flow_???.tif $SCMH/flow_tiles_intb/flow_????.tif | xargs -n 1 -P 4 bash -c $'
file=$1
filename=$(basename $file .tif )

gdalbuildvrt -overwrite -te $ulx $lry $lrx  $uly -srcnodata -9999999 -vrtnodata -9999999  $RAM/${filename}_$tile.vrt    $file 

MAX=$(pkstat -max  -i   $RAM/${filename}_$tile.vrt   | awk \'{ print $2  }\' )
echo $MAX   $RAM/${filename}_$tile.vrt 
if [ $MAX = "-1e+07"    ] ; then rm -f $RAM/${filename}_$tile.vrt ; fi

' _ 

export GDAL_CACHEMAX=20000
export GDAL_NUM_THREADS=2

echo calculate mean  $RAM/flow_$tile.vrt $RAM/flow_*_$tile.vrt 

gdalbuildvrt -separate -overwrite -te $ulx $lry $lrx  $uly -srcnodata -9999999 -vrtnodata -9999999  $RAM/flow_$tile.vrt $RAM/flow_*_$tile.vrt 
pkstatprofile  -ot Float32   -co COMPRESS=DEFLATE -co ZLEVEL=9 -nodata -9999999 -f stdev -f nvalid  -i $RAM/flow_$tile.vrt -o $RAM/flow_$tile.tif 

gdal_translate -ot Byte    -a_nodata 0         -b 2    -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/flow_$tile.tif $SCMH/flow_tiles/flow_obs_$tile.tif &

gdal_translate -ot Float32 -a_nodata -9999999  -b 1    -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/flow_$tile.tif $RAM/flow_stdev_$tile.tif
pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -min -1 -max 9999999999999     -i $RAM/flow_stdev_$tile.tif -o  $RAM/flow_stdev_msk_$tile.tif
pksetmask -ot Float32 -m $RAM/flow_stdev_msk_$tile.tif -msknodata 0 -nodata -1 -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $RAM/flow_stdev_$tile.tif -o  $SCMH/flow_tiles/flow_stdev_$tile.tif

rm $RAM/flow_$tile.tif  $RAM/flow_*_$tile.vrt $RAM/flow_stdev_$tile.tif  $RAM/flow_stdev_msk_$tile.tif

