#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_clump_reclass_1k.sh%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_clump_reclass_1k.sh%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc02_clump_reclass_1k.sh


# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc02_clump_reclass_1k.sh

# relclass the bin clump and then overlay 

export DIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0
export RAM=/dev/shm

# will add to 1 ... so the overall will start from 1 
lastmaxb=0   

for BIN in 1 2 3 4 5 6 7 8 9 ; do 

echo hist for BIN  $BIN
pkstat -hist -i  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif   | grep -v " 0" | awk -v lastmaxb=$lastmaxb '{ if ($1==0) { print $1 , 0  } else { lastmaxb=1+lastmaxb   ; print $1 , lastmaxb }   }' >  $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt

lastmaxb=$(tail -1 $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt   | awk '{ print $2  }')

echo reclass for BIN  $BIN
pkreclass -ot UInt32  -code    $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt     -co COMPRESS=DEFLATE -co ZLEVEL=9  -i  ${DIR}_bin/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif  -o ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif

gdal_edit.py  -a_nodata 0 ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.tif
rm  $RAM/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin${BIN}_clump.txt
done 

 
gdalbuildvrt -separate -overwrite    ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.vrt  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin?_clump.tif


oft-calc -of GTiff -ot UInt32 ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.vrt  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_tmp.tif   <<EOF
1
#1 #2 #3 #4 #5 #6 #7 #8 #9 M M M M M M M M
EOF
gdal_translate -a_nodata 0  -ot   UInt32  -co COMPRESS=DEFLATE -co ZLEVEL=9  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_tmp.tif ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif
rm  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_tmp.tif  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.vrt 

bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct.txt 
awk '{ if(NR==1 ) {print  0, 0, 0, 0, 255 } else {print $0} }' ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct.txt >  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct0.txt  

gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -alpha  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif  ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct0.txt ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct.tif  

rm -f ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct0.txt ${DIR}_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump_ct.txt 





