#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /project/fas/sbsc/hydro/stdout/sc09_for_run_singleVariable_nofollowing.sh.%J.out
#SBATCH -e /project/fas/sbsc/hydro/stderr/sc09_for_run_singleVariable_nofollowing.sh.%J.err
#SBATCH --mem=200M
#SBATCH --job-name=sc09_for_run_singleVariable_nofollowing.sh
ulimit -c 0

### cd /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc
### for file in    */checking_ls.txt ; do  dir=$( basename $(dirname $file )  )  ;     awk -v dir=$dir '{ if (NR<10) { print "soil" , dir , "0"NR   , $1 } else { print "soil" , dir ,  NR , $1 }  }' $file  ; done  | awk '{ if ($4!=115) print $1 , $2 , $3   }' > no_following.txt


cat /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/soil_acc/no_following.txt  | xargs -n 3 -P 1 bash -c $'  
dir=$1
year=$2
MM=$3 

rm -f /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}_acc/$year/${dir}_${year}_${MM}.vrt 

for tif in /gpfs/gibbs/pi/hydro/hydro/dataproces/TERRA/${dir}/${dir}_${year}_${MM}.tif ; do 
for ID  in $(awk \'{ print $1  }\' /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt  )  ; do 
MEM=$(grep ^"$ID " /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/tiles_comp/tileComp_size_memory.txt | awk  \'{ print int ($4)}\' ) ;  
sbatch  --export=tif=$tif,ID=$ID --mem=${MEM}M --job-name=sc10_var_acc_intb1_TERRA_forloop_$(basename $tif .tif).sh  /gpfs/gibbs/pi/hydro/hydro/scripts/TERRA/sc10_variable_accumulation_intb1_TERRA_forloop_nofollowing.sh 
done 
sleep 1200  # 20 min
done 

' _ 


