#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_Brahmaputra_discarge_join_occurence.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_Brahmaputra_discarge_join_occurence.sh.%A_%a.err
#SBATCH --mem-per-cpu=5000

#  sbatch /gpfs/home/fas/sbsc/ga254/scripts/FLO1K/sc11_Brahmaputra_discarge_join_occurence.sh 



export  FLO=/project/fas/sbsc/ga254/dataproces/FLO1K
export  SHP=/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp
export  EXT=/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/extract_flo1k
export  RAM=/dev/shm 


# attach the year to the discarge
for file in $EXT/point*_max.txt ; do 
filename=$(basename $file .txt )
paste -d " " <(seq 1960 2015 )  $file  >  $EXT/${filename}_year.txt 
done 


for point in $(seq 1 10)      ; do
for year  in $(seq 2005 2015) ; do
awk -v year=$year -v point=$point  'BEGIN { printf (year - 1" ") }  { if ($2 == point) printf ("%i " , $3) } END {printf ("\n") } '  brahmaputra${year}_ct.txt  
done  > point${point}_occurance.txt 
done 



for point in $(seq 1 10)      ; do
join -1 1 -2 1  point${point}_max_year.txt   point${point}_occurance.txt > point${point}_year_flo1k_oc0_oc1_oc2_oc3.txt 
done 












