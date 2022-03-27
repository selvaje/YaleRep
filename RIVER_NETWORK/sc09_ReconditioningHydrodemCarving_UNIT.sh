#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving_UNIT.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving_UNIT.%J.err
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

# sbatch --export=N=200,DIM=140,UNIT=4000,GEO=GLOBE,RADIUS=71,TRH=8  --mem-per-cpu=20000  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 
# sbatch --export=N=200,DIM=20,UNIT=4000,GEO=GLOBE,RADIUS=71,TRH=8   --mem-per-cpu=20000  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 
# sbatch --export=N=200,DIM=20,UNIT=3753,GEO=GLOBE,RADIUS=71,TRH=8   --mem-per-cpu=43000   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 

# prepare the RAM needed  # aggiunta a mano la 3 colonna con il tempo
# for UNIT in  1 2 3 4 5 6 7 8 9 10 11 12 13 14 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810  ; do  gdalinfo /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/unit/UNIT${UNIT}msk.tif | grep "Size is" | awk -v  UNIT=$UNIT  '{ gsub(",", " " ) ; print UNIT ,    int (( $3 * $4 / 1000000 * 31 ) + 500 ) }'  ; done | sort -gr -k 2,2  | awk ' { print $1"_"$2  } '   >  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt

# calculate minute for each unit 
# for file in  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.*.out ; do  echo   $( grep  -A 1  LSBATCH         $file | awk '{if (NR==2)  print $(NF-1) }' )  $(grep  "CPU time" $file  | awk '{ print $4  }'  )   ; done  | sort -k 1  -g   | uniq   > /tmp/min_unit.txt
# for UNIT in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810 ; do echo $UNIT $( grep ^"${UNIT} " /tmp/min_unit.txt | head -1 | awk '{ print $2 }'  )  $( grep ^"${UNIT} "  /tmp/min_unit.txt |tail  -1 | awk '{ print $2 }'  ) ; done

# for lunch a sinble unit
# fare correre e cancellare 

# grep "User defined signal"  /gpfs/scratch60/fas/sbsc/ga254/std*/sc06_ReconditioningHydrodemCarving.sh.*.err 
# bsub   -W 24:00 -M 30000   -R "rusage[mem=30000]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 100 40  4001 GLOBE

# for TRH in 1 2 3 4 5 6 7 8 9 10 ;do bsub   -W 24:00  -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 200 110  3753  GLOBE 81 $TRH ; done 


#  cat  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt   | xargs -n 2 -P 1 bash -c $'  for LINE in $( cat   /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt    ) ; do    UNIT=$( echo $LINE | tr "_" " "  | awk \'{  print $1  }\' ) ; RAM=$( echo $LINE | tr "_" " "  | awk \'{  print $2  }\' ) ; TIME=$( echo $LINE | tr "_" " "  | awk \'{  print $3  }\' )  ;  bsub  -W 24:00 -M ${RAM}  -R "rusage[mem=${RAM}]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $1 $2  $UNIT GLOBE   ; done ' _ 

# search for computation that reach the time limit
# for file in   /gpfs/scratch60/fas/sbsc/ga254/stdout/*   ; do  grep TERM_RUNLIMIT -B 3 $file | head -1 | awk '{  print $3, $4 , $5  }'  ; done  > /tmp/missing_LOG_DIM_UNIT.txt
# cat /tmp/missing.txt | xargs -n 3 -P 1 bash -c  $'  awk -v LOG=$1 -v DIM=$2  -v UNIT=$3 \'{ gsub("_"," ") ; if ($1==UNIT) { print LOG, DIM , UNIT ,  $2 , $3 } }\'  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt    ' _  >  /tmp/missing_LOG_DIM_UNIT_RAM_TIME.txt
# cat   /tmp/missing_LOG_DIM_UNIT_RAM_TIME.txt  | xargs -n 5 -P 1 bash -c $'  bsub  -W ${1}:00 -M ${4}  -R "rusage[mem=${4}]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $1 $2  $3 GLOBE   ; done ' _ 

#  cat /tmp/missing.txt   | xargs -n 3 -P 1 bash -c $'   cat  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt  ) ; do    UNIT=$( echo $LINE | tr "_" " "  | awk \'{  print $1  }\' ) ; RAM=$( echo $LINE | tr "_" " "  | awk \'{  print $2  }\' ) ; TIME=$( echo $LINE | tr "_" " "  | awk \'{  print $3  }\' )  ;  bsub  -W ${TIME}:00 -M ${RAM}  -R "rusage[mem=${RAM}]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $1 $2  $UNIT GLOBE   ; done ' _ 

