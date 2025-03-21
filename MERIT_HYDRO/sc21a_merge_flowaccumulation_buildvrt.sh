#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21a_merge_flowaccumulation_buildvrt.sh.%A_%a.out    
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21a_merge_flowaccumulation_buildvrt.sh.%A_%a.err
#SBATCH --job-name=sc21a_merge_flowaccumulation_buildvrt.sh
#SBATCH --array=1-126
#SBATCH --mem=50G

####  1-126   # row number /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt   final number of tiles 116
              
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc21a_merge_flowaccumulation_buildvrt.sh
#### sbatch  --dependency=afterany:$(myq | grep   | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc21a_merge_flowaccumulation_buildvrt.sh 

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

export GDAL_CACHEMAX=20000

# flow accumulation 

if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then
gdalbuildvrt -overwrite -srcnodata -9999999 -vrtnodata -9999999 $SCMH/flow_tiles_intb1/all_tif_dis.vrt $(for ID in $(seq 1 59) ; do ls  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles_intb1/flow_*${ID}.tif ; done) 
else
sleep 100
fi

gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  -a_nodata -9999999 -ot Float32 -projwin $ulx $uly $lrx $lry $SCMH/flow_tiles_intb1/all_tif_dis.vrt  $RAM/flow_${tile}.tif 

gdal_edit.py -a_ullr  $ulx $uly $lrx $lry   $RAM/flow_${tile}.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/flow_${tile}.tif 
gdal_edit.py -a_ullr  $ulx $uly $lrx $lry  $RAM/flow_${tile}.tif 
gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333   $RAM/flow_${tile}.tif 

MAX=$(pkstat -max -i  $RAM/flow_${tile}.tif   | awk '{ print $2  }' )
echo $MAX  $RAM/flow_${tile}.tif 

if [ $MAX = "-1e+07"    ] ; then 
rm -f $RAM/flow_${tile}.tif 
else
#### invert the negative values for the accumulation of the variables. 
oft-calc -ot Float32 $RAM/flow_${tile}.tif $RAM/flow_${tile}_pos.tif <<EOF
1
#1 0 > #1 -1 * #1 ?
EOF

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/flow_${tile}.tif  -msknodata -9999999 -nodata  -9999999 -i $RAM/flow_${tile}_pos.tif -o $SCMH/flow_tiles/flow_${tile}_pos.tif
rm -f $RAM/flow_${tile}_pos.tif

# pkfilter -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  -ot Float32 -of GTiff -dx 4 -dy 4 -d 4 -f mean -i  $RAM/flow_$tile.tif -o $SCMH/flow_tiles/flow_${tile}_4p.tif
# pkfilter -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND -co TILED=YES  -ot Float32 -of GTiff -dx 10 -dy 10 -d 10 -f mean -i $RAM/flow_$tile.tif -o $SCMH/flow_tiles/flow_${tile}_10p.tif 
mv   $RAM/flow_${tile}.tif   $SCMH/flow_tiles/flow_${tile}.tif 
fi 

exit 

if [ $SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_MAX  ] ; then 

sbatch --dependency=afterany:$(squeue -u $USER -o "%.9F %.80j" | grep sc21a_merge_flowaccumulation_buildvrt.sh | awk '{ print $1  }' | uniq)  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc22_build_dem_location_HandsTilesBASINS_StreamLbasin.sh

sleep 30 
fi 


