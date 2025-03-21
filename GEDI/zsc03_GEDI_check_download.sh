#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 

#SBATCH -o /gpfs/scratch60/fas/sbsc/zt226/stdout/sc03_GEDI_check_download.sh.%J_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/zt226/stderr/sc03_GEDI_check_download.sh.%J_%a.err
#SBATCH --job-name=sc03_GEDI_check_download.sh
#SBATCH --mem=1G

## 
# This script is to check DOWNLOAD_FAIL .txt files in GEDI


##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc03_GEDI_check_download.sh
#--- folder where the datasets are located
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export RAM=/dev/shm

truncate -s 0 /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/DOWN_FAIL_DATE.txt

for ID in {1..100}; do
export DATE=$(awk 'NR=='${ID}'' $DIRAPI/date_2020.txt)
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export filename=${DATE}_h5_list.txt

# check the download and 
DIFF=$( diff $DIRAPI/H5_TXT_LIST/$filename  $OUP_H5/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- )
[[ ! -z "$DIFF" ]] && echo $ID $DIFF >> /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/DOWN_FAIL_DATE.txt
done
	
more /gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/DOWN_FAIL_DATE.txt