#  cat  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt   | xargs -n 2 -P 1 bash -c $'   for UNIT in 497_338_3562_333   ; do bsub  -W 24:00 -M 70000  -R "rusage[mem=70000]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $1 $2  $UNIT EUROASIA   ; done ' _ 


# calculate the ram 

# 1145 154 2597 3005 3317 3629 3753 4000 4001 573 810 497_338_3562_333 
# new one 
# 497 5656337      ?
# 346 6254072      
# 1145 7642013     japan 
# 810 7949852      UK  
# 3317 12175858    MADAGASCAR  
# 2597 14470128    borneo 
# 3005 15937346    guinea    
# 154 24790283     canada island
# 573 158907908    greenland 
# 3629 160965130   Australia 
# 4000 360948377  South America    * 
# 4001 578979392  Africa 
# 3753 659333926   north Amarica   * 
# 3562 1519030245  EUROASIA 
# 3767 8275779607  sea 

echo UNIT ${UNIT} TYPE ${N} DIMENSION ${DIM}  STDEV ${RADIUS}

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb 
export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_GLOBE/PERMANENT/.gislock

export N
export DIM
export UNIT
export GEO
export RADIUS

export DEM=be75_grd_LandEnlarge_${GEO}
export OCCURENCE=occurrence_250m_${GEO}
export STDEV=be75_grd_LandEnlarge_std${RADIUS}_norm_${GEO}

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc${UNIT}_${N}_${DIM}_STDEV${RADIUS}
export GISRC=$HOME/.grass7/rc${UNIT}_${N}_${DIM}_STDEV${RADIUS}


rm -fr  $DIR/grassdb/loc_river_fill_GLOBE/${UNIT}_${N}_${DIM}_STDEV${RADIUS}
g.mapset  -c  mapset=${UNIT}_${N}_${DIM}_STDEV${RADIUS}  location=loc_river_fill_GLOBE  dbase=$DIR/grassdb   --quiet --overwrite 

echo create mapset   ${UNIT}_${N}_${DIM}_STDEV${RADIUS}
cp $DIR/grassdb/loc_river_fill_GLOBE/PERMANENT/WIND $DIR/grassdb/loc_river_fill_GLOBE/${UNIT}_${N}_${DIM}_STDEV${RADIUS}/WIND

g.mapsets   mapset=${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}   operation=add

rm -f  $DIR/grassdb/loc_river_fill_GLOBE/${UNIT}_${N}_${DIM}_STDEV${RADIUS}/.gislock

g.gisenv 

g.region   raster=UNIT${UNIT}   --o 
# g.region   n=41  s=35  w=-90  e=-77  --o   #    for stady area in USA
r.mask -r  --quiet
r.mask     raster=UNIT${UNIT}   --o

echo  carving 
r.mapcalc "${DEM}_carv  = ${DEM}@PERMANENT  -  ${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}@${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS} "  --overwrite

echo  procedure to smoth the border 

NEIG=3

echo start r.neighbors 
r.neighbors -c  input=${DEM}_carv  output=${DEM}_carvFilter   method=average  size=$NEIG  selection=${OCCURENCE}_G_null_1@PERMANENT  --overwrite 

echo start r.hydridem                                                                                               # memory=65000 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.hydrodem    input=${DEM}_carvFilter   output=${DEM}_cond   memory=65000  --overwrite 

echo start the output 
# r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16  input=${DEM}_cond    output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/dem_unit/${DEM}_cond${UNIT}_log${N}_DIM${DIM}_w$NEIG.tif 
# r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16  input=${OCCURENCE}                   output=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/GSW_unit/${OCCURENCE}_$UNIT.tif 


if  [  ${GEO} = "GLOBE"   ] ; then 
                                                                                                                               # memory=65000 
r.watershed -a  -b  elevation=${DEM}_cond   basin=basin  stream=stream   drainage=drainage   accumulation=accumulation   memory=65000  threshold=$TRH  --overwrite
r.info stream 
r.colors -r stream
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"       type=UInt32 format=GTiff nodata=0   input=stream  output=/dev/shm/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 0.5 -max 9999999999 -data 1 -i  /dev/shm/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif  -o  $DIR/output/stream_unit_small/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
gdal_edit.py   -a_nodata 0  $DIR/output/stream_unit_small/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
rm -f /dev/shm/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

