#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc98_correct_equi7proj.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc98_correct_equi7proj.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc98_correct_equi7proj.sh

### sbatch /gpfs/loomis/home.grace/ga254/scripts/MERIT/sc98_correct_equi7proj.sh 

ulimit -c 0

source ~/bin/gdal3

module load Rclone/1.53.0

rclone mount --daemon remote: /gpfs/loomis/project/sbsc/hydro/dataproces/GDRIVEGA
sleep 60 
 
for DIR in slope ; do ### aspect aspect-sine cti dev-scale dxx dy eastness geom pcurv roughness tcurv tri aspect-cosine convergence  dev-magnitude dx dxy dyy elev-stdev northness rough-magnitude rough-scale spi tpi vrm  ; do 

rclone copy remote:geomorpho90m_v.1.0/geomorphometry_100m_equi7/$DIR   /gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT/${DIR}_100

for CT in EU AN AS AD NA OC SA ; do 
for file in   /gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT/${DIR}_100/${DIR}_100M_MERIT_${CT}*.tif ; do 
gdal_edit.py -a_srs /gpfs/loomis/project/sbsc/ga254/dataproces/EQUI7/grids/${CT}/PROJ/EQUI7_V13_${CT}_PROJ_TILE_T3.prj $file
done 
done

# rclone copy /gpfs/loomis/scratch60/sbsc/ga254/dataproces/MERIT/${DIR}_100  remote:geomorpho90m_v.1.0/geomorphometry_100m_equi7/$DIR
done 




