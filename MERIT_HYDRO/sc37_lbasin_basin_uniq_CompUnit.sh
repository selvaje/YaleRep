#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc37_lbasin_basin_uniq_CompUnitC.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc37_lbasin_basin_uniq_CompUnitC.sh.%A_%a.err
#SBATCH --job-name=sc37_lbasin_basin_uniq_CompUnit.sh
#SBATCH --array=1-166
#SBATCH --mem=50G

####  1-166
#### sbatch  /gpfs/gibbs/pi/hydro/hydro/scripts/MERIT_HYDRO/sc37_lbasin_basin_uniq_CompUnit.sh

ulimit -c 0

source ~/bin/gdal3
source ~/bin/pktools
source ~/bin/grass78m

export MERIT=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO_DEM/
export GRASS=/tmp
export RAM=/dev/shm
export SCMH=/gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO

find  /tmp/       -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +1  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

###  SLURM_ARRAY_TASK_ID=166

export lbasin=$(ls /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_lbasin/lbasin_*_msk.tif   | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export basin=$(ls  /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/CompUnit_basin/basin_*_msk.tif     | head -$SLURM_ARRAY_TASK_ID | tail -1 )
export ID=$( basename $lbasin | awk  '{gsub("_"," ") ;  print $2 }'   )
export GDAL_CACHEMAX=30000

# highest  ID lbasin  1 676 628  = global lbasin   =  sort -g -k 2,2   CompUnit_lbasin/lbasin_*_msk.mm        (1 560 490 with no depression nodata) 
# highest  ID  basin 77 207 874  = global  basin   =  sort -g -k 2,2   CompUnit_basin/basin_*_msk.mm     = some basin can have the same number.. so r.clump

#### performed in script sc36
gdalinfo -mm  $lbasin | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3), int($4)}'  > $SCMH/CompUnit_lbasin/lbasin_${ID}_msk.mm
gdalinfo -mm  $basin  | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3), int($4)}'  > $SCMH/CompUnit_basin/basin_${ID}_msk.mm

grass78  -f -text --tmp-location  -c $SCMH/CompUnit_basin/basin_${ID}_msk.tif  <<'EOF'
GRASSVERBOSE=1
r.external  input=$SCMH/CompUnit_basin/basin_${ID}_msk.tif      output=basin --overwrite
r.external  input=$SCMH/CompUnit_lbasin/lbasin_${ID}_msk.tif    output=lbasin --overwrite

r.clump -d input=lbasin,basin   output=basin_lbasin_clump
r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32  nodata=0 input=basin_lbasin_clump        output=$SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_${ID}.tif 
gdalinfo -mm $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_${ID}.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_${ID}.mm
pkstat  -hist -i $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_${ID}.tif | grep -v " 0" > $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump_${ID}.hist
EOF

### base uniq 726 723 221 ; awk '{ sum = sum + $2 } END {print sum}' CompUnit_basin_lbasin_clump/basin_lbasin_clump_*.mm 
# # finalID from chanel_ident 726 723 221     chanel identifier
### awk '{{ sum = $2 + sum }} END {print sum }'   CompUnit_stream_channel/channel_ident/channel_ident_*.mm

exit 

## procedure qui sotto corretta ma poi trovata la soluzione con r.clump


#######################


echo $lbasin $basin | xargs -n 1 -P 2 bash -c $'

