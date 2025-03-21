#!/bin/bash
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 10:00:00       # 
#SBATCH -o /gpfs/scratch60/fas/sbsc/zt226/stdout/sc04_GEDI_redownload_missing.sh.%J_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/zt226/stderr/sc04_GEDI_redownload_missing.sh.%J_%a.err
#SBATCH --job-name=sc04_GEDI_redownload_missing.sh
#SBATCH --mem=2G
#SBATCH --array=85-100
## 
# This script is to check DOWNLOAD_FAIL .txt files in GEDI

## --array=130,131,134-137,140-142,144,146-151,153,154,156


###### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc04_GEDI_redownload_missing.sh

#--- folder where the datasets are located
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export RAM=/dev/shm
export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $DIRAPI/date_2020.txt)
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export filename=${DATE}_h5_list.txt


cat <(diff $DIRAPI/H5_TXT_LIST/$filename  $OUP_H5/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- ) | xargs -n 1 -P 1 bash -c $' 
FILE=$1	

        # process the .h5 file
	wget --waitretry=4 --random-wait  -c -w 5 --no-remove-listing -P $OUP_H5 --user=toby_tang --password='Tzp19910908' https://e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/${DATE}/${FILE} -q
' _

rm $OUP_H5/DOWNLOAD_*_$DATE.txt

### check if all .h5 files downloaded well
ls $OUP_H5/GEDI02_A*.h5  | xargs -n 1 -P 1 bash -c $' 
H5_FILE=$1
h5ls $H5_FILE && echo $(basename $H5_FILE) >> $RAM/DOWNLOAD_DONE_$DATE.txt 
' _

diff $DIRAPI/H5_TXT_LIST/$filename  $RAM/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- >> $RAM/DOWNLOAD_FAIL_$DATE.txt

mv $RAM/DOWNLOAD_*_$DATE.txt $OUP_H5/

## check if the $OUP_H5/DOWNLOAD_FAIL_$DATE.txt is empty
[[ -s $OUP_H5/DOWNLOAD_FAIL_$DATE.txt ]] || rm $OUP_H5/DOWNLOAD_FAIL_$DATE.txt