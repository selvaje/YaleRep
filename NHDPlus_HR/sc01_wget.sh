#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --job-name=sc01_wget.sh
#SBATCH --mem=5G

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc01_wget.sh

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/input

cat  /gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/input/data_wget.txt | grep _GDB   | xargs -n 1 -P 4 bash -c $'
wget $1  2>&1 | grep -i "error" 
' _ 

