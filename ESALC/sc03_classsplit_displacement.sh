#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 6 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_classsplit_displacement.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_classsplit_displacement.sh.%A.%a.err
#SBATCH --job-name=sc03_classsplit_displacement.sh
#SBATCH --mem=80G
#SBATCH --array=1-27

###  1-27 

source ~/bin/gdal3
source ~/bin/pktools

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC/sc03_classsplit_displacement.sh

###  create folders first to store dummy variables with the year as the name of the folder
###  cd /gpfs/gibbs/pi/hydro/hydro/dataproces/LCESA/
###  mkdir {1992..2018}

###    LAND COVER CATEGORIES

# 0   No data
# 10  Cropland, rainfed
# 11  Herbaceous cover
# 12  Tree or shrub cover
# 20  Cropland, irrigated or post-flooding
# 30  Mosaic cropland (>50%) / natural vegetation (tree, shrub, herbaceous cover) (<50%)
# 40  Mosaic natural vegetation (tree, shrub, herbaceous cover) (>50%) / cropland (<50%) 
# 50  Tree cover, broadleaved, evergreen, closed to open (>15%)
# 60  Tree cover, broadleaved, deciduous, closed to open (>15%)
# 61  Tree cover, broadleaved, deciduous, closed (>40%)
# 62  Tree cover, broadleaved, deciduous, open (15-40%)
# 70  Tree cover, needleleaved, evergreen, closed to open (>15%)
# 71  Tree cover, needleleaved, evergreen, closed (>40%)
# 72  Tree cover, needleleaved, evergreen, open (15-40%)
# 80  Tree cover, needleleaved, deciduous, closed to open (>15%)
# 81  Tree cover, needleleaved, deciduous, closed (>40%)
# 82  Tree cover, needleleaved, deciduous, open (15-40%)           # very few pixel aggregate with 81  - file name LC81_Y*.tif
# 90  Tree cover, mixed leaf type (broadleaved and needleleaved)
# 100 Mosaic tree and shrub (>50%) / herbaceous cover (<50%)
# 110 Mosaic herbaceous cover (>50%) / tree and shrub (<50%)
# 120 Shrubland
# 121 Shrubland evergreen
# 122 Shrubland deciduous
# 130 Grassland
# 140 Lichens and mosses
# 150 Sparse vegetation (tree, shrub, herbaceous cover) (<15%)
# 151 Sparse tree (<15%)                                           # very few pixel aggregate with 150  - file name LC150_Y*.tif
# 152 Sparse shrub (<15%)
# 153 Sparse herbaceous cover (<15%)
# 160 Tree cover, flooded, fresh or brakish water
# 170 Tree cover, flooded, saline water
# 180 Shrub or herbaceous cover, flooded, fresh/saline/brakish water
# 190 Urban areas
# 200 Bare areas
# 201 Consolidated bare areas
# 202 Unconsolidated bare areas
# 210 Water bodies
# 220 Permanent snow and ice


export INDIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
export RAM=/dev/shm
# year 1992  to 2018 
export YEAR=$(expr $SLURM_ARRAY_TASK_ID + 1991 ) 

# echo 10 11 12 20 30 40 50 60 61 62 70 71 72 80 90 100 110 120 121 122 130 140 152 153 160 170 180 190 200 201 202 210 220 | xargs -n 1 -P 6 bash -c $'

# CLASS=$1
# pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -min $(echo $1 - 0.5 | bc) -max $(echo $1 + 0.5 | bc) -data 1 -nodata 0 -i $INDIR/input/ESALC_${YEAR}.tif -o $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif
# gdal_edit.py  -tr 0.002777777777777  -0.002777777777777 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif 
# ' _


# # adapt to the new file name file name LC150_Y*.tif  file name LC81_Y*.tif
# # valid for 81 82 and 150 151 
# echo 81 82 150 151 |  xargs -n 2 -P 2 bash -c $'
# pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -min $(echo $1 - 0.5 | bc) -max $(echo $2 + 0.5 | bc) -data 1 -nodata 0 -i $INDIR/input/ESALC_${YEAR}.tif -o $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif
# gdal_edit.py  -tr 0.002777777777777  -0.002777777777777 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif
# ' _ 


echo 10 11 12 20 30 40 50 60 61 62 70 71 72 80 81 90 100 110 120 121 122 130 140 150 152 153 160 170 180 190 200 201 202 210 220 | xargs -n 1 -P 6 bash -c $'
GDAL_CACHEMAX=4000
echo   CUT $1
export CLASS=$1
gdal_translate -of VRT -projwin  -180 75 -169 60 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif $RAM/LC${CLASS}_Y${YEAR}_cropwest.vrt 
echo   MASK
pksetmask -of GTiff -co COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 0 -nodata 0 -i $RAM/LC${CLASS}_Y${YEAR}_cropwest.vrt  -o  $RAM/LC${CLASS}_Y${YEAR}_transpose2east.tif 

echo   TRANSPOSE
gdal_edit.py  -a_ullr 180 75 191 60 $RAM/LC${CLASS}_Y${YEAR}_transpose2east.tif 

echo  BUILDVRT 
gdal_translate -of VRT -projwin  -180 85  -169  60 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif $RAM/LC${CLASS}_Y${YEAR}_ta.vrt   # upper left
gdal_translate -of VRT -projwin  -169 85   180  60 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif $RAM/LC${CLASS}_Y${YEAR}_tb.vrt   # upper center right 
gdal_translate -of VRT -projwin  -180 60   180 -60 $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif $RAM/LC${CLASS}_Y${YEAR}_tc.vrt   # lower left   center right 

echo MASK 

pksetmask -of GTiff COMPRESS=DEFLATE -co ZLEVEL=9 -m /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/displacement/camp.tif -msknodata 1 -nodata 0 -i $RAM/LC${CLASS}_Y${YEAR}_ta.vrt -o $RAM/LC${CLASS}_Y${YEAR}_ta_msk.tif

gdalbuildvrt -srcnodata 0 -vrtnodata 0 -te -180 -60 191 85 $RAM/LC${CLASS}_Y${YEAR}.vrt $RAM/LC${CLASS}_Y${YEAR}_ta_msk.tif $RAM/LC${CLASS}_Y${YEAR}_t{b,c}.vrt $RAM/LC${CLASS}_Y${YEAR}_transpose2east.tif

echo FINAL TIF
gdal_translate -a_nodata 255 -co COMPRESS=DEFLATE -co ZLEVEL=9 $RAM/LC${CLASS}_Y${YEAR}.vrt $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}.tif
gdal_translate -a_nodata 255 -co COMPRESS=DEFLATE -co ZLEVEL=9 -r nearest -tr 0.0083333333333333333333 0.0083333333333333333333 $RAM/LC${CLASS}_Y${YEAR}.vrt $INDIR/LC$CLASS/LC${CLASS}_Y${YEAR}_1km.tif

rm $RAM/LC${CLASS}_Y${YEAR}*.vrt $RAM/LC${CLASS}_Y${YEAR}_transpose2east.tif  $RAM/LC${CLASS}_Y${YEAR}_ta_msk.tif $RAM/LC${CLASS}_Y${YEAR}_cropwest.vrt 
' _ 

rm  $RAM/LC*_Y${YEAR}*.vrt $RAM/LC*_Y${YEAR}_transpose2east.tif  $RAM/LC*_Y${YEAR}_ta_msk.tif $RAM/LC*_Y${YEAR}_cropwest.vrt 
