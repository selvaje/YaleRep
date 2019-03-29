#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 4:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -e  /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_mask_enlargment_merge_clamping.sh%J.err
#SBATCH -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_mask_enlargment_merge_clamping.sh%J.out
#SBATCH --job-name=sc03_mask_enlargment.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc04_mask_enlargment_merge_clamping.sh 

module load Apps/GRASS/7.3-beta

DIRP=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
DIRS=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT
RAM=/dev/shm

gdalbuildvrt -overwrite -srcnodata 0 -vrtnodata 0 $DIRP/msk_enlarge/msk_enl1km/all_tif.vrt  $DIRS/msk_enlarge/tiles_km1/*_msk.tif
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9   $DIRP/msk_enlarge/msk_enl1km/all_tif.vrt   $DIRP/msk_enlarge/msk_enl1km/msk_1km.tif 
gdal_edit.py  -a_nodata 0   $DIRP/msk_enlarge/msk_enl1km/msk_1km.tif 

source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.3-grace2.sh /tmp/  loc_$tile  $DIRP/msk_enlarge/msk_enl1km/msk_1km.tif

r.clump -d  --overwrite    input=msk_1km    output=msk_1km_clump 
r.colors -r map=msk_1km_clump 
r.out.gdal nodata=0 --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32  input=msk_1km_clump  output=$DIRP/msk_enlarge/msk_enl1km/msk_1km_clump.tif

pkstat --hist -i  $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump.tif  | sort -g -k 2,2 | tail -3 > /tmp/hist.txt 

NSAMERICAUNIT=$( awk '{ if(NR==1) print $1 }'  /tmp/hist.txt  )
AFRICAASIAUNIT=$( awk '{ if(NR==2) print $1 }' /tmp/hist.txt  )

rm -f /tmp/hist.txt 

# africa 

pkcreatect -min 0 -max 1 > /dev/shm/color.txt 
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $( echo $AFRICAASIAUNIT - 0.5 | bc ) -max $( echo $AFRICAASIAUNIT + 0.5 | bc ) -ct /dev/shm/color.txt -data 1 -nodata 0 -i $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump.tif -o  $DIRP/msk_enlarge/msk_enl1km/africaeuroasia.tif


gdalbuildvrt -separate -overwrite  $DIRP/msk_enlarge/msk_enl1km/outvrt.vrt  $DIRP/msk_enlarge/msk_enl1km/africaeuroasia.tif  $DIRP/shp/africa.tif

oft-calc  -ot Byte $DIRP/msk_enlarge/msk_enl1km/outvrt.vrt   $DIRP/msk_enlarge/msk_enl1km/SUMafricaeuroasia.tif   <<EOF
1
#1 #2 +
EOF

pkcreatect -min 0 -max 2 > /dev/shm/color.txt 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i $DIRP/msk_enlarge/msk_enl1km/SUMafricaeuroasia.tif -o $DIRP/msk_enlarge/msk_enl1km/SUMafricaeuroasia_ct.tif 
pkgetmask -ct  /dev/shm/color.txt     -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min 2  -max 3   -data 1   -nodata 0 -i  $DIRP/msk_enlarge/msk_enl1km/SUMafricaeuroasia_ct.tif -o $DIRP/msk_enlarge/msk_enl1km/africa_clean_ct.tif 

# euroasia 


pkgetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min  $( echo $NSAMERICAUNIT - 0.5 | bc )    -max  $( echo $NSAMERICAUNIT  + 0.5 | bc ) -data 1 -nodata 0 -i  $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump.tif -o $DIRP/msk_enlarge/msk_enl1km/northsoutamerica.tif 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i $DIRP/msk_enlarge/msk_enl1km/northsoutamerica.tif   -o $DIRP/msk_enlarge/msk_enl1km/northsoutamerica_ct.tif 

gdalbuildvrt -separate -overwrite    $DIRP/msk_enlarge/msk_enl1km/outvrt.vrt  $DIRP/msk_enlarge/msk_enl1km/northsoutamerica.tif    $DIRP/shp/southamerica.tif   

oft-calc  -ot Byte     $DIRP/msk_enlarge/msk_enl1km/outvrt.vrt  $DIRP/msk_enlarge/msk_enl1km/SUMnorthsoutamerica.tif <<EOF
1
#1 #2 +
EOF

pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i   $DIRP/msk_enlarge/msk_enl1km/SUMnorthsoutamerica.tif  -o   $DIRP/msk_enlarge/msk_enl1km/SUMnorthsoutamerica_ct.tif
pkgetmask  -ct /dev/shm/color.txt   -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min 2  -max 3   -data 1   -nodata 0    -i     $DIRP/msk_enlarge/msk_enl1km/SUMnorthsoutamerica_ct.tif   -o    $DIRP/msk_enlarge/msk_enl1km/southamerica_clean_ct.tif  



pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
           -m  $DIRP/msk_enlarge/msk_enl1km/southamerica_clean_ct.tif  -msknodata 1  -nodata 30000 \
           -m  $DIRP/msk_enlarge/msk_enl1km/africa_clean_ct.tif        -msknodata 1  -nodata 30001 \
           -i  $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump.tif  -o  $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump_UNIT.tif
gdal_edit.py -a_nodata  0  $DIRP/msk_enlarge/msk_enl1km/msk_1km_clump_UNIT.tif 

rm $DIRP/msk_enlarge/msk_enl1km/{SUMnorthsoutamerica.tif,SUMnorthsoutamerica_ct.tif,southamerica_clean.tif,southamerica.tif,northsoutamerica.tif,northsoutamerica_ct.tif,outvrt.vrt,SUMafricaeuroasia.tif,SUMafricaeuroasia_ct.tif,africa_clean.tif,africaeuroasia.tif,africaeuroasia_ct.tif,southamerica_clean_ct.tif,africa_clean_ct.tif}



