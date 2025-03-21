#!/bin/bash
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 3:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc_temp.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc_temp.sh.%A_%a.err
#SBATCH --job-name=sc_temp.sh
#SBATCH --mem=6G

######  --array=54-84

# This script contains three steps
# 1) download all .H5 files into scratch60/sbsc/zt226/dataproces/GEDI/ folders
# 2) output DOWNLOAD_DONE and DOWNLOAD_FAIL txt files

##### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc_temp.sh

source ~/bin/gdal3 
source ~/bin/pktools 

#--- folder where the datasets are located   # export DATE=2019.12.17
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export RAM=/dev/shm


cat $DIRAPI/date_2019.txt | xargs -n 1 -P 4 bash -c $' 
DATE=$1
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export filename=${DATE}_h5_list.txt

## 
if test -f "$OUP_H5/DOWNLOAD_DONE_$DATE.txt"; then
    echo "$OUP_H5/DOWNLOAD_DONE_$DATE.txt exists."
else

### check if all .h5 files downloaded well
for H5_FILE in $OUP_H5/GEDI02_A*_detailed.txt;  do
FILE=$(basename $H5_FILE _detailed.txt ).h5
echo $FILE >> $RAM/DOWNLOAD_DONE_$DATE.txt 
done

# compare the DOWNLOAD .h5 and the total .h5 file

diff $DIRAPI/H5_TXT_LIST/$filename  $RAM/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- >> $RAM/DOWNLOAD_FAIL_$DATE.txt

mv $RAM/DOWNLOAD_*_$DATE.txt $OUP_H5/

## check if the $OUP_H5/DOWNLOAD_FAIL_$DATE.txt is empty
[[ -s $OUP_H5/DOWNLOAD_FAIL_$DATE.txt ]] || rm $OUP_H5/DOWNLOAD_FAIL_$DATE.txt

fi
' _
