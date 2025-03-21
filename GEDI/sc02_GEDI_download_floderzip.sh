#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc02_GEDI_download_floderzip.sh.%A_%a.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc02_GEDI_download_floderzip.sh.%A_%a.err
#SBATCH --job-name=sc02_GEDI_download_floderzip.sh
#SBATCH --mem=1G
#SBATCH --array=1-4%2

####  --array=1-588
## sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc02_GEDI_download_floderzip.sh

export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export RAM=/dev/shm
export DATE=$( head -n $SLURM_ARRAY_TASK_ID $DIRAPI/date_2019_2020.txt | tail -1  )   
export OUP_H5=/gpfs/loomis/scratch60/sbsc/ga254/dataproces/GEDI/GEDI02_A.002/$DATE

mkdir -p $OUP_H5
# download .h5 files 
echo downloading ${DATE}
wget -P $OUP_H5 --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -c  --waitretry=30  --tries=5    -erobots=off -S   e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.002/${DATE}.zip   --progress=bar:force:noscroll

exit 

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
