#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc14_basin_area_comparison.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc14_basin_area_comparison.sh.%A_%a.err
#SBATCH --job-name=sc14_basin_area_comparison.sh
#SBATCH --array=1-82
#SBATCH --mem=20G

# 1-82
# sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/GRDC/sc14_basin_area_comparison.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SC=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO
export PRJ=/gpfs/gibbs/pi/hydro/hydro/dataproces/GRDC/MRB_tif

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export file=$(ls $PRJ/mrb_basins_??????_rec.tif  | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export tile=$(basename $file _rec.tif | sed 's/mrb_basins_//g') 


grass78  -f -text --tmp-location  -c $file  <<'EOF'
r.external   input=$file                                                      output=mrb      --overwrite 
r.external   input=$SC/lbasin_tiles_final20d_1p/lbasin_${tile}_arearec.tif    output=lbasin   --overwrite 
r.mapcalc "index  = ( float(lbasin  - mrb ) / float(lbasin  + mrb) ) * 1000000"  --o
r.out.gdal -f --o -c -m  createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Int32   format=GTiff nodata=-9999999 input=index  output=$PRJ/area_index_$tile.tif 
r.report map=lbasin,mrb  units=me -i -h -n --q -a  > $PRJ/area_report1_$tile.txt 
EOF

grep -v  -e "\-" -e TOTAL  $PRJ/area_report1_$tile.txt   | awk -F "|" '{if (NR>2) {
                          if ($2==int($2)) { col1=int($2)} else { col1="A"} ;
                          if ($3==int($3)) { col2=int($3)} else { col2="B"} ;
                          print col1 , col2 , $5 }}' > $PRJ/area_report2_$tile.txt 

paste  -d " " <(awk '{ print $1  }' $PRJ/area_report2_$tile.txt   )  <(awk '{ if (NR>1 ) print $2  }'  $PRJ/area_report2_$tile.txt   )  <(awk '{ if (NR>1 ) print $3  }'  $PRJ/area_report2_$tile.txt   )   | grep -v "A B" > $PRJ/area_report3_$tile.txt 

# 1 2002978
# A 2013243
# A 2028182
# 2 2067490
# 3 2068974
# 4 2082002
# 5 2119070

awk '{ 
if (NF==3) {
if (NR==1)   { old=$1 } ;
if ($1=="A") { col1=old } else
               { col1=$1 }
               print col1 , $2 , $3 
               old=col1 }
}' $PRJ/area_report3_$tile.txt   > $PRJ/area_report4_$tile.txt  

# pkfilter -nodata -9999999  -co COMPRESS=DEFLATE -co ZLEVEL=9  -dx 10 -dy 10 -d 10 -f mean  -i $PRJ/area_index_$tile.tif   -o $PRJ/area_index_${tile}_10p.tif 

if [ $SLURM_ARRAY_TASK_ID = 82   ] ; then 
sleep 500
gdalbuildvrt  -srcnodata -9999999 -vrtnodata -9999999  -overwrite  $PRJ/all_area_index_10p.vrt    $PRJ/area_index_??????_10p.tif 
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9     $PRJ/all_area_index_10p.vrt    $PRJ/all_area_index_10p.tif 


awk '{ gsub(",","") ;  print $1"a"$2, $3   }' $PRJ/area_report4_??????.txt | sort -k 1,1 -g   >   $PRJ/all_area_report4.txt
~/scripts/general/sum.sh   $PRJ/all_area_report4.txt    $PRJ/all_area_report_sum.txt <<EOF
n
1
0
EOF

awk '{ gsub("a" , " " ) ; print  $0   }'  all_area_report_sum.txt  | awk '{ print  $2   }' | sort | uniq  > $PRJ/all_mrb_uniq.txt

awk '{ gsub("a" , " " ) ; print  $0   }'  all_area_report_sum.txt  > all_area_report_sum_3col.txt



for n in $( cat   $PRJ/all_mrb_uniq.txt ) ; do 
awk -v n=$n '{ if ($2==n)  { print }   }'  all_area_report_sum_3col.txt | sort -gr -k 3,3 | head -1 
done | awk '{ print $1 , $2   }' >   all_maxarea_overlap.txt


fi 
