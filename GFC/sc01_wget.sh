#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 2 -N 1
#SBATCH -t 6:00:00       # 6 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --job-name=sc01_wget.sh

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GFC/sc01_wget.sh

ulimit -c 0

### https://earthenginepartners.appspot.com/science-2013-global-forest/download_v1.7.html
### download version v1.7 

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GFC

cd $DIR/datamask

for file in $(cat $DIR/datamask.txt ) ; do 
wget $file 
done 

cd $DIR/treecover2000

for file in $(cat $DIR/treecover2000.txt ) ; do 
wget $file 
done 

