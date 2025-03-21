#!/bin/bash

#export RAM=/dev/shm

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

dirMsk=/mnt/shared/data_from_yale/MERIT_HYDRO
IDtiles=(seq 1 116)
IDlarge=(seq 150 200)

export dirVar=/mnt/shared/data_from_yale/dataproces
export dirMERIT=/mnt/shared/data_from_yale/MERIT_HYDRO
export dirOut=/data/shen/Discharge/Data_Proc/02_PDF

export GDAL_CACHEMAX=3000 # MB


#################
# TERRA dataSet #
#################

SetNam=TERRA
varLst=(tmin tmax ppt soil)

export fmskname=$(basename $fmsk .tif  )

if [ -d ${dirOut}/${SetNam} ]; then
    rm -rf ${dirOut}/${SetNam}
fi

mkdir ${dirOut}/${SetNam}

for var in ${varLst[0]}
do
    mkdir ${dirOut}/${SetNam}/${var}
    for year in ${yrLst[0]}
    do
	mkdir ${dirOut}/${SetNam}/${var}/${year}
	for mon in ${monLst[@]}
	do
	    for basGrp in tiles large
	    do
		case $basGrp in
		    tiles )
			arrID=("${IDtiles[@]}") ;;
		    large )
			arrID=("${IDlarge[@]}") ;; 
		esac
		for ID in ${arrID[@]}
		do
		    echo ${SetNam} ${var} ${year} ${mon} ${basGrp} ${ID}
		done
	    done            
	done
    done
done  | xargs -n 6 -P 70 bash -c $'
SetNam=$1
var=$2
year=$3
mon=$4
basGrp=$5
ID=$6
dirMsk=${dirMERIT}/lbasin_compUnit_${basGrp}
fIDmsk=bid_${ID}_msk.tif

# crop base on compunit extend
gdal_translate  -a_ullr $(./getCorners4Gtranslate ${dirMsk}/${fIDmsk})  -projwin $(./getCorners4Gtranslate ${dirMsk}/${fIDmsk})  -co COMPRESS=DEFLATE -co ZLEVEL=9 ${dirVar}/${SetName}/${var}_acc/${year}/${var}_${year}_${mon}.vrt  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333 ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc.tif
gdal_edit.py  -a_ullr  $(./getCorners4Gtranslate ${dirMsk}/${fIDmsk})  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc.tif

# mask base on the compunit 
pksetmask of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m ${dirMsk}/${fIDmsk}  -msknodata 0 -nodata -9999999  -i ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc.tif -o  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc_msk.tif

rm -f ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc.tif

# hist 
#pkstat -hist -src_min 0 -src_max 999999  -i ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc_msk.tif  > ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc_hist.dat

###  pre_acc

gdal_translate  -a_nodata -9999  -a_srs EPSG:4326 -r bilinear -ot Int32  -tr 0.000833333333333333333 0.000833333333333333333   -projwin $(getCorners4Gtranslate $fIDmsk)  -co COMPRESS=DEFLATE -co ZLEVEL=9 -co BIGTIFF=YES ${dirVar}/${SetName}/${var}/${year}/${var}_${year}_${mon}.tif ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori.tif

gdal_edit.py -tr 0.000833333333333333333333333333333333 -0.000833333333333333333333333333333333  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori.tif
gdal_edit.py  -a_ullr  $(getCorners4Gtranslate ${dirMsk}/${fIDmsk})  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori.tif

pksetmask -of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m ${dirMsk}/${fIDmsk}  -msknodata 0 -nodata -9999999  -i ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori.tif -o  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori_msk.tif

rm -f ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori.tif

#pkstat -hist -src_min 0 -src_max 999999 -i ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori_msk.tif   >  ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori_hist.dat

#gdal_calc.py  -A ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_acc_msk.tif -B ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_ori_msk.tif --outfile=${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_diff.tif --calc="(A - B)"

#gdalvart -separate output.var layer1 layer2 

oft-calc  vrt ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_diff.tif <<EOF
1
#1 #2 -
EOF

pksetmask -of GeoTIFF -co BIGTIFF=YES  -co COMPRESS=DEFLATE -co ZLEVEL=9  -m ${dirMsk}/${fIDmsk}  -msknodata 0 -nodata -9999999 -i ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_diff.tif -o ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_diff_msk.tif

rm -f ${dirOut}/${SetNam}/${var}/${year}/${var}_${year}_${mon}_${ID}_diff.tif

' _
