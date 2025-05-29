#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 4:00:00    
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc99_loghest_path.sh_%j.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc99_loghest_path.sh_%j.err
#SBATCH --job-name=sc99_loghest_path.sh
#SBATCH --mem=10G

##### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc99_loghest_path.sh

export RAM=/dev/shm 

cp /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/dir_tiles_final20d_1p/dir_h20v04.tif        $RAM

module load GRASS/8.2.0-foss-2022b

grass  -f --text --tmp-location  $RAM/dir_h20v04.tif  <<'EOF'

r.external  input=$RAM/dir_h20v04.tif   output=dir --overwrite 

## 16.819,40.339 basento h18v04 
## 35.958,41.732 tur     h20v04

r.accumulate direction=dir  subwatershed=basin_bas  lfp=lfp_bas coordinates=35.958,41.732

g.region raster=basin_bas zoom=basin_bas

r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Byte format=GTiff nodata=0  input=basin_bas  output=/home/ga254/basin_tur.tif
v.out.ogr  --overwrite format=GPKG  input=lfp_bas  output=/home/ga254/lfp_tur.gpkg 

EOF

rm -f $RAM/dir_h18v04.tif 


exit

basento 
/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/ppt_acc/2011/tiles20d/ppt_2011_12_h18v04_acc.tif
/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_stream_uniq_tiles20d/stream_h18v04.tif