file=$1
min=$(gdalinfo -mm  $file | grep Computed | awk  \'{ gsub(","," ") ; gsub("="," ") ; print int($3) - 1 }\')
filename=$(basename $file .tif )
base=$(basename $file  .tif |  awk -F "_"  \'{    print $1    }\' )

# if some file have already the min = 1  do not perform the substraction.

if [ $min != 0 ] ; then 
oft-calc -ot UInt32 -um  $file $file  $RAM/${filename}_min.tif   <<EOF
1
#1 $min -
EOF
else 
cp $file $RAM/${filename}_min.tif 
fi

pkstat -hist -i $RAM/${filename}_min.tif  | grep -v " 0" |  awk \'{   print $1,  NR-1 }\' > $RAM/${filename}_min.histrec
### cp  $RAM/${filename}_min.tif   $SCMH/CompUnit_${base}_reclas/
pkreclass -ot UInt32 -code $RAM/${filename}_min.histrec -co COMPRESS=DEFLATE -co ZLEVEL=9  -i $RAM/${filename}_min.tif -o $SCMH/CompUnit_${base}_reclas/$filename.tif
rm  $RAM/${filename}_min.tif $RAM/${filename}_min.histrec

gdalinfo -mm $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.tif | grep Computed | awk \'{ gsub(/[=,]/," ",$0); print int($3),int($4)}\' > $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.mm
# count no data ... the 0
pkstat  --hist -i $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.tif | grep -v " 0"  > $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.hist  
head -n 1 $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.hist                        > $SCMH/CompUnit_${base}_reclas/${base}_${ID}_msk.nd

pkstat  --hist -i $SCMH/CompUnit_${base}/${base}_${ID}_msk.tif | grep -v " 0"  > $SCMH/CompUnit_${base}/${base}_${ID}_msk.hist  
head -n 1         $SCMH/CompUnit_${base}/${base}_${ID}_msk.hist                > $SCMH/CompUnit_${base}/${base}_${ID}_msk.nd
' _ 

 
# # highest ID lbasin     77 114 after rescaling from 1 to n # at this moment ID lbasin uniq at global level    1 560 490 ; CompUnit_lbasin_extract  1 560 451
# # highest ID basin  32 667 661 after rescaling from 1 to n # at this moment ID basin  uniq at global level  719 793 627 ; same basin can have same ID; 




  
# # combine the two layers

uniq_lbasin=$(awk '{ print $2 }'  $SCMH/CompUnit_lbasin_reclas/lbasin_${ID}_msk.mm )

if [ $uniq_lbasin -eq 1  ]  ; then 
# if lbasin is only one macro-basin (so max = 1 ) then copy the basin as it is
cp  $SCMH/CompUnit_basin_reclas/basin_${ID}_msk.tif   $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif 
gdalinfo -mm  $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif | grep Computed | awk '{gsub(/[=,]/," ",$0); print int($3), int($4)}' > $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.mm

##### usefull for the reclass globla uniq 
pkstat -hist -i  $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif | grep -v " 0"  > $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.hist
else

echo start grass

grass78  -f -text --tmp-location  -c $SCMH/CompUnit_basin_reclas/basin_${ID}_msk.tif  <<'EOF'
GRASSVERBOSE=1
r.external  input=$SCMH/CompUnit_basin_reclas/basin_${ID}_msk.tif      output=basin_rec --overwrite
r.external  input=$SCMH/CompUnit_lbasin_reclas/lbasin_${ID}_msk.tif    output=lbasin_rec --overwrite

r.clump -d input=lbasin_rec,basin_rec   output=basin_lbasin_clump
r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32  nodata=0 input=basin_lbasin_clump       output=$SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump2_${ID}.tif 
gdalinfo -mm $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump2_${ID}.tif  | grep Computed | awk '{ gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump2_${ID}.mm
pkstat -hist -i $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump2_${ID}.tif | grep -v " 0" > $SCMH/CompUnit_basin_lbasin_clump/basin_lbasin_clump2_${ID}.hist

### use later on a look-up table 
r.report map=lbasin_rec,basin_rec  units=c -i -h -n --q -a  > $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_0.txt 

## create a *10 coefficinet to multiply basin and then sum the lbasin value

max_mult=$(r.info -r lbasin_rec | awk -F "=" '{ if (NR==2) {   
if ( length($2) == 1 ) { dec=10};
if ( length($2) == 2 ) { dec=100};
if ( length($2) == 3 ) { dec=1000};
if ( length($2) == 4 ) { dec=10000};
if ( length($2) == 5 ) { dec=100000};
print dec
 }  }' )

### create a raster having unique value for basin lbasin 
r.mapcalc  " basin_lbasin_sum        =   double( (double(basin_rec) * $max_mult )  + double(lbasin_rec)  ) "  --o 

### r.report has a limitation for reporting floting number as ingteger  larger than 2,147,483,647 
### therefore I implement the r.report map=lbasin_rec,basin_rec that produce a table with smaller numbers
### r.report map=basin_lbasin_sum  units=c -i -h -n --q -a  > $SCMH/CompUnit_basin_uniq/lbasin_basin_sum_${ID}_0.txt

r.out.gdal --o -c -m -f createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=Float64 nodata=0 input=basin_lbasin_sum        output=$SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.tif 

EOF

gdalinfo -mm $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.tif | grep Computed | awk '{ gsub(/[=,]/," ",$0); print int($3),int($4)}' > $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.mm

## not usefull becouse floting 
# min=$(awk '{print $1  }' $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.mm  )
# max=$(awk '{print $2  }' $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.mm  )
# pkstat -src_min $min -src_max $max -hist -i $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.tif | grep -v " 0"  > $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.hist

## start to manipulate the r.report map=lbasin_rec,basin_rec table 
# |   1|                                                               |     315|
# |    |---------------------------------------------------------------|--------|
# |    |2002978| . . . . . . . . . . . . . . . . . . . . . . . . . . . |       9|
# |    |2013243| . . . . . . . . . . . . . . . . . . . . . . . . . . . |      28|
# |    |2028182| . . . . . . . . . . . . . . . . . . . . . . . . . . . |     278|
# |--------------------------------------------------------------------|--------|
# |   2|                                                               |      56|
# |    |---------------------------------------------------------------|--------|
# |    |2067490| . . . . . . . . . . . . . . . . . . . . . . . . . . . |      56|
# |--------------------------------------------------------------------|--------|
# |   3|                                                               |      70|
# |    |---------------------------------------------------------------|--------|
# |    |2068974| . . . . . . . . . . . . . . . . . . . . . . . . . . . |      70|

grep -v  -e "\-" -e TOTAL  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_0.txt  | awk -F "|" '{if (NR>2) {
                          if ($2==int($2)) { col1=int($2)} else { col1="A"} ;
                          if ($3==int($3)) { col2=int($3)} else { col2="B"} ;
                          print col1 , col2 }}' > $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_1.txt

