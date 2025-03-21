#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00     
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc14_tile_control_TERRA_rerunTile.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc14_tile_control_TERRA_rerunTile.sh.%J.err
#SBATCH --mem=400M
#SBATCH --job-name=sc14_tile_control_TERRA_rerunTile.sh
ulimit -c 0

### sbatch  --export=dir=swe    /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc14_tile_control_TERRA_rerunTile.sh

export dir=$dir
export DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc

awk '{print $1}' /gpfs/gibbs/pi/hydro/hydro/dataproces/GEO_AREA/tile_files/tile_lat_long_20d_MERIT_HYDRO_noheader.txt | grep -v h16v10 | xargs -n 1 -P 4 bash -c $'
line=$1 
cat  $DIR/*/tiles20d/${dir}_????_??_${line}_acc.nd |  grep $line | awk -v line=$line \'{ print line ,  $2 }\' | sort | uniq -c   
' _   > $DIR/tile_nodata.txt
 
####  expr 62 \* 12  = 744 , so all should have the same nodata pixel number. 
    
sort -g -k  1,1 $DIR/tile_nodata.txt | awk '{ if ($1 < 180 ) print $2, $3  }' >  $DIR/tile_nodata_toReRun.txt 

# list  year and months with different no data values 

cat $DIR/tile_nodata_toReRun.txt | xargs -n 2 -P 1 bash -c $' 

grep $1 $DIR/*/tiles20d/${dir}_????_??_${1}_acc.nd  | awk  -v n=$2  \'{ if ($2==n) print $1 }\'  | awk \'{ gsub(":"," ") ; gsub("_"," ") ; print $7 ,  $8 , $9 }\'

' _  | sort   | uniq  > $DIR/year_month_nodata_toReRun1.txt 

## anomalis tiles 
grep 32767.000  $DIR/*/tiles20d/${dir}_*_*_*_acc.mm  | awk -v dir=$dir  '{ gsub("_"," " ) ;  print dir , $2 , $3  }'  | sort | uniq  > $DIR/year_month_nodata_toReRun2.txt 

cd $DIR
for YYYY in $(seq 1958 2019) ; do 
for MM in  01 02 03 04 05 06 07 08 09 10 11 12 ; do 
echo $YYYY/${dir}_${YYYY}_${MM}_acc.ls $(cat  $YYYY/${dir}_${YYYY}_${MM}_acc.ls )  
done 
done 2>  /dev/null | awk -v dir=$dir '{ if (NF==1 ) { gsub ("_"," ") ; print dir ,  $2, $3  } }' > $DIR/year_month_nodata_toReRun3.txt 

for YYYY in $(seq 1958 2019) ; do 
for MM in  01 02 03 04 05 06 07 08 09 10 11 12 ; do 
echo $YYYY/${dir}_${YYYY}_${MM}_acc.ls $(cat  $YYYY/${dir}_${YYYY}_${MM}_acc.ls )  
done ; done 2>  /dev/null | awk -v dir=$dir '{ if ($2!=115 ) {gsub ("_"," "); print dir,$2,$3}}' > $DIR/year_month_nodata_toReRun4.txt 

### count tile is scratch 
wc -l /gpfs/loomis/scratch60/sbsc/ga254/dataproces/TERRA/${dir}_acc/????/${dir}_????_??_acc.ls | grep -v "59 " | awk '{  gsub("[_/]", " " ) ; print  }'  | awk '{ if(NF>4)  print $9 , $11 , $14   }' >   $DIR/year_month_nodata_toReRun5.txt 

cat $DIR/year_month_nodata_toReRun{1,2,3,4,5}.txt | sort -g | uniq > $DIR/year_month_nodata_toReRun6.txt 

###### use exit for re-cheking befor to run 
#### lunch the jobs for the year and months with different no data values 

exit

cat   $DIR/year_month_nodata_toReRun6.txt  | xargs -n 3 -P 1 bash -c $'  
dir=$1
year=$2
MM=$3 

rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc/$year/${dir}_${year}_${MM}.vrt 


for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}/${dir}_${year}_${MM}.tif ; do 
    focase 
for ID  in $(awk \'{ print $1  }\' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt  )  ; do 
MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  \'{ print int($4)  }\' ) ;  
sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_TERRA_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_forloop_nofollowing.sh 
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

sbatch --export=dir=$dir},year=${year},tifname=${dir}_${year}_${MM} --job-name=sc11_tiling20d_TERRA_${dir}_${year}_${MM}.sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc11_tiling20d_TERRA.sh

' _ 
