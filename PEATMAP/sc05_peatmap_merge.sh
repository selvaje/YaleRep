#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1
#SBATCH -t 03:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc05_peatmap_merge.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc05_peatmap_merge.sh.%J.err
#SBATCH --job-name=sc05_peatmap_merge.sh
#SBATCH --mem-per-cpu=40000M

# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Code/global-environmental-variables/PEATMAP/sc05_peatmap_merge.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/PEATMAP/sc05_peatmap_merge.sh

module purge
source ~/bin/gdal
source ~/bin/pktools

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP

MASKly=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/elv/all_tif.vrt

#for FILE in $( ls $DIR/out ); do gdal_edit.py -a_nodata 0 $DIR/out/$FILE; done

#gdalbuildvrt  -overwrite -srcnodata 0 $DIR/out/all_peatmap.vrt  $DIR/out/*.tif

echo -------------
echo MASKING
echo -------------
pksetmask -i $DIR/out/all_peatmap.vrt -m $MASKly -msknodata=-9999 -nodata=-9999 -o $DIR/PEATMAP2.tif -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Int16

exit

scp -i ~/.ssh/JG_PrivateKeyOPENSSH jg2657@grace.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/PEATMAP/PEATMAP.tif /home/jaime/Data/PEATMAP



## small subset to verify
gdal_translate -projwin -5 54 -2 50  -co COMPRESS=DEFLATE -co ZLEVEL=9 tif/GRanD_1958.vrt out/subsetVRT1958.tif

#####################################################


for i in $( echo SA_Peatland_01_RP.tif SA_Peatland_02_RP.tif SA_Peatland_03_RP.tif SA_Peatland_04_RP.tif); do gdal_edit.py -a_nodata 0 $i; done

gdalbuildvrt allSA.vrt ./SA_Peatland_0*.tif -srcnodata 0 -overwrite
