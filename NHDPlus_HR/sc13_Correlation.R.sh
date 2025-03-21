#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00      
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc13_Correlation.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc13_Correlation.R.sh.%J.err
#SBATCH --job-name=sc13_Correlation.R.sh
#SBATCH --mem=100G

### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/NHDPlus_HR/sc13_Correlation.R.sh

module load R/3.5.3-foss-2018a-X11-20180131

R  --vanilla --no-readline   -q  <<'EOF'
library(data.table)
table <- data.table::fread("/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0.txt", header=FALSE , sep=" ")
colnames(table)[1] = "HYDRO"
colnames(table)[2] = "NHDP"

table$ABS = abs ( table$HYDRO - table$NHDP )

cor_s = cor(table$HYDRO , table$NHDP , method = "spearman")
write.table(cor_s,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_spearman_all.txt"  , row.names = F , col.names = F)

abs_median=median(table$ABS)
write.table(abs_median,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_abs_median_all.txt"  , row.names = F , col.names = F)

table_m=as.matrix(table)
wt = wilcox.test(table_m[,1] , table_m[,2] ,  alternative = "two.sided")
write.table(wt,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_wt_all.txt" )

q=quantile(table$HYDRO, probs = seq(0.1,1,.1))
write.table(q,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_abs_percentile.txt"  , row.names = F , col.names = F)

table$MEAN = ( (table$HYDRO +  table$NHDP)/2 )
q=quantile(table$MEAN, probs = seq(0.1,1,.1))
write.table(q,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_percentile.txt"  , row.names = F , col.names = F)

cor_pall=c()  ; cor_sall=c()
for (n in  c(1,2,3,4,5,6,7,8,9,10))  {
table_cor = table[table$HYDRO  > q[n]]
cor_s = cor(table_cor$HYDRO , table_cor$NHDP , method = "spearman")
cor_p = cor(table_cor$HYDRO , table_cor$NHDP , method = "pearson")
cor_sall  = rbind (cor_sall , cor_s) 
cor_pall  = rbind (cor_pall , cor_p) 
}

write.table(cor_sall,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_spearman.txt"  , row.names = F , col.names = F)
write.table(cor_pall,"/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val/flow_HYDRO_NHDP_gt0_pearson.txt"   , row.names = F , col.names = F)

EOF

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/NHDPlus_HR/raster_flow_val

echo "perc meanp absp spear pears" > $DIR/flow_HYDRO_NHDP_gt0_perc_meanp_absp_spear_pears.txt 
paste -d " " <(seq 10 10 100 ) $DIR/flow_HYDRO_NHDP_gt0_percentile.txt  $DIR/flow_HYDRO_NHDP_gt0_abs_percentile.txt $DIR/flow_HYDRO_NHDP_gt0_spearman.txt $DIR/flow_HYDRO_NHDP_gt0_pearson.txt >> $DIR/flow_HYDRO_NHDP_gt0_perc_meanp_absp_spear_pears.txt 



