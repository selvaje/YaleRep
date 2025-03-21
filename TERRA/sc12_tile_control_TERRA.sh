#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 3:00:00       # 6 hours 
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc12_tile_control_TERRA.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc12_tile_control_TERRA.sh.%J.err
#SBATCH --mem=400M
#SBATCH --job-name=sc12_tile_control_TERRA.sh 
ulimit -c 0


#### for year in $(seq 1958 2019) ;  do  sbatch --export=dir=swe,year=$year  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc12_tile_control_TERRA.sh ; done 

source ~/bin/gdal3

### dir=ppt
### year=1964

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc

echo ls 
for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do 
ls $DIR/$year/tiles20d/${dir}_${year}_${MM}_*_acc.tif | wc -l ; 
done > $DIR/$year/checking_ls.txt  

# echo min max $year $dir 
# for file in  $DIR/$year/tiles20d/${dir}_${year}_*.tif  ; do 
# echo $file $( gdalinfo $file -mm | grep Comp )  
# done  > $DIR/$year/checking_min_max.txt  

# for MM in 01 02 03 04 05 06 07 08 09 10 11 12 ; do 
# echo $MM $(ls /gpfs/scratch60/fas/sbsc/$USER/dataproces/TERRA/${dir}_acc/${year}/intb/${dir}_${year}_${MM}_*_acc.tif | wc -l )
# done  >    $DIR/$year/checking_ls_intb.txt  


exit 


# for file in ppt_1959_??.tif  ; do gdallocationinfo -geoloc  -valonly  $file   -24.346 14.937 ; done

/gpfs/scratch60/fas/sbsc/ga254/dataproces/TERRA/ppt_acc/1959
for file in *.vrt ; do gdallocationinfo -geoloc  -valonly  $file   -24.346 14.937 ; done

for file in intb/*44*.tif  ; do gdallocationinfo -geoloc  -valonly  $file   -24.346 14.937 ; done 
