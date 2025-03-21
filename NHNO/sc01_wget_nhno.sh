#!/bin/bash
#SBATCH --job-name=sc01_wget_nhno.sh
#SBATCH --ntasks=1 --nodes=1
#SBATCH --mem-per-cpu=5G
#SBATCH --time=12:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_wget_nhno.sh.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_wget_nhno.sh.%J.err

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/NHNO/sc01_wget_nhno.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/NHNO/

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHNO/sc01_wget_nhno.sh


wget http://store.pangaea.de/Publications/Nishina-etal_2017/FAOSTAT_ver1.zip
unzip FAOSTAT_ver1.zip
