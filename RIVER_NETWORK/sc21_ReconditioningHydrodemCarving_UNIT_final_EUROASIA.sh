#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1 -N 1  
#SBATCH -t 168:00:00
#SBATCH --mail-user=email

# sacct -j 623622   --format=jobid,MaxVMSize,start,end,CPUTImeRaw,NodeList,ReqCPUS,ReqMem,Elapsed,Timelimit 
# sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 

# best combination 200 log ; 120 depth ;  151 diamiter stdev ;  30798730 

# sbatch --export=N=200,DIM=140,UNIT=4000,GEO=GLOBE,RADIUS=151,TRH=8  --mem-per-cpu=20000  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 

# CENTER awk 'BEGIN{ print  int (( 40209  * 53760  / 1000000 * 31 ) + 500 )    }' = 67510 = 68000
# RIGHT  awk 'BEGIN{ print  int (( 11819  * 24171  / 1000000 * 31 ) + 500 )    }' = 9355 =   9400
# LEFT   awk 'BEGIN{ print  int (( 39435  * 54017  / 1000000 * 31 ) + 500 )    }' = 66534 = 67000
# 
# for ZONE in LEFT CENTER RIGHT ; do   RADIUS=151 ; N=200 ; DIM=120 ; if [ $ZONE = RIGHT ]  ; then  RAM=9400 ; else RAM=68000  ; fi  ;  sbatch --export=N=$N,DIM=$DIM,GEO=EUROASIA,ZONE=$ZONE,RADIUS=$RADIUS,TRH=8 -J sc21_ReconditioningHydrodemCarving_N${N}_DIM${DIM}_STDEV${RADIUS}_TRH${TRH}_final_$ZONE.sh -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc21_ReconditioningHydrodemCarving_final_$ZONE.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc21_ReconditioningHydrodemCarving_final_$ZONE.%J.err   --mem-per-cpu=$RAM  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc21_ReconditioningHydrodemCarving_UNIT_final_EUROASIA.sh ; done  

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

rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT/.gislock
source  /gpfs/home/fas/sbsc/ga254/scripts/general/enter_grass7.0.2-grace2.sh  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT 
rm -f /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/loc_river_fill_${GEO}/PERMANENT/.gislock

export N
export DIM
export ZONE
export GEO
export RADIUS

export DEM=be75_grd_LandEnlarge_${GEO}
export OCCURENCE=occurrence_250m_${GEO}
export STDEV=be75_grd_LandEnlarge_std${RADIUS}_norm_${GEO}
export RPROJ=/project/fas/sbsc/ga254/dataproces/RIVER_NETWORK
export RSCRA=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK

cp  $HOME/.grass7/grass$$     $HOME/.grass7/rc${ZONE}_${N}_${DIM}_STDEV${RADIUS}
export GISRC=$HOME/.grass7/rc${ZONE}_${N}_${DIM}_STDEV${RADIUS}

rm -fr  $RSCRA/grassdb/loc_river_fill_${GEO}/${ZONE}_${N}_${DIM}_STDEV${RADIUS}
g.mapset  -c  mapset=${ZONE}_${N}_${DIM}_STDEV${RADIUS}  location=loc_river_fill_${GEO}  dbase=$RSCRA/grassdb   --quiet --overwrite 

echo create mapset   ${ZONE}_${N}_${DIM}_STDEV${RADIUS}
cp $RSCRA/grassdb/loc_river_fill_${GEO}/PERMANENT/WIND $RSCRA/grassdb/loc_river_fill_${GEO}/${ZONE}_${N}_${DIM}_STDEV${RADIUS}/WIND

g.mapsets   mapset=fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}   operation=add

rm -f  $RSCRA/grassdb/loc_river_fill_${GEO}/${ZONE}_${N}_${DIM}_STDEV${RADIUS}/.gislock

g.gisenv 

g.region raster=UNIT497_338_3562_333 --o 
r.mask -r  --quiet
r.mask   raster=UNIT497_338_3562_333 --o

if [ $ZONE = LEFT ]   ; then  g.region  w=-59.5354166666667      e=53 res=0:00:07.5  ; fi 
if [ $ZONE = CENTER ] ; then  g.region  w=-20  e=92 res=0:00:07.5                    ; fi 
if [ $ZONE = RIGHT ]  ; then  g.region  w=90 e=140.395833333333       res=0:00:07.5  ; fi 

g.region -p 

