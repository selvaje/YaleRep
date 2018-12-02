# bash   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc02_core.sh
# bsub -W 24:00 -n 8 -R "span[hosts=1]" -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_core_1k_250.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_core_1k_250.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc02_core_1k_250.sh 1k
# in caso di rerun su slurm correggere anche il 1km

export RES=$1

export DIR=/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_bin

pkcreatect -min 0 -max 1 > /tmp/color.txt 
pkcreatect -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte  -nodata -1 -min 0 -max 1  -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin9.tif   -o  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin9_clean.tif
gdal_edit.py -a_nodata -1  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin9_clean.tif

echo  0 1 2 3 4 5 6 7 8 9 | xargs -n 1 -P 8 bash -c $'
gdal_edit.py -a_nodata -1  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin$1.tif
' _

echo 2 3 4 5 6 7 8 9 | xargs -n 1 -P 8 bash -c $'

    bin1=$1
    bin2=$(bc <<< "$bin1-1")
    echo $bin1
        rm -f $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin1}+${bin2}.tif 
        # sum the bin-levels, if the result is 1 is a peak, if 2 means no peak.  
        gdal_calc.py --calc="A+B" --co="COMPRESS=LZW" --overwrite --NoDataValue=-1 \
            -A $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin1}.tif \
            -B $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin2}.tif \
            --outfile=$DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin1}+${bin2}.tif
        # calculate min and max for each bin-unit
        oft-stat -mm --noavg --nostd \
            -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin1}+${bin2}.tif \
            -um $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin2}_clump.tif \
            -o  $DIR/zonal_stats_${bin2}.txt
        # if the maximum value is 1  means than is a peak for that level  
        awk \'{if($4==1) { print $1,1 }  else { print $1,0 }}\' $DIR/zonal_stats_${bin2}.txt > $DIR/code_${bin2}.txt

        # reclassify to 0 to 1 to  map only the peaks  
        pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte -nodata -1 -ct /tmp/color.txt \
            -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin2}_clump.tif \
            -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin2}_clean.tif \
            --code $DIR/code_${bin2}.txt

        rm -f $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin${bin1}+${bin2}.tif
        rm -f $DIR/zonal_stats_${bin2}.txt
        rm -f $DIR/code_${bin2}.txt

' _

# merge the peak for each bin-levl
                                                                                           #  only select core from the bin 2 on  
gdalbuildvrt -overwrite  -separate $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core.vrt $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin{2,3,4,5,6,7,8,9}_clean.tif

oft-calc -ot Byte $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core.vrt $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_tmp.tif << EOF
1
#1 #2 #3 #4 #5 #6 #7 #8 + + + + + + +
EOF

rm $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core.vrt 

pkcreatect  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte -nodata -1 -min 0 -max 1   -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_tmp.tif -o  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_tmp.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core.tif
rm  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_tmp.tif

# mask the bin with the core to have the bin level for each core 

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct.tif  -msknodata 0 -nodata 0  \
 -i $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin_ct.tif  -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_bin_ct.tif


# mask sl bin_clump del sc02_clump_reclass_1k.sh con il core to have the bin_clump for each core 

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 -m $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct.tif   -msknodata 0 -nodata 0   -i  ${DIR}/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_core_clump.tif 

exit 


# remove the below part


# oft-stat         -i  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_bin_ct.tif \
#                  -um ${DIR}/../GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_bin_clump_reclass/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_WGS84_bin_clump.tif \
#                   -o $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_bin_clump_core_clump.txt 

# reapeat the operation -um con il watershed clump in script 

# echo clump the core , rimosso effettuao il clumping con il bin-unit in modo tale the ogni watershed ha il suo peak corrispondente al bin. 

# rm -fr  ${DIR}/grassdb/loc_clump_core                                                                        
# gdal_edit.py -a_nodata 0 $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct.tif
  
# source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2.sh  ${DIR}/grassdb_${RES} loc_clump_core    $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct.tif  

# r.clump -d  --overwrite    input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_ct      output=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump
# r.colors -r map=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump 

# r.out.gdal nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump   output=$DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump.tif 
# rm -fr  ${DIR}/grassdb_${RES}/loc_clump_core                                                                        

#  rimosso per non farlo fare al 250 
# bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump_random_color.txt 
# gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump.tif  $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump_random_color.txt   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump_ct.tif 
# gdal_edit.py -a_nodata 0   $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump_ct.tif  

rm -rf    $DIR/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_${RES}_v1_0_WGS84_core_clump_random_color.txt 

#  bsub  -W 2:00  -M 50000  -R "rusage[mem=50000]"  -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_cost_1k_250.sh.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_cost_1k_250.sh.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc03_cost_1k_250.sh  1k
