#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00  
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc38_basin_global_uniq_CompUnit.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc38_basin_global_uniq_CompUnit.sh.%A_%a.err
#SBATCH --job-name=sc38_basin_global_uniq_CompUnit.sh
#SBATCH --array=1-166
#SBATCH --mem=25G

####  1-166
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc38_basin_global_uniq_CompUnit.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.tif | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export filename=$(basename $file .tif  )
export tile=$(echo  $filename | tr  "_"  " "  | awk '{ print $4 }')
if [  $SLURM_ARRAY_TASK_ID -eq 1  ] ; then
export lastmaxb=0
time for filehist in  $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.hist   ; do 
export filenamehist=$(basename  $filehist  .hist  )

awk -v lastmaxb=$lastmaxb '{ if ($1==0) {print $1, 0} else { lastmaxb=1+lastmaxb; print $1, lastmaxb}}' $filehist > $SCMH/CompUnit_basin_lbasin_clump_reclas/${filenamehist}_rec.txt  
export lastmaxb=$(tail -1 $SCMH/CompUnit_basin_lbasin_clump_reclas/${filenamehist}_rec.txt  | awk '{ print $2  }')
done 

else
sleep 1000  # 16 min
fi 

GDAL_CACHEMAX=20000 

echo pkreclass  $SCMH/CompUnit_basin_lbasin_clump_reclas/${filename}_rec.txt $file  $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.tif
pkreclass -ot UInt32 -code $SCMH/CompUnit_basin_lbasin_clump_reclas/${filename}_rec.txt -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $file -o $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.tif
gdalinfo -mm  $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3), int($4) }'  > $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.mm

    #   ??? ??? ???  Chanel identifier                                           = awk '{ sum = sum + $2 } END {print sum}' CompUnit_stream_channel/channel_ident/channel_ident_*.mm
    #   726 723 221  CompUnit_stream_uniq_reclas or  overall global unique basin = awk '{ sum = sum + $2 } END {print sum}' CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.mm
    #  paste <(  ls  CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.mm ) <(cat  CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.mm | awk '{ print $2 }')  <(cat CompUnit_stream_channel/channel_ident/channel_ident_*.mm | awk '{ print $2 }'  )  | awk '{ print $1, $2-$3 }' 
    
# create a global segment stream ID 
pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $SCMH/CompUnit_lstream/lstream_${tile}_msk.tif -msknodata 0 -nodata 0  \
-i  $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.tif  -o $SCMH/CompUnit_stream_uniq_reclas/stream_uniq_$tile.tif
gdalinfo -mm  $SCMH/CompUnit_stream_uniq_reclas/stream_uniq_$tile.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3) , int($4) }'  > $SCMH/CompUnit_stream_uniq_reclas/stream_uniq_$tile.mm

gdal_edit.py  -a_nodata 0 -a_srs EPSG:4326  $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename.tif    
gdal_edit.py  -a_nodata 0 -a_srs EPSG:4326  $SCMH/CompUnit_stream_uniq_reclas/stream_uniq_$tile.tif

# gdal_edit.py -a_ullr  $(getCorners4Gtranslate  $file ) $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename   
# gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename   
# gdal_edit.py -a_ullr  $(getCorners4Gtranslate  $file ) $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename   
# gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 $SCMH/CompUnit_basin_lbasin_clump_reclas/$filename   

exit 


