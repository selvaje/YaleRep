#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00       # 6 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc20_build_dem_location_HandsTilesBASINS_Flow_Continental.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc20_build_dem_location_HandsTilesBASINS_Flow_Continental.sh.%J.err
#SBATCH --mem=800G
#SBATCH  --job-name=sc20_build_dem_location_HandsTilesBASINS_Flow.sh 
ulimit -c 0


# source ~/bin/gdal3    2>  /dev/null
# source ~/bin/pktools  2>  /dev/null 
# module load GRASS/8.2.0-foss-2022b   2>  /dev/null


export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  


### gdal_translate --config GDAL_CACHEMAX 40000  -a_srs EPSG:4326 -co BIGTIFF=YES -co COMPRESS=DEFLATE -co ZLEVEL=9 -co INTERLEAVE=BAND  $MERIT/are/all_tif_dis.vrt    $MERIT/are/all_tif_dis.tif

cp $MERIT/are/all_tif_dis.tif /tmp/are.tif 
cp $SC/hydrography90m_v.1.0/r.watershed/direction_tiles20d/direction.tif   /tmp/dir.tif
cp $MERIT/msk/all_tif_dis.tif /tmp/msk.tif

#### export OMP_NUM_THREADS=4 usefull for r.accumulate multi tread 

apptainer exec --env=SC=$SC /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass85.sif bash -c "
/usr/local/grass-8.5/bin/grass -f --text --tmp-project /tmp/dir.tif <<'EOF'

r.external input=/tmp/are.tif output=are  --overwrite &
r.external input=/tmp/dir.tif output=dir  --overwrite &
r.external input=/tmp/msk.tif output=msk  --overwrite &
wait

r.mask raster=msk --o
OMP_NUM_THREADS=4  
r.flowaccumulation input=dir type=FCELL weight=are output=flow nprocs=4

r.mapcalc.tiled    'flow_int =  float(flow * 1000)'     nprocs=4   #### cell in grass  -2,147,483,648 to 2,147,483,647 so opt for float 

export GDAL_CACHEMAX=400G
### export GDAL_NUM_THREADS=4

##### Float32   Computed Min/Max= 0.001, 5 853 598.000 , * 1000 = 5 853 598 000    
r.out.gdal --o -f -c -m createopt='COMPRESS=DEFLATE,ZLEVEL=9,BIGTIFF=YES' nodata=-9999999 type=Float32  input=flow_int output=$SC/hydrography90m_v.1.0/r.watershed/accumulation_tiles20d/accumulation_sfd_int64T.tif

EOF
"


exit


first run 
CPU Utilized: 07:27:56
CPU Efficiency: 50.11% of 14:53:52 core-walltime
Job Wall-clock time: 07:26:56
Memory Utilized: 720.41 GB
Memory Efficiency: 90.05% of 800.00 GB
