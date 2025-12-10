#!/bin/bash
#SBATCH -p day 
#SBATCH -n 1 -c 11  -N 1
#SBATCH -t 24:00:00 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc99_rho.sh.%A_%a.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc99_rho.sh.%A_%a.err
#SBATCH --job-name=sc99_rho.sh
#SBATCH --mem=50G
#SBATCH --array=20-39

####  sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSI_TS/sc99_rho.sh 

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSI_TS/extract_red
cd $EXTRACT
module load StdEnv
# seq 40 105 | xargs -n 1 -P 20 bash -c $' 
# echo $( cut -d " " -f $1 stationID_x_y_valueALL_predictors.txt | head -1) $( ~/scripts/general/spearman_awk.sh stationID_x_y_valueALL_predictors.txt 14 $1)# ' _

export col=$SLURM_ARRAY_TASK_ID

var=$(cut -d " " -f $col  stationID_x_y_valueALL_predictors.txt | head -1)
seq 9 19  | xargs -n 1 -P 11 bash -c $'
echo $(cut -d " " -f $1 stationID_x_y_valueALL_predictors.txt | head -1) $(~/scripts/general/spearman_awk_improved.sh stationID_x_y_valueALL_predictors.txt $1 $col)
' _ > /tmp/rho_$var.txt

paste -d " " <(grep QMIN | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
             <(grep Q10  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
             <(grep Q20  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
             <(grep Q30  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q40  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q50  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q60  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q70  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q80  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep Q90  | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt )\
	     <(grep QMAX | awk '{if (NR==2) printf "%.6f", $2 }' /tmp/rho_$var.txt ) > rho_$var.txt

rm /tmp/rho_$var.txt

