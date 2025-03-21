#!/bin/bash -l
#SBATCH -p day
#SBATCH -n 1 -c 12  -N 1
#SBATCH -t 2:00:00  
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stderr1/sc10_GEDI_qualitycontrol_txt_creation.sh.%J.err
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stdout1/sc10_GEDI_qualitycontrol_txt_creation.sh.%J.out
#SBATCH --mem=5G 
#SBATCH --job-name=sc10_GEDI_qualitycontrol_txt_creation.sh

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI/sc10_GEDI_qualitycontrol_txt_creation.sh

# created: Oct 7, 2020 10:43 PM
# author: Zhipeng Tang

# This script contains three steps

#--- folder where the datasets are located
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/GEDI
export INP_DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI
export OUP_H5=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/GEDI
export QC_txt=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI/QC_TXT
# open the main folder
# cd $INP_DIR

####################################### Step 2 #################################################
# create a global txt file 
################################################################################################


## select only tree height higher than 0 and lower than 100 meters in the colunm 3    #########   x_y_filter.txt   line 646 926 953
#### s prevent to print blank lines                                   ###   cut the elevation to 2 deciaml

rm -f $QC_txt/*.txt 
 
cd $OUP_H5



ls -d 20{19,20}.??.??_h5_list  | xargs -n 1 -P 12  bash -c $' 

dir=$1 
dirname=$(basename $dir _h5_list ) 
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

awk \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $11>=5 && $11<=8 && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95 && $26==0 && $27 < 0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400 }    }\'   $OUP_H5/$dir/GEDI02_A*land_tree.txt > $QC_txt/x_y_allfilter_$dirname.txt  

### Compare 1: solar_ele < 0    vs. solar_ele >= 0 
awk \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $11>=5 && $11<=8 && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95 && $26==0 && $27 >= 0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400 }    }\'   $OUP_H5/$dir/GEDI02_A*land_tree.txt > $QC_txt/x_y_day_$dirname.txt

### Compare 2: Beam 1-4         vs. 5-8  
awk \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $11>=1 && $11<=4 && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95 && $26==0 && $27 < 0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400 }    }\'   $OUP_H5/$dir/GEDI02_A*land_tree.txt > $QC_txt/x_y_coveragebeam_$dirname.txt 

### Compare 3 $8 : sensitivity > 0.95       vs. 0.9 < sensitivity <= 0.95
awk \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $11>=5 && $11<=8 && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.80 && $21>0.80 && $22>0.80 && $23>0.80 && $24>0.80 && $25>0.80 && !($20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95) $26==0 && $27 < 0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400 }    }\'   $OUP_H5/$dir/GEDI02_A*land_tree.txt > $QC_txt/x_y_sensitivity_$dirname.txt  
 
### Compare 4: degrade_flag = 0   vs.       degrade_flag = 1 
awk \' { if ($9<10000 && $10>0 && ($10-$9 <=200) && $11>=5 && $11<=8 && $14==1 && $15==1 && $16==1 && $17==1 && $18==1 && $19==1 && $20>0.95 && $21>0.95 && $22>0.95 && $23>0.95 && $24>0.95 && $25>0.95 && $26!=0 && $27 < 0 )  { print $2,$1,($3+$4+$5+$6+$7+$8-$9-$10)/400 }    }\'   $OUP_H5/$dir/GEDI02_A*land_tree.txt > $QC_txt/x_y_degrade_$dirname.txt 

' _ 

exit 