paste  -d " " <(awk '{ print $1  }'  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_1.txt )  <(awk '{ if (NR>1 ) print $2  }'  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_1.txt ) | grep -v "A B" > $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_2.txt

# 1 2002978
# A 2013243
# A 2028182
# 2 2067490
# 3 2068974
# 4 2082002
# 5 2119070

awk 'BEGIN {print 0 , 0 } { 
if (NF==2) {
if (NR==1)   { old=$1 } ;
if ($1=="A") { col1=old } else
               { col1=$1 }
               print col1 , $2 
               old=col1 }
}' $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_2.txt > $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_3.txt

# 0 0
# 1 2002978
# 1 2013243
# 1 2028182
# 2 2067490
# 3 2068974

## col1 lbasin  ; col2 basin 

max=$(sort -k 1,1 -g  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_3.txt | tail -1  | awk '{ print $1  }' )
            
awk -v max=$max  '{  
if ( length(max) == 1 ) { dec=10};
if ( length(max) == 2 ) { dec=100};
if ( length(max) == 3 ) { dec=1000};
if ( length(max) == 4 ) { dec=10000};
if ( length(max) == 5 ) { dec=100000};
print ($2 * dec ) + $1 , NR-1
   }'  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_3.txt >  $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_4.txt 

# 0 0
# 20029780001 1
# 20132430001 2
# 20281820001 3
# 20674900002 4
# 20689740003 5

pkreclass -ot UInt32 -code $SCMH/CompUnit_basin_uniq/lbasin_basin_reclass_${ID}_4.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $SCMH/CompUnit_basin_uniq/basin_lbasin_sum_${ID}.tif -o $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif

gdalinfo -mm $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif | grep Computed | awk '{ gsub(/[=,]/," " , $0 ); print int($3), int($4)}'  > $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.mm

# usefull for the reclass all compuUnit globla uniq 
pkstat -hist -i  $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.tif | grep -v " 0"  > $SCMH/CompUnit_basin_uniq/basin_uniq_${ID}.hist

######## ident 80 e 108 have more ID
#### wc -l CompUnit_basin_uniq/basin_uniq_*.hist = 727206936 - 166 = 727 206 770   ### finalID from chanel_ident 727 206 791    chanel identifier 
fi

exit 
