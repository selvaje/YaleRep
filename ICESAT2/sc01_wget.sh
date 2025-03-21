#!/bin/bash 
#SBATCH -n 1 -c 6 -N 1 
#SBATCH -t 4:00:00 
#SBATCH --job-name=sc01_wget.sh 
#SBATCH -p day 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc01_wget.sh.%J.out 
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc01_wget.sh.%J.err 
#SBATCH --mem=10g 


### --array=1

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc01_wget.sh

export OUT_FD=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2

rm -f $OUT_FD/index.html  $OUT_FD/folderlist_004.txt 

ssh transfer-grace  "wget --user=el_selvaje  --password=Speleo_74  -P /gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/  https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/"   
awk -F "\""  '{ print substr($6,1,10)  }' $OUT_FD/index.html  | grep -e "2020\." -e "2018\." -e "2019\." > /gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/folderlist_004.txt

echo start the loop 

rm -f $OUT_FD/index.html
mkdir -p $OUT_FD/H5_TXT_LIST_004

cat $OUT_FD/folderlist_004.txt   | xargs -n 1 -P 6 bash -c $'
## for FOLDER in $( cat $OUT_FD/folderlist_004.txt   ) ; do
ssh transfer-grace "wget  --user=el_selvaje --password=Speleo_74 -P $OUT_FD/H5_TXT_LIST_004  -A.h5  https://n5eil01u.ecs.nsidc.org/ATLAS/ATL08.004/$FOLDER  -q"
grep h5 $OUT_FD/H5_TXT_LIST_004/$FOLDER    | awk -F "\\""  \'{ print $6 }\' | grep h5  > $OUT_FD/H5_TXT_LIST_004/${FOLDER}_h5_list_004.txt
' _ 
