#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_classsplit_displacement.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_classsplit_displacement.sh.%J.err
#SBATCH --job-name=sc03_classsplit_displacement.sh
#SBATCH --mem=10G

source ~/bin/gdal3
source ~/bin/pktools

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ESALC_GFC/sc03_classsplit.sh

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

export GFC=/gpfs/loomis//gpfs/gibbs/pi/hydro/hydro/dataproces/GFC
export ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC
export ESALC_GFC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC_GFC
export RAM=/dev/shm

echo 0  0    > $RAM/ESALC_2018_rec.txt
echo 10 10  >> $RAM/ESALC_2018_rec.txt
echo 11 11  >> $RAM/ESALC_2018_rec.txt
echo 12 12  >> $RAM/ESALC_2018_rec.txt 
echo 20 20  >> $RAM/ESALC_2018_rec.txt
echo 30 30  >> $RAM/ESALC_2018_rec.txt
echo 40 40  >> $RAM/ESALC_2018_rec.txt
echo 50 50  >> $RAM/ESALC_2018_rec.txt
echo 60 60  >> $RAM/ESALC_2018_rec.txt
echo 61 21  >> $RAM/ESALC_2018_rec.txt
echo 62 62  >> $RAM/ESALC_2018_rec.txt
echo 70 70  >> $RAM/ESALC_2018_rec.txt
echo 71 71  >> $RAM/ESALC_2018_rec.txt
echo 72 72  >> $RAM/ESALC_2018_rec.txt
echo 80 80  >> $RAM/ESALC_2018_rec.txt
echo 81 81  >> $RAM/ESALC_2018_rec.txt
echo 82 81  >> $RAM/ESALC_2018_rec.txt
echo 90 90  >> $RAM/ESALC_2018_rec.txt
echo 100 100  >> $RAM/ESALC_2018_rec.txt
echo 110 110  >> $RAM/ESALC_2018_rec.txt
echo 120 120  >> $RAM/ESALC_2018_rec.txt
echo 121 121  >> $RAM/ESALC_2018_rec.txt
echo 122 122  >> $RAM/ESALC_2018_rec.txt
echo 130 130  >> $RAM/ESALC_2018_rec.txt
echo 140 140  >> $RAM/ESALC_2018_rec.txt
echo 150 150  >> $RAM/ESALC_2018_rec.txt
echo 151 150  >> $RAM/ESALC_2018_rec.txt
echo 152 152  >> $RAM/ESALC_2018_rec.txt
echo 153 153  >> $RAM/ESALC_2018_rec.txt
echo 160 160  >> $RAM/ESALC_2018_rec.txt
echo 170 170  >> $RAM/ESALC_2018_rec.txt
echo 180 180  >> $RAM/ESALC_2018_rec.txt
echo 190 0  >> $RAM/ESALC_2018_rec.txt
echo 200 0  >> $RAM/ESALC_2018_rec.txt
echo 201 0  >> $RAM/ESALC_2018_rec.txt
echo 202 0  >> $RAM/ESALC_2018_rec.txt
echo 210 0  >> $RAM/ESALC_2018_rec.txt
echo 220 0  >> $RAM/ESALC_2018_rec.txt

pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -nodata 0 -code $RAM/ESALC_2018_rec.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 \
-i $ESALC/input/ESALC_2018.tif  -o $ESALC_GFC/ESALC_2018_rec.tif

rm $RAM/ESALC_2018_rec.txt



