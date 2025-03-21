#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh.%A_%a.out   
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh.%A_%a.err
#SBATCH --job-name=sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh
#SBATCH --array=1-166
#SBATCH --mem=20G

####  1 1-166
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$( ls   $SCMH/lbasin_compUnit_large/bid*_msk.tif $SCMH/lbasin_compUnit_tiles/bid*_msk.tif | head -$SLURM_ARRAY_TASK_ID   | tail -1 )     # 166 files 
export NN=$( basename $file _msk.tif | awk '{gsub("bid","") ; print }'  )   
export filename=$( basename $file  .tif  ) 
export DIR=$( dirname $file ) 

echo $file $NN

export GDAL_CACHEMAX=4000

echo buidlvrt 
cd  $SCMH 

if [ $SLURM_ARRAY_TASK_ID = 1  ] ; then  
wc=$(  wc -l $SCMH/lbasin_tiles_final20d_1p/uniq_computational_unit.txt | awk '{ print $1 -1  }' )
paste -d " " $SCMH/lbasin_tiles_final20d_1p/uniq_computational_unit.txt <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0; shuf -i 1-255 -n $wc -r) <(echo 0 ; shuf -i 1-255 -n $wc -r) | awk '{ if (NR==1) {print $0 , 0} else { print $0 , 255 }}'  > $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.txt
else 
sleep 60 
fi 
####### $(pkinfo -te -i $file) 
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite $RAM/no_$filename.vrt $(ls lbasin_compUnit_large/bid*_msk.tif lbasin_compUnit_tiles/bid*_msk.tif | grep -v $filename)
gdalbuildvrt -srcnodata 0 -vrtnodata 0 -overwrite $RAM/msk_$filename.vrt /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/msk/all_tif_dis.vrt

gdalinfo $RAM/no_$filename.vrt
gdalinfo $RAM/msk_$filename.vrt

# gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  $RAM/no_$filename.vrt
# gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/no_$filename.vrt

# gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  $RAM/msk_$filename.vrt
# gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/msk_$filename.vrt

# all number of compunit escluded the running one
gdal_translate -projwin $(getCorners4Gtranslate $file) -a_ullr  $(getCorners4Gtranslate $file)  -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/no_$filename.vrt  $RAM/no_$filename.tif   
# mask water 
gdal_translate -projwin $(getCorners4Gtranslate $file) -a_ullr  $(getCorners4Gtranslate $file)  -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/msk_$filename.vrt $RAM/msk_$filename.tif  

gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  $RAM/no_$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/no_$filename.tif

gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  $RAM/msk_$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/msk_$filename.tif

cp $RAM/no_$filename.tif   ${DIR}_enlarg/
cp $RAM/msk_$filename.tif  ${DIR}_enlarg/

pkstat -hist -i  $RAM/no_$filename.tif   | grep -v " 0" > ${DIR}_enlarg/no_$filename.hist
pkstat -hist -i  $RAM/msk_$filename.tif  | grep -v " 0" > ${DIR}_enlarg/msk_$filename.hist

gdalinfo $RAM/no_$filename.vrt
gdalinfo $RAM/msk_$filename.vrt
                                                                                                                                                 ## to inclued also the 1
pksetmask -ot Byte -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $RAM/no_$filename.tif -msknodata 0.99 -p ">" -nodata 0 -i $RAM/msk_$filename.tif -o  $RAM/$filename.tif

gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  $RAM/$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  $RAM/$filename.tif

gdalinfo  $RAM/$filename.tif
####   cp $RAM/$filename.tif $SCMH/tmp/
pkreclass -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -c 1 -r $NN  -nodata 0 -i $RAM/$filename.tif  -o ${DIR}_enlarg/$filename.tif

gdal_edit.py  -tr  0.00083333333333333333333  -0.00083333333333333333333  ${DIR}_enlarg/$filename.tif
gdal_edit.py -a_ullr  $(getCorners4Gtranslate $file)  ${DIR}_enlarg/$filename.tif

pkstat -hist -i  ${DIR}_enlarg/$filename.tif   | grep -v " 0"  >  ${DIR}_enlarg/$filename.hist

gdalinfo ${DIR}_enlarg/$filename.tif
rm $RAM/$filename.tif $RAM/no_$filename.vrt  $RAM/msk_$filename.vrt  $RAM/no_$filename.tif  $RAM/msk_$filename.tif

## applay ct
gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -co COPY_SRC_OVERVIEWS=YES -alpha ${DIR}_enlarg/$filename.tif  $SCMH/lbasin_compUnit_overview/lbasin_compUnit_enlarg_ct.txt ${DIR}_enlarg_ct/$filename.tif

exit 

if [ $SLURM_ARRAY_TASK_ID = $SLURM_ARRAY_TASK_MAX  ] ; then 
sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j"  | grep sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh   | awk '{ print $1  }' | uniq)   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc33_merge20d_1-40p_ct_compUnit_enlarg.sh

sleep 30

sbatch --dependency=afterany:$( squeue -u $USER -o "%.9F %.80j"  | grep sc32_tiling20d_lbasin_oftbb_TilesLarge_enlargment.sh   | awk '{ print $1  }' | uniq)   /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc36_compUnit_base_variable.sh 

sleep 30
fi 