# r.stream.order  stream_rast=stream  direction=drainage  stream_vect=stream_vect   accumulation=accumulation  elevation=${DEM}_cond
# v.in.ogr  nput=/project/fas/sbsc/ga254/dataproces/NHDplus/shp/NHDPlusV21_MS_05_NHDSnapshot_06/NHDFlowline.shp  output=NHDFlowline  --o 
# v.to.rast input=NHDFlowline output=stream_NHD value=1  type=line use=val  --o 
# r.stream.order  stream_rast=stream_NHD   direction=drainage  stream_vect=stream_vect_NHD    accumulation=accumulation  elevation=${DEM}_cond  --o 
# r.mapcalc " occurrence_250m_GLOBE_1_null   =  if( isnull(occurrence_250m_GLOBE_null_1) , 1 , null() ) "  --o
# r.grow.distance input=occurrence_250m_GLOBE_1_null distance=occurence_distance --overwrite
# r.neighbors -c  input=occurence_distance  output=neigh_max  selection=occurrence_250m_GLOBE_null_1 method=maximum --o
#   r.mapcalc " occurrence_stream    =  if(   neigh_max <  0.010416667 , 1 , null()) " --o 

r.mask -r  --quiet
r.mask   raster=stream  --o
r.mapcalc  " ${OCCURENCE}_STRbin =   ${OCCURENCE}_null_1   "   --overwrite 

r.report -n -h  units=c map=${OCCURENCE}_STRbin | awk -v UNIT=$UNIT -v N=$N  -v DIM=$DIM -v RADIUS=$RADIUS  -F "|"  '{if(NR==5) print $(NF-1), UNIT ,DIM, N , RADIUS }' > $DIR/output/txt/stream${UNIT}_log${N}_DIM${DIM}_STDEV${RADIUS}_TRH${TRH}.txt 
r.mask -r  --quiet
r.mask  raster=UNIT${UNIT}   --o

# r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=${OCCURENCE}_STRbin  output=$DIR/output/stream_unit/streamBIN${UNIT}_log${N}_DIM${DIM}.tif 

rm -fr  $DIR/grassdb/loc_river_fill_GLOBE/${UNIT}_${N}_${DIM}_STDEV${RADIUS}

fi 

sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 
exit 





if [ ${GEO}  = "EUROASIA" ] ; then  

for ZONE in LEFT CENTER RIGHT ; do 

# for ZONE in RIGHT ; do 

if [ $ZONE  = LEFT ]   ; then  g.region  e=53        res=0:00:07.5  ; fi 
if [ $ZONE = CENTER ]  ; then  g.region  w=-20  e=92 res=0:00:07.5  ; fi 
if [ $ZONE = RIGHT ]   ; then  g.region  w=90        res=0:00:07.5  ; fi 

r.watershed  -b  elevation=${DEM}_cond   basin=basin  stream=stream   drainage=drainage   accumulation=accumulation   memory=65000  threshold=$TRH  --overwrite
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=UInt32 format=GTiff nodata=0   input=stream  output=/dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif 
rm -f /dev/shm/stream${UNIT}_log${N}_DIM${DIM}.tif

pkgetmask -co COMPRESS=DEFLATE -co ZLEVEL=9 -ct $DIR/grassdb/color0_1.txt -ot Byte -min 0.5 -max 9999999999 -data 1 -i  /dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif  -o  $DIR/output/stream_unit/stream${UNIT}_${ZONE}log${N}_DIM${DIM}.tif
rm -f   /dev/shm/stream${UNIT}_DIM${DIM}_log${N}.tif 

r.mask  raster=stream  --o
r.mapcalc  " ${OCCURENCE}_STRbin =   ${OCCURENCE}_null_1   "   --overwrite 

r.report -n -h  units=c map=${OCCURENCE}_STRbin | awk -v UNIT=$UNIT -v N=$N  -v DIM=$DIM  -F "|"  '{if(NR==5) print $(NF-1), UNIT ,DIM, N }' > $DIR/output/txt/stream${UNIT}_${ZONE}_log${N}_DIM${DIM}.txt 

r.mask  raster=UNIT${UNIT}   --o

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0  input=${OCCURENCE}_STRbin  output=$DIR/output/stream_unit/streamBIN${UNIT}_${ZONE}_log${N}_DIM${DIM}.tif 

done 
rm -fr  $DIR/grassdb/loc_river_fill_GLOBE/${UNIT}_${N}_${DIM} 
fi 
