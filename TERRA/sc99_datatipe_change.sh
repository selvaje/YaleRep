#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc99_datatipe_change.sh.%J.out  
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc99_datatipe_change.sh.%J.err
#SBATCH --job-name sc99_datatipe_change.sh 
#SBATCH --mem=32G

ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#### for YYYY  in $(seq 1958 2019 ) ; do   sbatch  --export=YYYY=$YYYY   /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc99_datatipe_change.sh  ; done 

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4
module load GRASS/7.8.0-foss-2018a-Python-3.6.4

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export TERRAH=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA 
export YYYY=$YYYY

ls $TERRAH/tmin_acc/$YYYY/tiles20d/tmin_${YYYY}_*_*_acc.tif | xargs -n 1 -P 4 bash -c $' 
file=$1
filename=$(basename $file .tif )

TYPE=$(gdalinfo  $file  | grep Type | awk \'{  print $4  }\' )

if   [  $TYPE = "Type=Int16,"   ] ; then 
echo $file no conversion 
else 
pksetmask  -m $file -msknodata -9999999 -nodata -9999 -ot Int16 -co COMPRESS=DEFLATE -co ZLEVEL=9   -i  $file -o $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}_tmp.tif 
mv $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}_tmp.tif  $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}.tif 

gdalinfo -mm $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}.tif | grep Computed | awk \'{ gsub(/[=,]/," ", $0 ); print $3 , $4 }\' > $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}.mm

echo ${filename}.tif $(pkstat -hist -src_min -9999.1 -src_max -9998.9 -i $TERRAH/tmin_acc/$YYYY/tiles20d/${filename}.tif | awk \'{ print $2 }\') > /dev/shm/${filename}.mm
awk \'{ if($2=="") { print $1,0} else {print $1 , $2 } }\' /dev/shm/${filename}.mm > $TERRAH/${dir}_acc/$year/tiles20d/${filename}.nd
rm /dev/shm/${filename}.mm

fi 

' _ 

