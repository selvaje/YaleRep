#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 8:00:00       # 
#SBATCH -o /gpfs/scratch60/fas/sbsc/zt226/stdout/sc08_rclone_to_googledrive.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/zt226/stderr/sc08_rclone_to_googledrive.sh.%A_%a.err
#SBATCH --job-name=sc08_rclone_to_googledrive.sh
#SBATCH --mem=5G
#SBATCH --array=1-157
######  --array=189-231

### you do not need the array ... 

# rclone copy  path/*/*_detailed.txt  TobyData:H5_files/     



# This script copies .h5 files from the cluster to the google drive

module load GDAL/3.1.0-foss-2018a-Python-3.6.4


##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc08_rclone_to_googledrive.sh

#--- folder where the datasets are located  # export DATE=2019.11.01

export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $INP_DIR/date_2019.txt)
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR

############# move only the  *_detailed.txt 
rclone copy --fast-list --include=*detailed.txt  $OUP_H5    TobyData:Tree_Height/$DATE --transfers=40 --checkers=40 --tpslimit=10 --drive-chunk-size=1M --max-backlog 200000 --verbose --log-file=/gpfs/loomis/scratch60/sbsc/zt226/stdout/$DATE.log 

exit 