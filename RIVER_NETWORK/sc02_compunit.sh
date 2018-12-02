# bsub -W 10:00 -n 1 -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_compunit.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_compunit.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc02_compunit.sh

# 1 kg di farena
# 300 lievito madre
# 1 cucchiaino di sale 
# 5 chcchiaio di zucchero 
# 250 olio 
# impastare con il vino 

export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG
RAM=/dev/shm/

# use this as main mask data 

gdal_edit.py -a_nodata -1    $DIR/GSHHS_land_mask250m_enlarge_clumpMSK.tif 
rm -fr  $DIR/../grassdb/loc_MSK 
source /gpfs/home/fas/sbsc/ga254/scripts/general/create_location_grass7.0.2.sh $DIR/../grassdb  loc_MSK  $DIR/GSHHS_land_mask250m_enlarge_clumpMSK.tif  # = a  GSHHS_land_mask250m_enlarge_clump.tif

echo clump # fatto un altro clamp per evitore i no data nelle zone interne.
r.clump -d  --overwrite    input=GSHHS_land_mask250m_enlarge_clumpMSK  output=GSHHS_land_mask250m_enlarge_clumpMSKclump

r.out.gdal nodata=0 --overwrite -f -c   createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff type=UInt32 input=GSHHS_land_mask250m_enlarge_clumpMSKclump  output=$DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump.tif 

# # 98339 america north and south  ????
# # 91514 africa eurasia    ?????
# # max value 

pkstat --hist -i $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump.tif | sort -g -k 2,2 | tail -3 > /tmp/hist.txt 

NSAMERICAUNIT=$( awk '{ if(NR==1) print $1 }'  /tmp/hist.txt  )
AFRICAASIAUNIT=$( awk '{ if(NR==2) print $1 }' /tmp/hist.txt  )

rm -f /tmp/hist.txt 

# africa 
# rm  -f  $DIR/../shp/suez.*
# ogr2ogr  -clipsrc 31 27 36 32  $DIR/../shp/suez.shp  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG/version2.3.6/GSHHS_shp/f/GSHHS_f_L1.shp 
# create the africa.shp in qgis 

# gdal_rasterize -ot Byte -te -180 -60 +180 +84 -tr 0.002083333333333333 0.002083333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9   -burn 1 -l "africa"   $DIR/../shp/africa.shp     $DIR/../shp/africa.tif   
pkcreatect -min 0 -max 1 > /dev/shm/color.txt 
pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $( echo $AFRICAASIAUNIT - 0.5 | bc )  -max $( echo $AFRICAASIAUNIT + 0.5 | bc  ) -ct /dev/shm/color.txt  -data 1 -nodata 0 -i $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump.tif -o $DIR/africaeuroasia.tif 

gdalbuildvrt -separate -overwrite $DIR/outvrt.vrt   $DIR/africaeuroasia.tif $DIR/../shp/africa.tif

oft-calc  -ot Byte $DIR/outvrt.vrt   $DIR/SUMafricaeuroasia.tif <<EOF
1
#1 #2 +
EOF

pkcreatect -min 0 -max 2 > /dev/shm/color.txt 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i $DIR/SUMafricaeuroasia.tif -o $DIR/SUMafricaeuroasia_ct.tif ; 
pkgetmask -ct  /dev/shm/color.txt     -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min 2  -max 3   -data 1   -nodata 0    -i  $DIR/SUMafricaeuroasia.tif -o $DIR/africa_clean_ct.tif 

rm -f   $DIR/SUMafricaeuroasia.tif   $DIR/SUMafricaeuroasia_ct.tif  $DIR/africa_clean.tif   $DIR/africaeuroasia.tif   $DIR/africaeuroasia_ct.tif 

# euroasia 
rm -f  $DIR/../shp/panama.* 
ogr2ogr -clipsrc   -82 +5  -73 13    $DIR/../shp/panama.shp   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG/version2.3.6/GSHHS_shp/f/GSHHS_f_L1.shp 
# create the africa.shp in qgis 

# gdal_rasterize -ot Byte -te -180 -60 +180 +84 -tr 0.002083333333333333 0.002083333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9   -burn 1 -l "southamerica"   $DIR/../shp/southamerica.shp     $DIR/../shp/southamerica.tif   

pkgetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min  $( echo $NSAMERICAUNIT - 0.5 | bc )    -max  $( echo $NSAMERICAUNIT  + 0.5 | bc )   -data 1 -nodata 0 -i  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump.tif -o  $DIR/northsoutamerica.tif 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i $DIR/northsoutamerica.tif  -o $DIR/northsoutamerica_ct.tif   

gdalbuildvrt -separate -overwrite  $DIR/outvrt.vrt    $DIR/northsoutamerica.tif   $DIR/../shp/southamerica.tif   

oft-calc  -ot Byte $DIR/outvrt.vrt   $DIR/SUMnorthsoutamerica.tif <<EOF
1
#1 #2 +
EOF

pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct /dev/shm/color.txt -i  $DIR/SUMnorthsoutamerica.tif  -o  $DIR/SUMnorthsoutamerica_ct.tif 
pkgetmask  -ct /dev/shm/color.txt   -co COMPRESS=DEFLATE -co ZLEVEL=9  -ot Byte  -min 2  -max 3   -data 1   -nodata 0    -i   $DIR/SUMnorthsoutamerica_ct.tif   -o  $DIR/southamerica_clean_ct.tif  

rm -f $DIR/SUMnorthsoutamerica.tif  $DIR/SUMnorthsoutamerica_ct.tif   $DIR/southamerica_clean.tif   $DIR/southamerica.tif  $DIR/northsoutamerica.tif  $DIR/northsoutamerica_ct.tif   $DIR/outvrt.vrt 

pksetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9 \
           -m  $DIR/southamerica_clean_ct.tif  -msknodata 1  -nodata 4000 \
           -m  $DIR/africa_clean_ct.tif        -msknodata 1  -nodata 4001 \
           -i  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump.tif  -o  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif
 

pkstat --hist -i  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif   | grep  -v " 0" >   $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.txt 
sort -k 2,2 -g    $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.txt   >     $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_s.txt 

# far partire il seguente dopo aver controllato i valori di captacha e altre isole 
bsub -W 24:00 -n 1 -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_compunit.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_compunit.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc03_compunit.sh


