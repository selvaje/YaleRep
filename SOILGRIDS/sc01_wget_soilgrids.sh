#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/jg2657/stdout/sc01_wget_soilgrids.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/jg2657/stderr/sc01_wget_soilgrids.sh.%J.err
#SBATCH --job-name=sc01_wget_soilgrids.sh
#SBATCH --array=1-82

module purge
source ~/bin/gdal

# sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/SOILGRIDS/sc01_wget_soilgrids.sh



### exploring the data
## extracting names of available files
## curl -s https://files.isric.org/soilgrids/data/recent/ | grep .tif | awk -F[\"] '{print $2}' | sed '/.xml/d'  > ~/Data/SOILGRIDS/soil_layers.txt

##  DEPTHS:
##	sl1 = 0.00 m
##  sl2 = 0.05 m
##  sl3 = 0.15 m
##  sl4 = 0.30 m
##  sl5 = 0.60 m
##  sl6 = 1.00 m
##  sl7 = 2.00 m

####  SLTPPT = Silt content (2-50 micro meter) mass fraction in % at depth <sl1...sl7>
####  CLYPPT = Clay content (0-2  micro meter) mass fraction in % at depth <sl1...sl7>
####  SNDPPT = Sand content (50-2000  micro meter) mass fraction in % at depth <sl1...sl7>

####  AWCh1 = Derived available soil water capacity (volumetric fraction) with FC = pF 2.0 for depth 
####  AWCh2 = Derived available soil water capacity (volumetric fraction) with FC = pF 2.3 for depth 
####  AWCh3 = Derived available soil water capacity (volumetric fraction) with FC = pF 2.5 for depth 
####  AWCtS = Derived saturated water content (volumetric fraction) teta-S
####  WWP : Derived available soil water capacity (volumetric fraction) until wilting point for depth 

##  TEXMHT : Texture class (USDA system) at depth 

##  PHIKCL : Soil pH x 10 in KCl at depth 
##  PHIHOX : Soil pH x 10 in H2O at depth 

####  OCDENS : Soil organic carbon density in kg per cubic-m at depth 
####  OCSTHA : Soil organic carbon stock in tons per ha for depth interval 
####  ORCDRC : Soil organic carbon content (fine earth fraction) in g per kg at depth 

##  BLDFIE : Bulk density (fine earth) in kg / cubic-meter at depth 

##    CECSOL : Cation exchange capacity of soil in cmolc/kg at depth 
####  CRFVOL : Coarse fragments volumetric in % at depth 

##    ACDWRB_M_ss = Grade of a sub-soil being acid e.g. having a pH < 5 and low BS
####  BDRICM  = Depth to bedrock (R horizon) up to 200 cm
####  BDRLOG_M : Probability of occurence (0-100%) of R horizon
##    HISTPR : Cummulative probability of organic soil based on the TAXOUSDA and TAXNWRB

##  SLGWRB : Sodic soil grade based on WRB soil types and soil pH
##  OCSTHA_M_100cm : Soil organic carbon stock in tons per ha for depth interval 0.00 m - 1.00 m   (_200cm / _30cm)

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/SOILGRIDS/

###----------------------------------------------------------------
####  Prepare the txt file with the file names = variables to process

# for VAR in SLTPPT CLYPPT SNDPPT AWCtS WWP TEXMHT PHIHOX ORCDRC BLDFIE CECSOL CRFVOL; do for NUM in {1..7}; do echo ${VAR} _M_sl${NUM}_250m_ll.tif; done ; done > $DIR/soil_var_names.txt

# echo ACDWRB _M_ss_250m_ll.tif >> $DIR/soil_var_names.txt
# echo BDRICM _M_250m_ll.tif >> $DIR/soil_var_names.txt
# echo BDRLOG _M_250m_ll.tif >> $DIR/soil_var_names.txt
# echo HISTPR _250m_ll.tif >> $DIR/soil_var_names.txt
# echo SLGWRB _250m_ll.tif >> $DIR/soil_var_names.txt
###----------------------------------------------------------------


LINE=$(cat $DIR/soil_var_names.txt | head -n $SLURM_ARRAY_TASK_ID | tail -1)  ### first 1 replace with $SLURM_ARRAY_TASK_ID

VAR=$(echo $LINE | awk '{ print $1 }' )
SEC=$(echo $LINE | awk '{ print $2 }' )

mkdir $DIR/$VAR
cd $DIR/$VAR

wget https://files.isric.org/soilgrids/data/recent/${VAR}${SEC}
gdal_edit.py -a_ullr -180 84 180 -56 ${VAR}${SEC}


