
# perform a merging action for the /mnt/data2/dem_variables/GMTED2010/altitude/class_mi and /mnt/data2/dem_variables/GMTED2010/altitude/class_mx
# create in avery clever way missing tiles. The missing tiles were appear if all the pixel where above or below a treshold, therfore all 100% or 0%



# run the script in the  @bulldogj 

# rm /lustre0/scratch/ga254/stderr/* ; rm /lustre0/scratch/ga254/stdout/* ; 

# create tif with value 0 or 100 used to refeel the area

# to que after the completition of sc2 

# n=`qstat | grep percent_bj | wc -l` ; for time in `seq 1 100` ; do if [ $n  -eq 0  ] ; then  echo run the script ;   ; exit   ; else  sleep 60   ;   echo sleeping   ;  fi ; done

# for dir in `seq -500 100 8600` ; do  qsub -v dir=$dir,mm=mi   /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc6a_class_treshold_density_merge_bj.sh ; done # 400 8600 range confirrmed  (-500 tutti i valore == 100)
# for dir in `seq -500 100 8700` ; do  qsub -v dir=$dir,mm=md   /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc6a_class_treshold_density_merge_bj.sh ; done # -500 8700 range confirrmed 
# for dir in `seq -500 100 8700` ; do  qsub -v dir=$dir,mm=mx   /lustre0/scratch/ga254/scripts_bj/environmental-layers/terrain/procedures/dem_variables/gmted2010_res_x10/sc6a_class_treshold_density_merge_bj.sh ; done # -500 8700 range confirrmed


#PBS -S /bin/bash 
#PBS -q fas_normal
#PBS -l mem=4gb
#PBS -l walltime=2:00:00
#PBS -l nodes=1:ppn=4
#PBS -V
#PBS -o /lustre0/scratch/ga254/stdout/merge_tr 
#PBS -e /lustre0/scratch/ga254/stderr/merge_tr


# load moduels 

module load Tools/Python/2.7.3
module load Libraries/GDAL/1.10.0
module load Tools/PKTOOLS/2.4.2
module load Libraries/OSGEO/1.10.0

#  DIR=$1
#  mm=$2

DIR=${dir}
mm=${mm}
INDIR=/home2/ga254/scratch/dem_bj/GMTED2010/altitude/class_${mm}/class${DIR}          # this has pixel value = 0.002083333333333
INDIR_C=/home2/ga254/scratch/dem_bj/GMTED2010/altitude/class_${mm}/class              # this has pixel value = 0.002083333333333
INDIR_Cm100=/home2/ga254/scratch/dem_bj/GMTED2010/altitude/class_${mm}/class-100      # this has pixel value = 0.008333333333333 this is the only class with all (50) tiles
OUTDIR=/home2/ga254/scratch/dem_bj/GMTED2010/altitude/percent_class_${mm}
TMP=/tmp


rm  -f $OUTDIR/file_processed_sc3.txt  # the file has ben processed by the script sc1_dem_treshold_percent.sh

for file  in `ls $INDIR_C/*.tif`  ; do 
    tile=`basename $file _class.tif`

    if [ -f $INDIR/$tile"_C"$DIR"Perc.tif" ] ; then 
	echo the file  $INDIR/$tile"_C"$DIR"Perc.tif"   exist and will be merged as it is
	echo $tile"_C"$DIR"Perc.tif" >>  $OUTDIR/file_processed_sc3.txt # usefull to list file processed by script sc1, in case of delation use this.
    else

gdalinfo -mm    $INDIR_C/$tile"_class.tif" | grep Computed | awk '{ gsub ("[=,]"," "); print int($(NF-1)), int($(NF))}' > $TMP/${tile}_class${DIR}_min_max_${mm}.txt 

min=`awk '{ print $1}'  $TMP/${tile}_class${DIR}_min_max_${mm}.txt `  
max=`awk '{ print $2}'  $TMP/${tile}_class${DIR}_min_max_${mm}.txt `
rm -f  $TMP/${tile}_class${DIR}_min_max_${mm}.txt 

echo $min and $max compare to $DIR

if [ $max -lt $DIR ]  ;  then 
      echo copy the $INDIR/$tile"_C"$DIR"Perc.tif"  with 0 value
      echo $INDIR/$tile"_C"$DIR"Perc.tif" with 0 value >>  $INDIR/refill_file_list.txt
      # pkgetmask -min 10000 -max 10001  -t 0 -ot Byte -i  $INDIR_Cm100/$tile"_C-100Perc.tif" -co COMPRESS=LZW  -o $INDIR/$tile"_C"$DIR"Perc.tif" 
      # change the previus line with this to avoid constant calculation 
      cp  /home2/ga254/scratch/dem_bj/GMTED2010/altitude/value0/$tile".tif"     $INDIR/$tile"_C"$DIR"Perc.tif"  
      
fi 

if [ $min -gt $DIR ] ; then 
      echo copy the $INDIR/$tile"_C"$DIR"Perc.tif"  with 100 value 
      echo $INDIR/$tile"_C"$DIR"Perc.tif" with 100 value >>  $INDIR/refill_file_list.txt
      # pkgetmask -min 10000 -max 10001  -t 0 -f 100  -ot Byte  -co COMPRESS=LZW  -i $INDIR_Cm100/$tile"_C-100Perc.tif"  -o $INDIR/$tile"_C"$DIR"Perc.tif" 
      cp  /home2/ga254/scratch/dem_bj/GMTED2010/altitude/value100/$tile".tif"    $INDIR/$tile"_C"$DIR"Perc.tif"  
      
fi 

fi  

done

echo STARTING THE MERGING ACTION 
rm -f $OUTDIR/perc_$DIR.tif
gdal_merge.py   -co COMPRESS=LZW    -ot Byte -o $OUTDIR/perc_$DIR.tif  $INDIR/*.tif 

if [ -f $OUTDIR/color-bw.txt ] ; then 
    echo the $OUTDIR/color-bw.txt exist ;
else 
    pkcreatect -g -min 0 -max 100 | sort -k 1,1 -rg | awk '{  print NR-1 , $2 ,$3 ,$4 ,$5 }'  >  $OUTDIR/color-bw.txt
fi 

pkcreatect -ct  $OUTDIR/color-bw.txt -co COMPRESS=LZW -co INTERLEAVE=BAND  -d "Percent of elevation values >= ${DIR}m" -i  $OUTDIR/perc_$DIR.tif -o  $OUTDIR/threshold_${DIR}_GMTED2010_${mm}.tif   

rm $OUTDIR/perc_$DIR.tif
