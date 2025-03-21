#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc42_RF.R.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc42_RF.R.sh.%J.err
#SBATCH --job-name=sc42_RF.R.sh
#SBATCH --mem=10G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc42_RF.R.sh

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/europe/txt/

module load R/3.5.3-foss-2018a-X11-20180131

R  --vanilla --no-readline   -q  <<'EOF'
library(randomForest)
table = read.table("eu_x_y_hight_predictors4R.txt", header = TRUE, sep = " ")
table$geom = as.factor(table$geom)
mod.rf <- randomForest(h ~ ., table , importance=TRUE)

imp=importance(mod.rf)
write.table(imp, "importance_allVar3.txt" )
saveRDS(mod.rf , "model_allrf3.RDS")

EOF


EOF

