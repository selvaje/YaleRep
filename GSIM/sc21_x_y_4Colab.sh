#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 1 hours 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_x_y_4Colab.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_x_y_4Colab.sh.%A_%a.err
#SBATCH --job-name=sc21_x_y_4Colab.sh
#SBATCH --mem=1G
#SBATCH --array=6-708

#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc21_x_y_4Colab.sh
#### --array=6-708
#### 1825:1958-01-31    
#### 2532:2016-12-31

ulimit -c 0
source ~/bin/gdal3

module load Rclone/1.53.0

find  /tmp/       -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER -atime +2 -ctime +2  -mtime +2  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

### create data.txt only once 
### grep "^[0-9][0-9][0-9][0-9]"-  /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly/* | awk  '{gsub("," , " " ) ;  gsub(":" , " " ) ;   { print $2 }  }' | sort | uniq -c  > /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/metadata/date.txt

### awk '{  if ($4!=2) print $3 , $1 , $2 }' /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/snapFlow/x_y_snapFlowFinal_*.txt | sort -k 1,1 >   /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/snapFlow/ID_x_y_snapFlowFinal.txt

#  SLURM_ARRAY_TASK_ID=706
SNAP=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping
EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
RAM=/dev/shm
TERRA=/gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA
SOILGRIDS=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS
ESALC=/gpfs/gibbs/pi/hydro/hydro/dataproces/ESALC

DATE=$(awk -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824) print $2 }' $SNAP/metadata/date.txt)
DA_TE=$(echo $DATE | awk -F - '{ print $1"_"$2 }')
YYYY=$(echo $DATE | awk -F - '{ print $1 }')
MM=$(echo $DATE | awk -F - '{ print $2 }')

echo $DATE 

DATE1=$(awk -v n=1  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE1=$(echo $DATE1 | awk -F - '{ print $1"_"$2 }')
YYYY1=$(echo $DATE1  | awk -F - '{ print $1 }')
MM1=$(echo $DATE1    | awk -F - '{ print $2 }')

DATE2=$(awk -v n=2  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE2=$(echo $DATE2 | awk -F - '{ print $1"_"$2 }')
YYYY2=$(echo $DATE2  | awk -F - '{ print $1 }')
MM2=$(echo $DATE2    | awk -F - '{ print $2 }')

DATE3=$(awk -v n=3  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE3=$(echo $DATE3 | awk -F - '{ print $1"_"$2 }')
YYYY3=$(echo $DATE3  | awk -F - '{ print $1 }')
MM3=$(echo $DATE3    | awk -F - '{ print $2 }')

DATE4=$(awk -v n=4  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE4=$(echo $DATE4 | awk -F - '{ print $1"_"$2 }')
YYYY4=$(echo $DATE4  | awk -F - '{ print $1 }')
MM4=$(echo $DATE4    | awk -F - '{ print $2 }')

DATE5=$(awk -v n=5  -v ID=$SLURM_ARRAY_TASK_ID '{ if(NR==ID+1824-n) print $2 }' $SNAP/metadata/date.txt)
DA_TE5=$(echo $DATE5 | awk -F - '{ print $1"_"$2 }')
YYYY5=$(echo $DATE5  | awk -F - '{ print $1 }')
MM5=$(echo $DATE5    | awk -F - '{ print $2 }')

grep ^${YYYY}-${MM} /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly/*.mon | awk '{gsub("/"," "); gsub(":"," "); gsub(","," "); gsub(".mon"," ");if($12!="NA") {print $10, $12}}' | sort -k 1,1  > $RAM/stationID_value_${DA_TE}.txt

join -1 1 -2 1 $SNAP/snapFlow/ID_x_y_snapFlowFinal.txt $RAM/stationID_value_${DA_TE}.txt | awk -v DATE=$DATE '{ print $1, DATE , $2 , $3 , $4 }'  > $SNAP/x_y_mean/stationID_x_y_value_${DA_TE}.txt
awk '{ print $3, $4   }'  $SNAP/x_y_mean/stationID_x_y_value_${DA_TE}.txt   >   $SNAP/x_y_date/x_y_${DA_TE}.txt

rm $RAM/stationID_value_${DA_TE}.txt
