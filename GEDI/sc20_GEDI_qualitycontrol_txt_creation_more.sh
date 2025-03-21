#!/bin/bash -l
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 2:00:00  
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stderr1/sc20_GEDI_qualitycontrol_txt_creation_more.sh.%J.err
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stdout1/sc20_GEDI_qualitycontrol_txt_creation_more.sh.%J.out
#SBATCH --mem=5G 
#SBATCH --job-name=sc20_GEDI_qualitycontrol_txt_creation_more.sh

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc20_GEDI_qualitycontrol_txt_creation_more.sh

# created: Oct 7, 2020 10:43 PM
# author: Zhipeng Tang

# This script contains three steps

#--- folder where the datasets are located
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI
export QC_txt=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/QC_MORE

####################################### Step 2 #################################################
# create a global txt file 
################################################################################################


## select only tree height higher than 0 and lower than 100 meters in the colunm 3    #########   x_y_filter.txt   line 646 926 953
#### s prevent to print blank lines                                   ###   cut the elevation to 2 deciaml

rm -f $QC_MORE/*.txt 

cd $OUP_H5



ls -d 20{19,20}.??.??_h5_list  | xargs -n 1 -P 12  bash -c $' 
dir=$1 
dirname=$(basename $dir _h5_list ) 
month=${dirname:5:2}                 ## the month of the data
## echo txt in  $dir 
############## Quality control ##########################

## $1:		y
## $2:  	x
## $3-$8: 	rh_95 for six algorithms
## $9: 		max_rh_95 < 100
## $10:		min_rh_95 > 0
## $11: 	1-4 coverage beam = lower power (worst) ; 5-8 power beam = higher power (better)  
## $12:		digital_elevation_model
## $13:		elev_lowestmode
## $14-$19:	quality_flag for six algorithms quality_flag = 1 (better)
## $20-$25:	sensitivity for six algorithms sensitivity < 0.95 (worse)  ;  sensitivity > 0.95  (beter ) 
## $26: 	degrade_flag = 1  (worse)  ; degrade_flag = 0  (beter)
## $27: 	solar_ele < 0
## month        month 01 02 ... 12  

awk  -v month=$month \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95 && $26==0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400,$11,$26,$27 , month } } \'   $OUP_H5/$dir/GEDI02_A*land_tree.txt  > $QC_txt/x_y_more_$dirname.txt  

' _ 

# sbatch --export=string=x_y_more  /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc21_GEDI_point2grid_more.sh 


exit 

