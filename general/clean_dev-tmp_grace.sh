#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 0:05:00
#SBATCH --array=1-1000
#SBATCH --mail-user=email
#SBATCH --job-name=clean_dev-tmp_grace.sh

find  /dev/shm/  -user $USER | xargs -n 1 -P 8 rm -ifr
find  /tmp/      -user $USER | xargs -n 1 -P 8 rm -ifr
