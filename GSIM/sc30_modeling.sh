#!/bin/bash
#SBATCH -p bigmem
#SBATCH -n 1 -c 40 -N 1
#SBATCH -t 24:00:00       # 1 hours 
#SBATCH -o /vast/palmer/scratch/sbsc/ga254/stdout/sc30_modeling.sh.%J.out
#SBATCH -e /vast/palmer/scratch/sbsc/ga254/stderr/sc30_modeling.sh.%J.err
#SBATCH --job-name=sc30_modeling.sh
#SBATCH --mem=500G


#### sbatch   /gpfs/gibbs/pi/hydro/hydro/scripts/GSIM/sc30_modeling.sh

EXTRACT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract 
cd $EXTRACT

module load StdEnv
module load R/4.1.0-foss-2020b

head -1 stationID_x_y_value_predictors.txt | sed  's/-/_/g'   > stationID_x_y_value_predictors_header.txt
shuf -n 30000  <( awk '{ if (NR> 1 && $5>=0) print  $0} '  stationID_x_y_value_predictors.txt ) | awk -F ":" '{ print $1="" , $0  }'  | sed 's/^ *//g'  > stationID_x_y_value_predictors_rand.txt

awk '{print $5 } ' stationID_x_y_value_predictors_rand.txt   > stationID_x_y_value_predictors_randy.txt
awk '{print $1="", $2="", $3="", $4="", $5="", $0}' stationID_x_y_value_predictors_rand.txt | sed 's/^ *//g' > stationID_x_y_value_predictors_randx.txt

awk '{ print $1="", $2="", $3="", $4="",$0}' stationID_x_y_value_predictors_header.txt |  sed 's/^ *//g' > stationID_x_y_value_predictors_randyx.txt
### awk '{  if($5==0) {MEAN=log(0.000001)} else {MEAN=log($5)}  print $1="", $2="", $3="", $4="",$5="", MEAN, $0}' stationID_x_y_value_predictors_rand.txt |   sed -e's/  */ /g' |  sed 's/^ *//g'  >> stationID_x_y_value_predictors_randyx.txt

awk '{ if($5>=0) { print $1="", $2="", $3="", $4="", $0 }}' stationID_x_y_value_predictors_rand.txt |   sed -e's/  */ /g' |  sed 's/^ *//g'  >> stationID_x_y_value_predictors_randyx.txt

Rscript --vanilla  -e '
library("data.table")
library("ranger")
library("VSURF")

tableyx = fread("stationID_x_y_value_predictors_randyx.txt", header = TRUE, sep = " ")

tableyx$geom           =   as.factor(tableyx$geom)
tableyx$order_hack     =   as.factor(tableyx$order_hack)
tableyx$order_horton   =   as.factor(tableyx$order_horton)
tableyx$order_shreve   =   as.factor(tableyx$order_shreve)
tableyx$order_strahler =   as.factor(tableyx$order_strahler)
tableyx$order_topo     =   as.factor(tableyx$order_topo)

# des.table = summary(table)
# write.table(des.table, "stat_allVar.txt", quote = FALSE  )

# t <- tuneRF(table[,-1], table[,1],  stepFactor = 1,  plot = TRUE, ntreeTry = 500, trace = TRUE,  improve = 0.01)  

# "thresholding step" =  First step is dedicated to eliminate irrelevant variables from the dataset. 
# "interpretation step" = Second step aims to select all variables related to the response for interpretation purpose. 
# "prediction step" = Third step refines the selection by eliminating redundancy in the set of variables selected by the second step, for prediction purpose

#### variable selection base on VSURF 

rf.vs = VSURF( MEAN~. , data=tableyx , parallel = TRUE, ncores = 40 , clusterType=c("FORK","FORK") , RFimplem = "ranger" )

### rf.vs1 = VSURF( x =  tableyx[,2:102]  , y = tableyx[,1] , parallel = TRUE, ncores = 12 , clusterType="ranger" , RFimplem = "ranger" )

write.table(names(tableyx)[rf.vs$varselect.thres  + 1] , "varselect_thres1.txt"  , quote = F , col.names = F)
write.table(names(tableyx)[rf.vs$varselect.interp + 1] , "varselect_interp1.txt" , quote = F , col.names = F)
write.table(names(tableyx)[rf.vs$varselect.pred   + 1] , "varselect_pred1.txt"   , quote = F , col.names = F)

save.image("data0.RData")
'

exit 

# library(tuneRanger) ## for now not implemented

# fit a model with variable selection 
mod.rfR.vs = ranger( pa ~ . , table.rf.vs  ,   importance="permutation")

impR.vs=as.data.frame(importance(mod.rfR.vs))
impR.vs.s = impR.vs[order(impR.vs$"importance(mod.rfR.vs)",decreasing=TRUE), , drop = FALSE]

write.table(impR.vs.s, paste0("../vector_seed",seed,"/importanceR_selvsVar.txt"), quote = FALSE  )
s.mod.rfR = capture.output(mod.rfR.vs)
write.table(s.mod.rfR, paste0("../vector_seed",seed,"/selvsVarR.mod.rf.txt"), quote = FALSE , row.names = FALSE )

save.image("data1.RData")

'







