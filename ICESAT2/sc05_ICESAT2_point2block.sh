#!/bin/bash -l
#SBATCH -n 1 -c 12 -N 1
#SBATCH -t 4:00:00  
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc05_ICESAT2_point2block_%J.sh.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc05_ICESAT2_point2block_%J.sh.err
#SBATCH --mem=5G 
#SBATCH --job-name=sc05_ICESAT2_point2block

##   sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2/sc05_ICESAT2_point2block.sh 

# created: Oct 7, 2020 10:43 PM  -p scavenge
# author: Zhipeng Tang

# This script contains three steps

#--- folder where the datasets are located
export DIRAPI=/gpfs/gibbs/pi/hydro/hydro/scripts/ICESAT2
export INP_DIR=/gpfs/loomis/scratch60/sbsc/zt226/dataproces/ICESAT2
export QC_txt=/gpfs/gibbs/pi/hydro/hydro/dataproces/ICESAT2/QC_TXT

mkdir -p $QC_txt
rm -f $QC_txt/*.txt 

# open the main folder
cd $INP_DIR


####################################### Step 2 #################################################
# create a global txt file 
################################################################################################

ls -d 20{19,20}.??.??_h5_list  | xargs -n 1 -P 12  bash -c $' 

dir=$1 
dirname=$(basename $dir _h5_list ) 
## echo txt in  $dir 
############## Quality control ##########################

## $1:		y   latitude, 
## $2:  	x   longitude
## $3:  	rh_98
## $4:  	min_canopy
## $5:   	night is 0 or day is 1 
## $6-$14: 	rh_25, rh_50, rh_60, rh_70, rh_75, rh_80, rh_85, rh_90, rh_95 

awk \' { if ($14<100 && $14>0)  { print $2,$1,$14}   }\'   $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_95_$dirname.txt
awk \' { if ($13<100 && $13>0)  { print $2,$1,$13}   }\'   $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_90_$dirname.txt  
awk \' { if ($12<100 && $12>0)  { print $2,$1,$12}   }\'   $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_85_$dirname.txt
awk \' { if ($11<100 && $11>0)  { print $2,$1,$11}   }\'   $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_80_$dirname.txt  
awk \' { if ($10<100 && $10>0)  { print $2,$1,$10}   }\'   $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_75_$dirname.txt  
awk \' { if ($9<100 && $9>0)    { print $2,$1,$9}   }\'    $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_70_$dirname.txt  

## This contains 6 percentiles of tree height
awk \' { if ($14<100 && $9>0)    { print $2,$1,$9,$10,$11,$12,$13,$14}   }\'    $INP_DIR/$dir/ATL08_*land_tree.txt > $QC_txt/x_y_more_66_$dirname.txt  

' _ 

exit 




## select only tree height higher than 0 and lower than 100 meters in the colunm 3    #########   x_y_filter.txt   line 646 926 953
#### s prevent to print blank lines                                   ###   cut the elevation to 2 deciaml
rm -f $INP_DIR/x_y_filter.txt 
for dir in $(dir  -d *_list ) ; do 
echo $dir 
cat -s $INP_DIR/$dir/ATL08_*detailed.txt |  awk ' $3>0 && $3<100 {   printf("%s %s %2.2f\n", $2 , $1 , $3)  }'  >> $INP_DIR/x_y_filter.txt    
done

cd $INP_DIR/blockfile
awk  'NR%1000000==1{x="blockfile"++i".txt" ; }{print $1 , $2 , $3 > x}' $INP_DIR/x_y_filter.txt


