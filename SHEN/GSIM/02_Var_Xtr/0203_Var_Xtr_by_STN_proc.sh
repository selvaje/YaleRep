#!/bin/bash 

function var_Xtr_grep(){
# this is to grep values from the output of gdallocationinfo     
    local args=("$@")    
    export fSTN=${args[0]}
    export dirRAW=${args[1]}
    export dirOut=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}

if [ -d ${dirOut}/${datSet} ]; then
    rm -rf ${dirOut}/${datSet}
fi
mkdir -p ${dirOut}/${datSet}/Grep
mkdir -p ${dirOut}/${datSet}/QC

for var in ${varLst[@]} 
do
touch ${dirOut}/${datSet}/QC/${var}_QC.dat
done

cut -d, -f1 ${fSTN} | xargs -n 1 -P 70 bash -c $'
ID=$1

for var in ${varLst[@]} 
do
value=($(grep Value ${dirRAW}/${datSet}/${var}_${ID}.dat | awk -F: \'{print $2}\'))
echo ${ID} ${value[@]} > ${dirOut}/${datSet}/Grep/${var}_${ID}.dat
echo ${ID} ${#value[@]} >> ${dirOut}/${datSet}/QC/${var}_QC.dat 
done

' _
}

function Row_to_Col(){
# this is to convert data in the row format into column format
    local args=("$@")    
    export fSTN=${args[0]}
    export dirRow=${args[1]}
    export dirCol=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}

if [ -d ${dirCol}/${datSet}/Col_by_STN ]; then
    rm -rf ${dirCol}/${datSet}/Col_by_STN
fi
mkdir -p ${dirCol}/${datSet}/Col_by_STN

cut -d, -f1 ${fSTN} | xargs -n 1 -P 70 bash -c $'
ID=$1
if [ ${datSet} = "TERRA" ]; then
    for var in ${varLst[@]} 
    do
    awk \'{for(i=2;i<=NF;i++) print $i}\' ${dirRow}/${datSet}/Grep/${var}_${ID}.dat > ${dirCol}/${datSet}/Col_by_STN/${var}_${ID}_col.dat
    done
elif [ ${datSet} = "GRAND" ]; then
    for var in ${varLst[@]} 
    do
    awk \'{for(i=2;i<=NF;i++) {for (j=1;j<=12;j++) print $i}}\' ${dirRow}/${datSet}/Grep/${var}_${ID}.dat > ${dirCol}/${datSet}/Col_by_STN/${var}_${ID}_col.dat
    done
else     
    for var in ${varLst[@]} 
    do
    awk \'{for (i=1;i<=708;i++) print $2}\' ${dirRow}/${datSet}/Grep/${var}_${ID}.dat > ${dirCol}/${datSet}/Col_by_STN/${var}_${ID}_col.dat
    done
fi
' _
}


function STN_Aggr(){
# this is to aggregate STN data into a single file
    local args=("$@")    
    export fSTN=${args[0]}
    export dirSTN=${args[1]}
    export dirCat=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}

if [ -d ${dirSTN}/${datSet}/Cated ] ; then
    rm -rf ${dirSTN}/${datSet}/Cated
fi

mkdir ${dirSTN}/${datSet}/Cated

echo ${varArr[@]} | xargs -n 1 -P 70 bash -c $'
var=$1
while read -r ID
do
cat ${dirSTN}/${datSet}/Col_by_STN/${var}_${ID}_col.dat >> ${dirCat}/${datSet}/Cated/${var}.dat   
done < ${fSTN}
' _
}

function STN_Aggr_relay(){
# this is to aggregate STN data into a single file
    local args=("$@")    
    export fSTN=${args[0]}
    export dirSTN=${args[1]}
    export dirCat=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}

for relay in {1..5}
do

if [ -d ${dirSTN}/${datSet}/Cated/relay${relay} ] ; then
    rm -rf ${dirSTN}/${datSet}/Cated/relay${relay}
fi

mkdir ${dirSTN}/${datSet}/Cated/relay${relay}

export relay

echo ${varArr[@]} | xargs -n 1 -P 70 bash -c $'
var=$1
while read -r ID
do
cat ${dirSTN}/${datSet}/Relay/relay${relay}/${var}_${ID}.dat >> ${dirCat}/${datSet}/Cated/relay${relay}/${var}.dat   
done < ${fSTN}
' _
done
}


