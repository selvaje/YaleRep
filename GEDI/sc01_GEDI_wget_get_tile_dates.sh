#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH --job-name=sc01_GEDI_wget_get_tile_dates.sh
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_GEDI_wget_get_tile_dates.sh.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_GEDI_wget_get_tile_dates.sh.sh.%J.err
#SBATCH --mem=1G

#####   sc01_GEDI_wget_get_tile_dates.sh


cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/

rm index.html  folderlist.txt 
wget --user=el_selvaje  --password='Speleo_74'    https://e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.002/
awk -F "\""  '{ print substr($6,1,10)  }'  index.html  | grep -e "2020\." -e "2019\." > folderlist.txt

for FOLDER in $( cat folderlist.txt   ) ; do
wget --user=el_selvaje --password='Speleo_74' -O - -A.h5  https://e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.002/$FOLDER | grep h5 | grep -v .xml | awk -F "\""  '{ print $6 }' | grep h5 > H5_TXT_LIST/${FOLDER}_h5_list.txt 
done

cd H5_TXT_LIST/
for file in *_h5_list.txt ; do for H5 in $( cat $file ) ; do date=$(basename $file  _h5_list.txt) ; echo $date $H5  ; done  ; done  > folder_h5_list.txt 



# download all files 
# wget -P OUINP_DIR --user=el_selvaje  --password='Speleo_74'  -r -l1 -H -t1 -nd -N -np -A.h5 -erobots=off https://e4ftl01.cr.usgs.gov/GEDI/GEDI02_A.001/2019.04.18/ 
