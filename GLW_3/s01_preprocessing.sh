#!/bin/bash 

source ~/bin/gdal
source ~/bin/pktools 

# manually download data from
#https://dataverse.harvard.edu/dataset.xhtml?persistentId=doi:10.7910/DVN/BLWPZN#
# ._Da.tif (RF output) chosen over ._Aw.tif (Weighted ave) because we want to do the aggregation by ourselves.  

export dirIn=/home/sbsc/ls732/DataSets/GLW_3
export dirOut=/home/sbsc/ls732/DataSets/GLW_3

amlLst=(Bf Ch Ct Dk Gt Ho Pg Sh)

echo ${amlLst[@]} | xargs -n 1 -P 8 bash -c $'
aml=$1
echo ${aml}
tifOri=5_${aml}_2010_Da.tif
tifMsk=5_${aml}_2010_Da_msk.tif

pksetmask   -m  ${dirIn}/${tifOri}  -msknodata -9999999  -nodata -9999 -p "<"   -i  ${dirIn}/${tifOri}  -o  ${dirOut}/${tifMsk} -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Float32

' _