function Aggr_paste(){
# this is to paste aggregated files into one
    local args=("$@")    
    export fRelay=${args[0]} # relay flag
    export dirProc=${args[1]}
    export dirPst=${args[2]}
    export datSet=${args[3]}
    export varLst=${args[@]:4:${#args[@]}}

    declare -a header=()
    if [ -d ${dirProc}/${datSet}/Psted ] ; then
        rm -rf ${dirProc}/${datSet}/Psted
    fi
    mkdir ${dirProc}/${datSet}/Psted
    touch ${dirProc}/${datSet}/Psted/${datSet}.csv

if [ ${fRelay} -eq 1 ]; then
    for relay in {0..5}
    do
        for var in ${varLst[@]}
        do
           header+=(${var}${relay})
           paste -d,  ${dirPst}/${datSet}/Psted/${datSet}.csv ${dirProc}/${datSet}/Cated/relay${relay}/${var}.dat  > ${dirPst}/${datSet}/Psted/temp.csv
           mv ${dirPst}/${datSet}/Psted/temp.csv ${dirPst}/${datSet}/Psted/${datSet}.csv
        done
    done
else
    for var in ${varLst[@]} 
    do
           header+=(${var}${relay})
           paste -d,  ${dirPst}/${datSet}/Psted/${datSet}.csv ${dirProc}/${datSet}/Cated/${var}.dat  > ${dirPst}/${datSet}/Psted/temp.csv
           mv ${dirPst}/${datSet}/Psted/temp.csv ${dirPst}/${datSet}/Psted/${datSet}.csv
    done
fi
echo ${header[@]} | tr " " "," > ${dirPst}/${datSet}/Psted/header.csv
cut -d, -f2-  ${dirPst}/${datSet}/Psted/${datSet}.csv >  ${dirPst}/${datSet}/Psted/temp.csv
cat ${dirPst}/${datSet}/Psted/header.csv ${dirPst}/${datSet}/Psted/temp.csv >  ${dirPst}/${datSet}/Psted/${datSet}.csv
rm ${dirPst}/${datSet}/Psted/header.csv ${dirPst}/${datSet}/Psted/temp.csv
}

########
# MAIN #
########

dirGSIM=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/GSIM_Summ
dirRAW=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/RAW
export dirProc=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/procd
export dirQC=/data/shen/Discharge/Data_Proc/GSIM/02_Var_Xtr/by_STN/QC/TERRA

##############
# TERRA Data #
##############

#varArr=(tmin soil tmax ppt)
# var_Xtr_grep ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirRAW} ${dirProc} TERRA ${varArr[@]}
# Row_to_Col ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirProc} ${dirProc} TERRA ${varArr[@]}
# STN_Aggr ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} TERRA ${varArr[@]}

#-------------------
# create relay 
#-------------------

# if [ -d ${dirProc}/TERRA/Relay ]; then
#     rm -rf ${dirProc}/TERRA/Relay
# fi
# mkdir ${dirProc}/TERRA/Relay

# for relay in {1..5}
# do
#     printf '%s\n' ${relay}
#     export relay
#     mkdir ${dirProc}/TERRA/Relay/relay${relay}
# cat ${dirQC}/ID_wo_error.dat | xargs -n 1 -P 70 bash -c $'
# ID=$1
# varArr=(tmin soil tmax ppt)
# for var in ${varArr[@]}
# do
#     fOri=${dirProc}/TERRA/Col_by_STN/${var}_${ID}_col.dat
#     nL=$((-($relay - 1)))
#     if [ ${nL} -eq 0 ];
#     then nL=\'$\'
#     fi
#     printf \'%s\n\' "${nL},\$m0" ,p Q | ed -s ${fOri} > ${dirProc}/TERRA/Relay/relay${relay}/${var}_${ID}.dat
# done
# ' _
# done

#-------------------
# aggregate relayed data 
#-------------------

# mkdir ${dirProc}/TERRA/Cated/relay0
# mv ${dirProc}/TERRA/Cated/*.dat  ${dirProc}/TERRA/Cated/relay0

# varArr=(tmin tmax ppt soil)
# STN_Aggr_relay ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} TERRA ${varArr[@]}
# Aggr_paste 1 ${dirProc} ${dirProc} TERRA ${varArr[@]}

##############
# GRAND DATA #
##############

varArr=(GRAND)
# var_Xtr_grep ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirRAW} ${dirProc} GRAND ${varArr[@]}
# Row_to_Col ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirProc} ${dirProc} GRAND ${varArr[@]}
# STN_Aggr ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} GRAND ${varArr[@]}
# Aggr_paste 0 ${dirProc} ${dirProc} GRAND ${varArr[@]}

#####################
# Static Variables  #
#####################

############
# GRIDSOIL #
############

# varArr=(AWCtS CLYPPT SNDPPT SLTPPT WWP)
# var_Xtr_grep ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirRAW} ${dirProc} SOILGRIDS ${varArr[@]}
# Row_to_Col ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirProc} ${dirProc} SOILGRIDS ${varArr[@]}
# STN_Aggr ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} SOILGRIDS ${varArr[@]}
# Aggr_paste 0 ${dirProc} ${dirProc} SOILGRIDS ${varArr[@]}

########
# GRWL #
########

# varArr=(canal delta lake river water)
# var_Xtr_grep ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirRAW} ${dirProc} GRWL ${varArr[@]}
# Row_to_Col ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirProc} ${dirProc} GRWL ${varArr[@]}
# STN_Aggr ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} GRWL ${varArr[@]}
# Aggr_paste 0 ${dirProc} ${dirProc} GRWL ${varArr[@]}

#######
# GSW #
#######

# varArr=(extent occurrence recurrence seasonality)
# var_Xtr_grep ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirRAW} ${dirProc} GSW ${varArr[@]}
# Row_to_Col ${dirGSIM}/TS_summ_!phi_snapped.csv ${dirProc} ${dirProc} GSW ${varArr[@]}
# STN_Aggr ${dirQC}/ID_wo_error.dat ${dirProc} ${dirProc} GSW ${varArr[@]}
# Aggr_paste 0 ${dirProc} ${dirProc} GSW ${varArr[@]}

################
# All Together #
################

paste -d, ${dirProc}/TERRA/Psted/TERRA.csv ${dirProc}/GRAND/Psted/GRAND.csv ${dirProc}/SOILGRIDS/Psted/SOILGRIDS.csv ${dirProc}/GRWL/Psted/GRWL.csv ${dirProc}/GSW/Psted/GSW.csv  > ${dirProc}/var_All.csv 
