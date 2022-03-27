#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 4 -N 1
#SBATCH -t 8:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_classplit.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_classplit.sh.%A.%a.err
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_classplit.sh
#SBATCH --array=1-24

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/LCESA/sc02_classplit.sh

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
# 82  Tree cover, needleleaved, deciduous, open (15-40%)           # very few pixel aggregate with 81
# 90  Tree cover, mixed leaf type (broadleaved and needleleaved)
# 100 Mosaic tree and shrub (>50%) / herbaceous cover (<50%)
# 110 Mosaic herbaceous cover (>50%) / tree and shrub (<50%)
# 120 Shrubland
# 121 Shrubland evergreen
# 122 Shrubland deciduous
# 130 Grassland
# 140 Lichens and mosses
# 150 Sparse vegetation (tree, shrub, herbaceous cover) (<15%)
# 151 Sparse tree (<15%)                                           # very few pixel aggregate with 150
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


export INDIR=/project/fas/sbsc/ga254/dataproces/LCESA
export RAM=/dev/shm

# year 1992 2015 
export YEAR=$(expr $SLURM_ARRAY_TASK_ID + 1991 ) 

echo 10 11 12 20 30 40 50 60 61 62 70 71 72 80 90 100 110 120 121 122 130 140 152 153 160 170 180 190 200 201 202 210 220 | xargs -n 1 -P 4 bash -c $'
CLASS=$1

pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -min  $( echo $CLASS - 0.5 | bc ) -max $( echo $CLASS + 0.5 | bc ) -data 1 -nodata 0   -i $INDIR/input/ESACCI-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.0.7.tif -o $INDIR/$YEAR/LC${CLASS}_Y${YEAR}.tif 
gdal_edit.py  -a_ullr 0.002777777777777  -0.002777777777777 $INDIR/$YEAR/LC${CLASS}_Y${YEAR}.tif 
 ' _

# valid for 81 82 and 150 151 
echo 81 82 150 151 |  xargs -n 2 -P 2 bash -c $'
pkgetmask -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9 -min $( echo $1 - 0.5 | bc ) -max $(echo $2 + 0.5 | bc ) -data 1 -nodata 0 -i $INDIR/input/ESACCI-LC-L4-LCCS-Map-300m-P1Y-${YEAR}-v2.0.7.tif -o $INDIR/$YEAR/LC${1}_Y${YEAR}.tif
gdal_edit.py  -a_ullr 0.002777777777777  -0.002777777777777 $INDIR/$YEAR/LC${CLASS}_Y${YEAR}.tif 
' _ 

