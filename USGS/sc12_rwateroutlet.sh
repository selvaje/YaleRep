#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc12_rwateroutlet.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc12_rwateroutlet.sh.%A_%a.err
#SBATCH --mem=50G
#SBATCH --array=22,27,28,29,30,32,34,55,79,83,84,90,91

### for TH in 1 2 3 4 5 6 7 8 9 10 ; do sbatch --job-name=sc12_rwateroutlet_th$TH.sh --export=TH=$TH   /gpfs/gibbs/pi/hydro/hydro/scripts/USGS/sc12_rwateroutlet.sh ; done 

ulimit -c 0

####  get the comp ID for the USGS points
####  cd /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_msk 
####  for file in *.tif ; do echo $file $( gdallocationinfo  -geoloc -valonly $file    < <( awk '{  print $1, $2 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/USGS/txt_orig/x_y_usgs_h*v*.txt  )  | sort | uniq | grep 1 )  ; done | grep " 1" 

# ls msk_*_msk.tif | grep -n -e _14_ -e _155_ -e _156_ -e _157_ -e _158_ -e _15_ -e _161_ -e _180_ -e _20_ -e _24_ -e _25_ -e _30_ -e _31_ | awk -F : '{printf ("%i,",$1) }' 
# 22,27,28,29,30,32,34,55,79,83,84,90,91

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export USGS=/gpfs/gibbs/pi/hydro/hydro/dataproces/USGS
export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export TH=$TH 

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 4 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

## SLURM_ARRAY_TASK_ID=97  #####   ID 96 small area for testing 
### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   

#### SLURM_ARRAY_TASK_ID=84
export file=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_msk/msk_*_msk.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 ) 
export filename=$(basename $file .tif  )
export ID=$( echo $filename | awk '{ gsub("msk_","") ; gsub("_msk","") ; print }'   )

echo $file 

${ID}_th${TH}.txt 

echo  dir msk | xargs -n 1 -P 2 bash -c $'
var=$1
cp $SC/CompUnit_$var/${var}_${ID}_msk.tif  $RAM/${var}_${ID}_msk_th${TH}.tif 
' _ 

grass78  -f -text --tmp-location  -c $RAM/msk_${ID}_msk_th${TH}.tif  <<'EOF'

for var in dir msk ; do
r.external  input=$RAM/${var}_${ID}_msk_th${TH}.tif     output=$var       --overwrite  
done
r.mask raster=msk  --o 

####### https://grass.osgeo.org/grass79/manuals/r.water.outlet.html 
GRASS_VERBOSE=1

paste -d " " \
<( awk '{ print $1,$2,$3   }' /gpfs/gibbs/pi/hydro/hydro/dataproces/USGS/txt_snapFlow/x_y_snapFlowFinal_*_th${TH}.txt  ) \
<( gdallocationinfo -geoloc -valonly $file < <(awk '{print $1, $2}' /gpfs/gibbs/pi/hydro/hydro/dataproces/USGS/txt_snapFlow/x_y_snapFlowFinal_*_th${TH}.txt )) \
| awk '{ if ($4==1) print $1,$2,$3 }' | xargs -n 3 -P 4 bash -c $'

## $1 lon
## $2 lat
## $3 USGS ID
r.water.outlet input=dir output=$3 coordinates=$1,$2 --overwrite
r.report -hn  map=$3  units=k  output=/tmp/${3}_are_th${TH}.txt 
echo $3 $(grep TOTAL  /tmp/${3}_are_th${TH}.txt  | awk -F "|"  \'{ gsub(",","") ; print $3  }\' ) > $USGS/txt_catch/${3}_are_th${TH}.txt 
rm -r  /tmp/${3}_are_th${TH}.txt 
' _ 

EOF

if [ $SLURM_ARRAY_TASK_ID -eq 91 ] ; then 
sleep  3000   
cat  $USGS/txt_catch/USGS-[0-9]*_are_th${TH}.txt | sort -k 1,1 > $USGS/txt_catch/USGS-ID_are_th${TH}.txt
join -1 3 -2 1 -o 1.3,1.4,2.2 <(sort -k 3,3 $USGS/txt_orig/usgs_site_x_y.txt) $USGS/txt_catch/USGS-ID_are_th${TH}.txt > $USGS/txt_catch/USGS-ID_areOrig_areSnap_th${TH}.txt 

fi  