echo  carving 
r.mapcalc "${DEM}_carv  = ${DEM}@PERMANENT  -  fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS}@fin_${OCCURENCE}_log${N}_DIM${DIM}_STDEV${RADIUS} "  --overwrite

g.region zoom=UNIT497_338_3562_333 

echo  procedure to smoth the border 

NEIG=3

echo start r.neighbors 
r.neighbors -c  input=${DEM}_carv  output=${DEM}_carvFilter   method=average  size=$NEIG  selection=${OCCURENCE}_G_null_1@PERMANENT  --overwrite 

g.region zoom=${DEM}_carv

echo start r.hydridem                                                                                               # memory=65000 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.hydrodem input=${DEM}_carvFilter output=${DEM}_cond_${ZONE} memory=65000 --overwrite 

echo start the output r.watershed                                                                                                                    # memory=65000 
r.watershed --quiet  -a  -b  elevation=${DEM}_cond_${ZONE}   basin=basin_${ZONE} stream=stream_${ZONE}   drainage=drainage_${ZONE} accumulation=accumulation_${ZONE}   memory=65000  threshold=$TRH  --overwrite

echo lbasin 
/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.basins -l  stream_rast=stream_${ZONE}  direction=drainage_${ZONE} basins=lbasin_${ZONE} memory=65000 --o

# region at this point n=72.9083333333333 s=48.2875 w=90 e=140.39375

# cat the border 
if [ $ZONE = RIGHT ] ; then 
    w=$(g.region -m  | grep w= | awk -F "=" '{ print $2   }' )
    e=$(g.region -m  | grep w= | awk -F "=" '{ printf ("%.14f\n" , $2 +  0.002083333333333 ) }' )

    g.region e=$e w=$w  res=0:00:07.5 
    r.mapcalc " lbasin_${ZONE}_estripe    = lbasin_${ZONE} " --o
    g.region raster=lbasin_${ZONE} # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_${ZONE}_estripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) <( r.report -n -h units=c map=lbasin_${ZONE}         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } '  | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${ZONE}_reclass.txt 
    r.reclass input=lbasin_${ZONE}  output=lbasin_${ZONE}_rec   rules=/dev/shm/lbasin_${ZONE}_reclass.txt   --o
fi 

if [ $ZONE = LEFT ] ; then 
    e=$(g.region -m  | grep e= | awk -F "=" '{ print $2   }' )
    w=$(g.region -m  | grep e= | awk -F "=" '{ printf ("%.14f\n" , $2 -  0.002083333333333 ) }' )

    g.region e=$e w=$w  res=0:00:07.5 
    r.mapcalc " lbasin_${ZONE}_wstripe    = lbasin_${ZONE} " --o
    g.region raster=lbasin_${ZONE} # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_${ZONE}_wstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) <( r.report -n -h units=c map=lbasin_${ZONE}         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } '  | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${ZONE}_reclass.txt 
    r.reclass input=lbasin_${ZONE}  output=lbasin_${ZONE}_rec   rules=/dev/shm/lbasin_${ZONE}_reclass.txt   --o
fi 

