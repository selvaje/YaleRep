#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 7:00:00       # 6 hours 
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc30_translate_vrt.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc30_translate_vrt.%J.err
#SBATCH --mem=20G
ulimit -c 0

################# r.watershed   98 000 mega and cpu 120 000  

#  1-59  IDtif    ### 22 small island on the north of russia   ###    25 & 26 east asia for testing 
#                                                        constrain up to 2016 as in GSIM. TERRA goes until 2018
### 48 last ID in the tileComp_size_memory.txt usefull to start sc11
#### for tif in  /gpfs/scratch60/fas/sbsc/ga254/dataproces/TERRA/tmin_acc/2015/intb/tmin_2015_12_*_acc.tif ; do sbatch  --export=tif=$tif /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc30_translate_vrt.sh ; done 

### for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/tmin_acc/2013/*.vrt ; do sbatch --export=tif=$tif /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc30_translate_vrt.sh ; done
### cat /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc/no_following.txt | xargs -n 3 -P 1 bash -c $' sbatch --export=tif=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc/${2}/soil_${2}_${3}.vrt /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc30_translate_vrt.sh ' _

module load GDAL/3.1.0-foss-2018a-Python-3.6.4
module load GSL/2.3-GCCcore-6.4.0
module load Boost/1.66.0-foss-2018a
module load PKTOOLS/2.6.7.6-foss-2018a-Python-3.6.4
module load Armadillo/8.400.0-foss-2018a-Python-3.6.4

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

SC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/TERRA/tmin_acc
GDAL_CACHEMAX=15000

gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -r bilinear -tr 0.0083333333333 0.0083333333333  $tif $(dirname $tif)/$(basename $tif .vrt).tif
