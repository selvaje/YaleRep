#!/bin/bash

#############
# Var Corr. #
#############

# dirTabl=/data/shen/Discharge/Data_Proc/GSIM/03_Modelling/Tabl_Merge
# dirOut=/data/shen/Discharge/Data_Proc/GSIM/03_Modelling/Modelling/solo_SOILGRID

# python3 pred_Model.py ${dirTabl}/tabl_GSIM_Var_relay5.csv ${dirOut}/ MEAN 0

##################
# resp. var. 	 #
# GSIM discharge #
##################

dirTabl=/data/shen/Discharge/Data_Proc/GSIM/03_Modelling/Tabl_Merge
dirOut1=/data/shen/Discharge/Data_Proc/GSIM/03_Modelling/Modelling/TERRA_GSW

obsTypes=(MEAN MIN MAX)

for relay in 0 1 3 5
do
	     
if [ -d ${dirOut1}/relay${relay} ]; then
    rm -rf ${dirOut1}/relay${relay}
fi

mkdir ${dirOut1}/relay${relay}

# if [ -d ${dirOut2}/relay${relay} ]; then
#     rm -rf ${dirOut2}/relay${relay}
# fi

# mkdir ${dirOut2}/relay${relay}

for obs in ${obsTypes[@]}
do
echo $obs
python3 pred_Model.py ${dirTabl}/tabl_GSIM_Var_relay5.csv ${dirOut1}/relay${relay}/ ${obs} ${relay}
#python3 pred_Model_geoLoc.py ${dirTabl}/tabl_GSIM_Var_relay5.csv ${dirOut2}/relay${relay}/ ${obs} ${relay}
done
done

