# bsub    -w "$(qmy | grep -e sc08_river_newtworkGMTED250.sh  -e sc08_river_newtworkGMTED250_EUROASIA.sh | awk   '{ printf ("done(%s) && ", $1) }' |   sed 's/....$//')"    -J  sc09_river_newtworkGMTED250_borderCutEUROASIA.sh   -W 24:00 -n 4  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh.%J.err    bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh 

# bsub    -J  sc09_river_newtworkGMTED250_borderCutEUROASIA.sh   -W 24:00 -n 3  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh.%J.err    bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh 

# bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc09_river_newtworkGMTED250_borderCutEUROASIA.sh

cleanram

pkcreatect -min 0 -max 1 >  /tmp/color.txt

echo 3 4 10 100 | xargs -n 1   -P  4  bash  -c $'    
TRH=$1

DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

xoff=$(gdalinfo $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}.tif | grep "Size is" | awk \'{ print $3 -1 }\' )
yoff=0
xsize=1
ysize=$(gdalinfo $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}.tif | grep "Size is" | awk \'{  print $4 }\' )

gdal_translate  -srcwin $xoff $yoff $xsize $ysize  $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}.tif  /dev/shm/basin_last91518_LEFT_trh${TRH}.tif

echo pkstat 
pkstat  --hist -i   /dev/shm/basin_last91518_LEFT_trh${TRH}.tif    | awk \'{ if ($2!=0)  print $1 , 0  }\'  >  /dev/shm/basin_last91518_LEFT_trh${TRH}.txt 
rm -f  /dev/shm/basin_last91518_LEFT_trh${TRH}.tif 
echo pkreclass
pkreclass  -co COMPRESS=DEFLATE -co ZLEVEL=9  -code   /dev/shm/basin_last91518_LEFT_trh${TRH}.txt  -i  $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}.tif   -o $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}_clean.tif

pkgetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot Byte   -min 0.5   -max  9999999999999  -data 1 -ct /tmp/color.txt    -i $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}_clean.tif  -o $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}_cleanmsk.tif

# CENTER 

xoff=$(gdalinfo $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif | grep "Size is" | awk \'{  print $3 -1 }\' )
yoff=0
xsize=1
ysize=$(gdalinfo $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif | grep "Size is" | awk \'{  print $4 }\' )

gdal_translate  -srcwin $xoff $yoff $xsize $ysize  $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif  /dev/shm/basin_last91518_CENTER_trh${TRH}.tif

pkstat --hist -i   /dev/shm/basin_last91518_CENTER_trh${TRH}.tif  | awk \'{ if ($2!=0)  print $1 , 0 }\'  >  /dev/shm/basin_last91518_CENTER_trh${TRH}.txt 

xoff=0
yoff=0
xsize=1
ysize=$(gdalinfo $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif | grep "Size is" | awk \'{  print $4 }\' )

gdal_translate  -srcwin $xoff $yoff $xsize $ysize  $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif  /dev/shm/basin_last91518_CENTER_trh${TRH}.tif

pkstat --hist -i   /dev/shm/basin_last91518_CENTER_trh${TRH}.tif   | awk \'{ if ($2!=0)   print $1 , 0 }\'  >>  /dev/shm/basin_last91518_CENTER_trh${TRH}.txt 
rm -f  /dev/shm/basin_last91518_CENTER_trh${TRH}.tif 
pkreclass  -co COMPRESS=DEFLATE  -co ZLEVEL=9  -code  /dev/shm/basin_last91518_CENTER_trh${TRH}.txt  -i  $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}.tif  -o $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}_clean.tif
pkgetmask   -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot Byte   -min 0.5   -max  9999999999999  -data 1 -ct /tmp/color.txt    -i $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}_clean.tif  -o $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}_cleanmsk.tif

# RIGHT 

xoff=0
yoff=0
xsize=1
ysize=$(gdalinfo $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}.tif | grep "Size is" | awk \'{  print $4 }\' )

gdal_translate  -srcwin $xoff $yoff $xsize $ysize  $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}.tif  /dev/shm/basin_last91518_RIGHT_trh${TRH}.tif

pkstat --hist -i   /dev/shm/basin_last91518_RIGHT_trh${TRH}.tif   | awk \'{ if ($2!=0)   print $1 , 0 }\'  >  /dev/shm/basin_last91518_RIGHT_trh${TRH}.txt 
rm  /dev/shm/basin_last91518_RIGHT_trh${TRH}.tif
pkreclass  -co COMPRESS=DEFLATE -co ZLEVEL=9  -code   /dev/shm/basin_last91518_RIGHT_trh${TRH}.txt  -i  $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}.tif   -o $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}_clean.tif

pkgetmask  -co COMPRESS=DEFLATE -co ZLEVEL=9   -ot Byte   -min 0.5   -max  999999999  -data 1  -ct /tmp/color.txt   -i $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}_clean.tif  -o $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}_cleanmsk.tif

echo start the sum of the map

rm -f  $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk.tif  

gdalbuildvrt -separate  -overwrite   $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk.vrt   $DIR/output/basin_last/basin_last91518_LEFT_trh${TRH}_cleanmsk.tif   $DIR/output/basin_last/basin_last91518_CENTER_trh${TRH}_cleanmsk.tif   $DIR/output/basin_last/basin_last91518_RIGHT_trh${TRH}_cleanmsk.tif

oft-calc -ot Byte   $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk.vrt  $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk_tmp.tif  <<EOF
1
#1 #2 #3 + + 
EOF

pkgetmask  -ot Byte  -co COMPRESS=DEFLATE -co ZLEVEL=9 -min 0.5 -max 9999999999999  -data 1  -ct /tmp/color.txt  -i  $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk_tmp.tif -o $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk.tif 

rm -f   $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk.vrt  $DIR/output/basin_last/basin_last91518_trh${TRH}_cleanmsk_tmp.tif

' _ 

rm -f  /tmp/color.txt  

cleanram

bsub   -W 12:00  -R "span[hosts=1]" -n 4   -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_river_newtworkGMTED250_mergeEUROASIA.sh.%J.out  -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_river_newtworkGMTED250_mergeEUROASIA.sh.%J.err   bash  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc10_river_newtworkGMTED250_mergeEUROASIA.sh
