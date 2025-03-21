#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc20_build_dem_location_HandsTilesBASINS_Flow_pos.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20_build_dem_location_HandsTilesBASINS_Flow_pos.sh.%J.err

ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

### for ID in $(awk '{ print $1 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt) ; do MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  '{ print int($4 ) }' ) ;  sbatch  --export=ID=$ID --mem=${MEM}M --job-name=sc20_build_dem_location_HandsTilesBASINS${ID}_Flow_pos.sh   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc20_build_dem_location_HandsTilesBASINS_Flow_pos.sh ; done 

source /home/ga254/bin/gdal3
source /home/ga254/bin/pktools


export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

# find  /tmp/       -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  
# find  /dev/shm/   -user $USER    2>/dev/null  | xargs -n 1 -P 8 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

### maximum ram 66571M  for 2^63  (2 147 483 648 cell)  / 1 000 000  * 31 M   
#### greo G_malloc /gpfs/scratch60/fas/sbsc/ga254/stderr/sc20*
export file=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tile_??_ID${ID}.tif
export filename=$(basename $file .tif  )
export tile=$(echo $filename | tr "ID" " " | awk '{ print $2 }' )
export zone=$(echo $filename | tr "_" " "  | awk '{ print $2 }' )

echo $file 
echo coordinates $ulx $uly $lrx $lry

### invert negative values of the flow accumulation
oft-calc -ot Float64   $SC/flow_tiles_intb1/flow_${zone}${tile}.tif   $RAM/flow_${zone}${tile}_pos.tif   <<EOF
1
#1 0 > #1 -1 * #1 ?
EOF

pksetmask -ot Float64  -co COMPRESS=DEFLATE -co BIGTIFF=YES  -co ZLEVEL=9 -m $SC/flow_tiles_intb1/flow_${zone}${tile}_msk.tif -msknodata 0 -nodata  -9999999 -i  $RAM/flow_${zone}${tile}_pos.tif -o $SC/flow_tiles_intb1/flow_${zone}${tile}_pos.tif

echo "############################################################"
sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize
echo "############################################################"
sacct  -j   $SLURM_JOB_ID  --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
echo "############################################################"

