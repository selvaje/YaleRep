# bsub -W 24:00 -n 1 -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_compunit.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_compunit.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc03_compunit.sh

# 1 kg di farena
# 300 lievito madre
# 1 cucchiaino di sale 
# 5 chcchiaio di zucchero 
# 250 olio 
# impastare con il vino 

# new  one 
# 497  5656337     camptcha 
# 346  6254072     ? 
# 1145 7642013     ? 
# 810  7949852     ?  
# 3317 12175858    MADAGASCAR  
# 2597 14470128    guinea ? 
# 3005 15937346    canada island   
# 154  24790283    canada island
# 573  158907908   greenland 
# 3629 160965130   Australia 
# 4000 360948377   South America 
# 4001 578979392   Africa 
# 3753 659333926   north Amarica 
# 3562 1519030245  EUROASIA 
# 3767 8275779607  sea 

export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/GSHHG
RAM=/dev/shm/

echo create island dataset 

WC=$(wc -l $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_s.txt | awk '{ print $1 }' )
awk -v WC=$WC '{ if(NR < ( WC - 12 )) {print $1 , $1 } else { print $1,0 }}' $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_s.txt > $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_island_tmp.txt

# controllare a mano i valori 

#        camptacha  island-west    island-east
awk '{ if($1==497 ||  $1==338 || $1==333 ) { print $1 , 0  }  else {  print $1 , $2 } }'  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_island_tmp.txt >    $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_island.txt  
rm     $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_island_tmp.txt    


pkreclass -co COMPRESS=DEFLATE -co ZLEVEL=9 -code $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_island.txt  -i   $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif -o  $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNITisland.tif
set all the island  ugula to 1
pkgetmask -ct  /dev/shm/color.txt  -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot Byte   -min 0.5   -max  999999999  -data 1   -i $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNITisland.tif  -o $DIR/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNITisland0-1.tif 

# create the island_areas in qgis 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK
gdal_rasterize -ot Byte -te -180 -60 +180 +84 -tr 0.002083333333333333 0.002083333333333333 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a id -l island_areas $DIR/shp/island_areas.shp $DIR/shp/island_areas.tif 

pkcreatect -min 1 -max 14 >  /dev/shm/color.txt 
pkcreatect -ot Byte -co COMPRESS=DEFLATE -co ZLEVEL=9  -ct   /dev/shm/color.txt   -i $DIR/shp/island_areas.tif  -o  $DIR/shp/island_areas_ct.tif  ;
rm -rf  $DIR/shp/island_areas.tif 

echo 1 2 3 4 5 6 7 8 9 10 11 12 13 14  | xargs -n 1 -P 14  bash -c  $' 

geo_string=$(oft-bb  $DIR/shp/island_areas_ct.tif $1 | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\') 
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNITisland0-1.tif /dev/shm/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT$1.tif  
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 -srcwin $geo_string  $DIR/shp/island_areas_ct.tif  /dev/shm/island_areas_ct$1.tif

pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -m /dev/shm/island_areas_ct$1.tif  -msknodata $1  -nodata 0 -p "!" -i /dev/shm/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT$1.tif -o  $DIR/unit/UNIT${1}msk.tif  

' _ 

# create computationa unit for the continent

tail -13 $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_s.txt | head -12  | xargs -n 2 -P 8 bash -c $' 
echo start the geo_string operation 
geo_string=$( oft-bb $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  $1  | grep BB | awk \'{ print $6,$7,$8-$6+1,$9-$7+1 }\')
gdal_translate   -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin  $geo_string  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif $DIR/unit/UNIT$1.tif 
pkgetmask -ct   /dev/shm/color.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min $1 -max $1 -data 1 -nodata 0 -i $DIR/unit/UNIT$1.tif  -o $DIR/unit/UNIT${1}msk.tif 

' _

echo  EUROASIA camptacha 497

geo_string=$( oft-bb $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif 497  | grep BB | awk '{ print $6,$7,$8-$6+1,$9-$7+1 }')
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin  $geo_string  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif $DIR/unit/UNIT497.tif 
pkgetmask    -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 496.5 -max 497.5   -data 1 -nodata 0 -i  $DIR/unit/UNIT497.tif  -o $DIR/unit/UNIT497msk.tif

export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK
echo   island-west  338   island-est 333
pkcreatect -min 1 -max 14 >  /dev/shm/color.txt 

geo_string=$( oft-bb $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif 338  | grep BB | awk '{ print $6,$7,$8-$6+1,$9-$7+1 }')
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin  $geo_string  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif $DIR/unit/UNIT338.tif 
pkgetmask    -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 337.5 -max 338.5   -data 1 -nodata 0 -i  $DIR/unit/UNIT338.tif  -o $DIR/unit/UNIT338msk.tif

geo_string=$( oft-bb $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif 333  | grep BB | awk '{ print $6,$7,$8-$6+1,$9-$7+1 }')
gdal_translate  -co COMPRESS=DEFLATE -co ZLEVEL=9  -srcwin  $geo_string  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif $DIR/unit/UNIT333.tif 
pkgetmask    -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 332.5 -max 333.5   -data 1 -nodata 0 -i  $DIR/unit/UNIT333.tif  -o $DIR/unit/UNIT333msk.tif

# merge  EUROASIA 3562 +   island-west  338  ########  camptacha 497  +  island-est  333 

pkcreatect -min 0 -max 1  >  /dev/shm/color.txt 
pkcomposite -dstnodata 0 -ct  /dev/shm/color.txt -cr sum -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/unit/UNIT497msk.tif  -i $DIR/unit/UNIT338msk.tif  -o $DIR/unit/UNIT497_338msk.tif   #  camptacha  + island-west 
pkcomposite -dstnodata 0 -ct  /dev/shm/color.txt -cr sum -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $DIR/unit/UNIT3562msk.tif -i $DIR/unit/UNIT333msk.tif  -o $DIR/unit/UNIT3562_333msk.tif  # EUROASIA + east-island 

# create a clumpMSKclump_UNIT  with sea 3767   EUROASIA 13496 +   island-est  1191  ########  camptacha 2524 +  island-west  1215 = 0  (old numbers just for reference ) 
                                                                                                                    #      sea         EUROASIA     island-est   camptacha       island-west  
pksetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -m  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif -msknodata  3767  -msknodata 3562  -msknodata 338  -msknodata 497  -msknodata 333  -nodata 0 \
 -i  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT.tif  -o  $DIR/GSHHG/GSHHS_land_mask250m_enlarge_clumpMSKclump_UNIT_noeuroasia.tif 


exit 

# old one 

# 11003 8209728    indonesia   #  
# 13283 11853191   MADAGASCAR  # 
# 1667 13166954    canada island 
# 10687 14013636     guinea    # 
# 11730 15288346   canada island  
# 612 23165874     canada island  
# 3260 153178164   greenland 
# 13632 158925073    australia  
# 20000 354955227   South America  
# 20001 576949211  africa  
# 14064 633972786  North america 
# 13496 1494258173 euroasia 
# 14196 8336810723 sea 

# new one 
# 497 5656337      ?
# 346 6254072      ? 
# 1145 7642013     ? 
# 810 7949852      ?  
# 3317 12175858    MADAGASCAR  
# 2597 14470128    guinea ? 
# 3005 15937346    canada island   
# 154 24790283     canada island
# 573 158907908    greenland 
# 3629 160965130   Australia 
# 20000 360948377  South America 
# 20001 578979392  Africa 
# 3753 659333926   north Amarica 
# 3562 1519030245  EUROASIA 
# 3767 8275779607  sea 
