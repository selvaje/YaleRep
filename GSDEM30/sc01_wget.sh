#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wget.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wget.sh.%J.err
#SBATCH --mem-per-cpu=2000

# sbatch ~/scripts/GSDEM30/sc01_wget.sh

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSDEM30/input
# rm -r *
wget -A .html  http://sendimage.whu.edu.cn/res/DEM_share/GSDEM30/
grep ","  index.html  | awk -F '"'  '{ print $8 }'  | grep N60   > list_dir.txt 

for DIR in $(cat list_dir.txt  ) ; do
wget -N -A .tif  -r   -e robots=off   --cut-dirs=3 --no-parent  -R "index.html*"    http://sendimage.whu.edu.cn/res/DEM_share/GSDEM30/$DIR

done 

exit

for DIR in $(cat list_dir.txt  ) ; do
mv  sendimage.whu.edu.cn/$DIR ../$(echo $DIR | awk -F "," '{  print $1"_"$2 }' | awk -F "=" '{  print $1  }' )
done 

rm -r sendimage.whu.edu.cn list_dir.txt index.html  
