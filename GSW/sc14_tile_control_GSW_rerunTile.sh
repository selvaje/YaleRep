#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00     
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc14_tile_control_GSW_rerunTile.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc14_tile_control_GSW_rerunTile.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc14_tile_control_GSW_rerunTile.sh
ulimit -c 0

### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc14_tile_control_GSW_rerunTile.sh

export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSW

awk '{print $1}' /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt | grep -v h16v10 | xargs -n 1 -P 4 bash -c $'
line=$1 
cat  $DIR/*_acc/tiles20d/*_${line}_acc.nd |  grep $line | awk -v line=$line \'{ print line ,  $2 }\' | sort | uniq -c   
' _   > $DIR/tile_nodata.txt
 
####  expr 62 \* 12  = 744 , so all should have the same nodata pixel number. 

##### addjust ($1< number_of variables)    
sort -g -k  1,1 $DIR/tile_nodata.txt | awk '{ if ($1<5 ) print $2, $3  }' >  $DIR/tile_nodata_toReRun.txt # empity if all have been run correctly. 

# list  year and months with different no data values 

cat $DIR/tile_nodata_toReRun.txt | xargs -n 2 -P 1 bash -c $' 

grep $1  $DIR/*_acc/tiles20d/*_${1}_acc.nd  | grep $2   | awk \'{ gsub(":"," ") ; gsub("_"," ") ; print $7 ,  $8 , $9 }\'

' _  | sort   | uniq  > $DIR/year_month_nodata_toReRun.txt 


exit 

###### use exit for re-cheking befor to run 
#### lunch the jobs for the year and months with different no data values 


cat $DIR/year_month_nodata_toReRun.txt  | xargs -n 3 -P 1 bash -c $'  
dir=$1
year=$2
MM=$3 

rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/${dir}_acc/$year/${dir}_${year}_${MM}.vrt 


for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/GSW/${dir}/${dir}_${year}_${MM}.tif ; do 
for ID  in $(awk \'{ print $1  }\' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt  )  ; do 
MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  \'{ print $4}\' ) ;  
sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_GSW_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc10_variable_accumulation_intb1_GSW_forloop_nofollowing.sh 
done 
sleep 1200  # 20 min
done 

' _ 


exit 
exit 

#### in case you need run the sc11 
                                                                                                                                      
cat $DIR/year_month_nodata_toReRun.txt  | xargs -n 3 -P 1 bash -c $'
dir=$1
year=$2
MM=$3

sbatch --export=dir=$dir},year=${year},tifname=${dir}_${year}_${MM} --job-name=sc11_tiling20d_GSW_${dir}_${year}_${MM}.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/GSW/sc11_tiling20d_GSW.sh

' _ 
