#!/bin/bash

##################
# resp. var. 	 #
# GSIM discharge #
##################

relay=$1
dirTabl=/gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/Processed/02_Model_wo_snapping/datTabl
dirOut=

obsTypes=(MEAN)

if [ -d ${dirOut}/relay${relay} ]; then
    rm -rf ${dirOut}/relay${relay}
fi

mkdir ${dirOut}/relay${relay}

for obs in ${obsTypes[@]}
do
echo $obs
python3 pred_Model.py ${dirTabl}/tabl_GSIM_Terra_Sel_relay_6_${obs}.csv ${dirOut}/relay${relay}/ ${obs} ${relay}
done