if [ $ZONE = CENTER ] ; then 
    echo left stripe 
    e=$(g.region -m  | grep e= | awk -F "=" '{ print $2   }' )
    w=$(g.region -m  | grep e= | awk -F "=" '{ printf ("%.14f\n" , $2 -  0.002083333333333 ) }' )

    g.region e=$e w=$w  res=0:00:07.5 
    r.mapcalc " lbasin_${ZONE}_wstripe    = lbasin_${ZONE} " --o

    w=$(g.region -m  | grep w= | awk -F "=" '{ print $2   }' )
    e=$(g.region -m  | grep w= | awk -F "=" '{ printf ("%.14f\n" , $2 +  0.002083333333333 ) }' )

    g.region e=$e w=$w  res=0:00:07.5
    r.mapcalc " lbasin_${ZONE}_estripe    = lbasin_${ZONE} " --o

    g.region raster=lbasin_${ZONE} # report on the basis of the region setting 
    cat <(r.report -n -h units=c map=lbasin_${ZONE}_estripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
        <(r.report -n -h units=c map=lbasin_${ZONE}_wstripe | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } ' | awk  '$1 ~ /^[0-9]+$/ { print $1 } '   ) \
       <( r.report -n -h units=c map=lbasin_${ZONE}         | awk  '{ gsub ("\\|"," " ) ; { print $1 }   } '  | awk  '$1 ~ /^[0-9]+$/ { print $1 } ' ) \
      | sort  | uniq -c | awk '{ if($1==1) {print $2"="$2 } else { print $2"=NULL"}  }' >  /dev/shm/lbasin_${ZONE}_reclass.txt 
    r.reclass input=lbasin_${ZONE}  output=lbasin_${ZONE}_rec   rules=/dev/shm/lbasin_${ZONE}_reclass.txt   --o
fi 
rm -f /dev/shm/lbasin_${ZONE}_reclass.txt 
g.region raster=lbasin_${ZONE}   res=0:00:07.5  
r.mapcalc  " lbasin_${ZONE}_clean = lbasin_${ZONE}_rec  " --o
g.remove -f  type=raster name=lbasin_${ZONE}_rec,lbasin_${ZONE}_estripe 

r.mask raster=lbasin_${ZONE}_clean --o

echo save to tif 
r.colors -r stream_${ZONE} 
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9"  type=UInt32 format=GTiff nodata=0   input=stream_${ZONE} output=$RPROJ/output/stream_unit/idstream${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
rm -f $RPROJ/output/stream_unit/idstream${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif.aux.xml 

pkcreatect -min 0 -max 1 > /dev/shm/color$ZONE.txt
pkgetmask -ct /dev/shm/color$ZONE.txt   -co COMPRESS=DEFLATE -co ZLEVEL=9 -ot Byte -min 0.5 -max 9999999999999 -data 1 -i $RPROJ/output/stream_unit/idstream${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif  -o  $RPROJ/output/stream_unit/bistream${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
gdal_edit.py   -a_nodata 0  $RPROJ/output/stream_unit/bistream${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
rm -f  /dev/shm/color$ZONE.txt 

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=lbasin_${ZONE}  output=$RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
rm -f $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif.aux.xml

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=lbasin_${ZONE}_clean  output=$RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif
rm -f $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif.aux.xml

# bash /gpfs/home/fas/sbsc/ga254/scripts/general/createct_random.sh $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}_color.txt
# gdaldem color-relief -co COMPRESS=DEFLATE -co ZLEVEL=9 -alpha  $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}_color.txt  $RPROJ/output/lbasin_unit/lbasin${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}_ct.tif

r.colors -r basin_${ZONE}
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0 input=basin_${ZONE}  output=$RPROJ/output/basin_unit/basin${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 

r.colors -r  ${DEM}_cond_${ZONE}
r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16 input=${DEM}_cond_${ZONE}  output=$RPROJ/dem_unit_cond/${DEM}_cond_${ZONE}_log${N}_DIM${DIM}_w$NEIG.tif 
r.colors -r  ${OCCURENCE} 
r.out.gdal --overwrite -f -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" format=GTiff nodata=-9999 type=Int16 input=${OCCURENCE} output=$RPROJ/GSW_unit/${OCCURENCE}_${ZONE}.tif 

echo r.stream.order 

/gpfs/home/fas/sbsc/ga254/.grass7/addons/bin/r.stream.order --quiet stream_rast=stream_${ZONE} direction=drainage_${ZONE} accumulation=accumulation_${ZONE}  elevation=${DEM}_cond_${ZONE} strahler=stream_strahler_${ZONE} horton=stream_horton_${ZONE} shreve=stream_shreve_${ZONE} hack=stream_hack_${ZONE} topo=stream_topo_${ZONE} memory=65000  --overwrite 

r.colors -r stream_trahler_${ZONE}
r.colors -r stream_horton_${ZONE}
r.colors -r stream_shreve_${ZONE}
r.colors -r stream_hack_${ZONE}
r.colors -r stream_topo_${ZONE}

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_strahler_${ZONE} output=$RPROJ/output/stream_order_unit/strahler${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_horton_${ZONE} output=$RPROJ/output/stream_order_unit/horton${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_shreve_${ZONE} output=$RPROJ/output/stream_order_unit/shreve${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif

r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_hack_${ZONE} output=$RPROJ/output/stream_order_unit/hack${ZONE}_$log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 
r.out.gdal --overwrite -c createopt="COMPRESS=DEFLATE,ZLEVEL=9" type=UInt32 format=GTiff nodata=0   input=stream_topo_${ZONE} output=$RPROJ/output/stream_order_unit/topo${ZONE}_log${N}_DIM${DIM}_STDEV${RADIUS}_w${NEIG}_TRH${TRH}.tif 



sstat  -j   $SLURM_JOB_ID.batch   --format=JobID,MaxVMSize 
exit 

