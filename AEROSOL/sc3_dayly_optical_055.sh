# dayli estimation trend 

# copy the input tif from /lustre0/scratch/ga254/dem_bj/AEROSOL/tif_mean 
# cd /lustre0/scratch/ga254/dem_bj/AEROSOL/tif_mean

# ls  day*_res_mean.tif | xargs -n 1 -P 12 bash -c $'
# gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -a_nodata -9999 -ot Float32  $1  /lustre0/scratch/ga254/dem_bj/AEROSOL/day_estimation/$1
# '
# cp /lustre0/scratch/ga254/dem_bj/AEROSOL/day_estimation/day1_res_mean.tif  /lustre0/scratch/ga254/dem_bj/AEROSOL/day_estimation/day365_res_mean.tif

# for day in 1 32 61 91 122 153 183 214 245 275 306 336 ; do qsub -v day=$day  /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/AEROSOL/sc3_dayly_optical_055.sh  ; done 

# bash /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/AEROSOL/sc3_dayly_optical.sh 32

#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=1gb
#PBS -l walltime=3:00:00 
#PBS -l nodes=1:ppn=1
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout 
#PBS -e /lustre0/scratch/ga254/stderr

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Libraries/OSGEO/1.10.0

export day=$day
# export day=$1

export INDIR=/lustre0/scratch/ga254/dem_bj/AEROSOL/tif_mean
export OUTDIR=/lustre0/scratch/ga254/dem_bj/AEROSOL/day_estimation 



if [ $day -eq 1  ] ; then  export dayend=32  ; fi  
if [ $day -eq 32 ] ; then  export dayend=61  ; fi   
if [ $day -eq 61 ] ; then  export dayend=91  ; fi   
if [ $day -eq 91 ] ; then  export dayend=122 ; fi   
if [ $day -eq 122 ] ; then  export dayend=153 ;fi   
if [ $day -eq 153 ] ; then  export dayend=183 ;fi   
if [ $day -eq 183 ] ; then  export dayend=214 ;fi   
if [ $day -eq 214 ] ; then  export dayend=245 ;fi   
if [ $day -eq 245 ] ; then  export dayend=275 ;fi   
if [ $day -eq 275 ] ; then  export dayend=306 ;fi   
if [ $day -eq 306 ] ; then  export dayend=336 ;fi   
if [ $day -eq 336 ] ; then  export dayend=365 ;fi 


export nseq=$(expr $dayend - $day - 1 )
export fact=$(awk -v nseq=$nseq  'BEGIN { print 1/(nseq + 1) }' )

echo  start to process $1 

for n in `seq 1 $nseq` ; do 
    
    echo processing day $(expr $day + $n)
    rm -f $OUTDIR/tmpday$(expr $day + $n)_res_mean.tif
    gdal_calc.py  --NoDataValue -9999   --type=Float32  -A $OUTDIR/day${day}_res_mean.tif  -B $OUTDIR/day${dayend}_res_mean.tif --calc="( A + ((B-A) * $fact * $n ) )"  --outfile=$OUTDIR/tmpday$(expr $day + $n)_res_mean.tif --co=COMPRESS=LZW --co=ZLEVEL=9   --type Float32 --overwrite 
    gdal_translate -co COMPRESS=LZW -co ZLEVEL=9 -ot Float32  $OUTDIR/tmpday$(expr $day + $n)_res_mean.tif  $OUTDIR/day$(expr $day + $n)_res_mean.tif
    rm -f $OUTDIR/tmpday$(expr $day + $n)_res_mean.tif
done 

exit 

# quality controll # funziona tutto 

for day in `seq 1 365` ; do  echo $day `gdallocationinfo  -valonly day${day}_res_mean.tif 200 100   ` ; done 


