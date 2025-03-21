#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 22:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc02_GEDI_download_all.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc02_GEDI_download_all.sh.%A_%a.err
#SBATCH --job-name=sc02_GEDI_download_all.sh
#SBATCH --mem=2G


######SBATCH --array=85-100
######  --array=54-84

# This script contains three steps
# 1) download all .H5 files into scratch60/sbsc/zt226/dataproces/GEDI/ folders
# 2) output DOWNLOAD_DONE and DOWNLOAD_FAIL txt files

##### narray=$(grep 2019.04 /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/date_2019.txt | wc -l )  ; sbatch  --export=YYYYMM=2019.04  --array=1-$narray /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc02_GEDI_download_all.sh 

source ~/bin/gdal3 
source ~/bin/pktools 

#--- folder where the datasets are located   # export DATE=2019.12.17
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export RAM=/dev/shm
# export DATE=$(awk 'NR=='${SLURM_ARRAY_TASK_ID}'' $DIRAPI/date_2019.txt)
export DATE=$( grep $YYYYMM  $DIRAPI/date_2019.txt | awk 'NR=='${SLURM_ARRAY_TASK_ID}''  )    ### YYYY.MM.DD
export check_DIR=${DATE}_h5_list
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI/$check_DIR
export filename=${DATE}_h5_list.txt

# download .h5 files 
echo downloading ${DATE}
wget -P $OUP_H5 --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -A.h5 -erobots=off e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/${DATE}/ -q 

# wget -P $OUP_H5 --user=toby_tang --password='Tzp19910908'  -r -l1 -H -t1 -nd -N -np -A.h5 -erobots=off e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/${DATE}/ -q

### check if all .h5 files downloaded well
rm -f $RAM/DOWNLOAD_DONE_$DATE.txt 
ls $OUP_H5/GEDI02_A*.h5  | xargs -n 1 -P 1 bash -c $' 
H5_FILE=$1
h5ls $H5_FILE && echo $(basename $H5_FILE) >> $RAM/DOWNLOAD_DONE_$DATE.txt 
' _  

# compare the DOWNLOAD .h5 and the total .h5 file
diff $DIRAPI/H5_TXT_LIST/$filename  $RAM/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- > $RAM/DOWNLOAD_FAIL_$DATE.txt

mv $RAM/DOWNLOAD_*_$DATE.txt $OUP_H5/

## check if the $OUP_H5/DOWNLOAD_FAIL_$DATE.txt is empty
if [ -s $OUP_H5/DOWNLOAD_FAIL_$DATE.txt ] ; then

rm -f $OUP_H5/DOWNLOAD_DONE_$DATE.txt

for H5_FILE in $(cat $OUP_H5/DOWNLOAD_FAIL_$DATE.txt  ) ; do
wget -P $OUP_H5 --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -A.h5 -erobots=off e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/${DATE}/$H5_FILE  -q
done

ls $OUP_H5/GEDI02_A*.h5  | xargs -n 1 -P 1 bash -c $' 
H5_FILE=$1
h5ls $H5_FILE && echo $(basename $H5_FILE) >> $RAM/DOWNLOAD_DONE_$DATE.txt 
' _ 

# compare the DOWNLOAD .h5 and the total .h5 file
diff $DIRAPI/H5_TXT_LIST/$filename  $RAM/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- > $RAM/DOWNLOAD_FAIL_$DATE.txt

mv $RAM/DOWNLOAD_*_$DATE.txt $OUP_H5/

else
rm -f $OUP_H5/DOWNLOAD_FAIL_$DATE.txt
fi

if [ -s $OUP_H5/DOWNLOAD_FAIL_$DATE.txt ] ; then

rm -f $OUP_H5/DOWNLOAD_DONE_$DATE.txt

for H5_FILE in $(cat $OUP_H5/DOWNLOAD_FAIL_$DATE.txt  ) ; do
wget -P $OUP_H5 --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -A.h5 -erobots=off e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/${DATE}/$H5_FILE  -q
done

ls $OUP_H5/GEDI02_A*.h5  | xargs -n 1 -P 1 bash -c $' 
H5_FILE=$1
h5ls $H5_FILE && echo $(basename $H5_FILE) >> $RAM/DOWNLOAD_DONE_$DATE.txt 
' _  

# compare the DOWNLOAD .h5 and the total .h5 file
diff $DIRAPI/H5_TXT_LIST/$filename  $RAM/DOWNLOAD_DONE_$DATE.txt | grep 'GEDI' | cut -d " " -f2- > $RAM/DOWNLOAD_FAIL_$DATE.txt

mv $RAM/DOWNLOAD_*_$DATE.txt $OUP_H5/

else
rm -f $OUP_H5/DOWNLOAD_FAIL_$DATE.txt
fi


if [ -s $OUP_H5/DOWNLOAD_FAIL_$DATE.txt ] ; then
echo $OUP_H5/DOWNLOAD_FAIL_$DATE.txt some files are still not  yet downloaded. 

else
rm -f $OUP_H5/DOWNLOAD_FAIL_$DATE.txt
fi 


sbatch --export=DATE=$DATE /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc05_GEDI_process_all_followDownload.sh 
