

export DIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/output/txt/

# calibration equations 

for UNIT in 3753 4000  ; do 
    echo $UNIT $(ls $DIR/stream${UNIT}_log*_DIM*.txt  | wc -l  )
done 

cat $DIR/stream3753_log*_DIM*.txt | awk '{ print  $3"_"$4 , $1   }'   | sort -k 1,1 > $DIR/calibration_equations/UNIT3753.txt
cat $DIR/stream4000_log*_DIM*.txt | awk '{ print  $3"_"$4 , $1   }'   | sort -k 1,1 > $DIR/calibration_equations/UNIT4000.txt

for UNIT in 4000   ; do 
    ITER=$(  ls stream${UNIT}_log*_DIM*.txt  | wc -l    )
    if [  $ITER -eq 195   ] ; then 
	cat $DIR/stream${UNIT}_log*_DIM*.txt | awk '{ print  $3"_"$4 , $1   }'   | sort -k 1,1  > $DIR/calibration_equations/UNIT$UNIT.txt
	join -1 1 -2 1  $DIR/calibration_equations/UNIT3753.txt  $DIR/calibration_equations/UNIT$UNIT.txt  | awk '{ print  $1 , $2+ $3  }'   >  $DIR/calibration_equations/UNITjoin$UNIT.txt
	mv  $DIR/calibration_equations/UNITjoin$UNIT.txt  $DIR/calibration_equations/UNIT3753.txt 
    fi 
done 

sort -g -k 2,2  $DIR/calibration_equations/UNIT3753.txt  >    $DIR/calibration_equations/CALIBRATION.txt 

cat $DIR/stream3753_log*_DIM*.txt | awk '{ print  $3"_"$4 , $1   }'   | sort -k 1,1 > $DIR/calibration_equations/UNIT3753.txt
cat $DIR/stream4000_log*_DIM*.txt | awk '{ print  $3"_"$4 , $1   }'   | sort -k 1,1 > $DIR/calibration_equations/UNIT4000.txt
   

for VAR in _001 _005 _010 _100 _200 _300 _400 _500 _600 _700 _800 _900 _950; do 
grep $VAR   $DIR/calibration_equations/UNIT3753.txt | awk -v VAR=$VAR '{ gsub( VAR , "")  ;  print     }'  | sort -k 2,2 -g >  $DIR/calibration_equations/UNIT3753$VAR.txt
done 

for VAR in _001 _005 _010 _100 _200 _300 _400 _500 _600 _700 _800 _900 _950; do 
grep $VAR   $DIR/calibration_equations/UNIT4000.txt | awk -v VAR=$VAR '{ gsub( VAR , "")  ;  print     }'  | sort -k 2,2 -g >  $DIR/calibration_equations/UNIT4000$VAR.txt
done 

for VAR in  _001 _005 _010 _100 _200 _300 _400 _500 _600 _700 _800 _900 _950 ; do 
grep $VAR   $DIR/calibration_equations/CALIBRATION.txt  | awk -v VAR=$VAR '{ gsub( VAR , "")  ;  print     }'  | sort -k 2,2 -g >  $DIR/calibration_equations/CALIBRATION$VAR.txt
done 
            
gnuplot -persist -e " set yrange [3200000:6000000] ; plot  'UNIT4000_001.txt' ,   'UNIT4000_010.txt' ,  'UNIT4000_100.txt' ,  'UNIT4000_200.txt' ,  'UNIT4000_300.txt' ,  'UNIT4000_400.txt' ,  'UNIT4000_500.txt' ,  'UNIT4000_600.txt' ,  'UNIT4000_700.txt' ,  'UNIT4000_800.txt' ,  'UNIT4000_900.txt' ,  'UNIT4000_950.txt' "
 
gnuplot -persist -e " set yrange [16000000:30000000]   ; plot 'UNIT3753_001.txt' ,   'UNIT3753_010.txt' ,  'UNIT3753_100.txt' ,  'UNIT3753_200.txt' ,  'UNIT3753_300.txt' ,  'UNIT3753_400.txt' ,  'UNIT3753_500.txt' ,  'UNIT3753_600.txt' ,  'UNIT3753_700.txt' ,  'UNIT3753_800.txt' ,  'UNIT3753_900.txt' ,  'UNIT3753_950.txt' "

gnuplot -persist -e " set yrange [20000000:40000000] ; plot 'CALIBRATION_001.txt' ,   'CALIBRATION_010.txt' ,  'CALIBRATION_100.txt' ,  'CALIBRATION_200.txt' ,  'CALIBRATION_300.txt' ,  'CALIBRATION_400.txt' ,  'CALIBRATION_500.txt' ,  'CALIBRATION_600.txt' ,  'CALIBRATION_700.txt' ,  'CALIBRATION_800.txt' ,  'CALIBRATION_900.txt' ,  'CALIBRATION_950.txt' " 


# calibration stdev 


for UNIT in 3753 4000  ; do 
    echo $UNIT $(ls $DIR/stream${UNIT}_log*_DIM*.txt  | wc -l  )
done 

cat $DIR/stream3753_log*_DIM*.txt | awk '{ print  $3"_"$5 , $1   }'   | sort -k 1,1 > $DIR/calibration_stdev/UNIT3753.txt
cat $DIR/stream4000_log*_DIM*.txt | awk '{ print  $3"_"$5 , $1   }'   | sort -k 1,1 > $DIR/calibration_stdev/UNIT4000.txt

join -1 1 -2 1  $DIR/calibration_stdev/UNIT3753.txt  $DIR/calibration_stdev/UNIT4000.txt  | awk '{ gsub ("_"," " ) ; print  $1 , $2 , $3+ $4  }'  |sort -g -k 3,3   >  $DIR/calibration_stdev/CALIBRATION.txt

cat $DIR/stream3753_log*_DIM*.txt | awk '{ print  $3"_"$5 , $1   }'   | sort -k 2,2 -g  > $DIR/calibration_stdev/UNIT3753.txt
cat $DIR/stream4000_log*_DIM*.txt | awk '{ print  $3"_"$5 , $1   }'   | sort -k 2,2 -g > $DIR/calibration_stdev/UNIT4000.txt


for VAR in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161  ; do 
awk -v VAR=$VAR '{   gsub( "_" , " ") ;  if(VAR==$2)   print $1 , $3      }'   $DIR/calibration_stdev/UNIT3753.txt  | sort -k 1,1 -g  >  $DIR/calibration_stdev/UNIT3753_$VAR.txt
done 

for VAR in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161 ; do 
awk -v VAR=$VAR '{   gsub( "_" , " ") ;  if(VAR==$2)   print $1 , $3      }'   $DIR/calibration_stdev/UNIT4000.txt  | sort -k 1,1 -g  >  $DIR/calibration_stdev/UNIT4000_$VAR.txt
done 

for VAR in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151 161 ; do 
awk -v VAR=$VAR '{ if(VAR==$2)   print $1 , $3      }'  $DIR/calibration_stdev/CALIBRATION.txt  | sort -k 1,1 -g    >  $DIR/calibration_stdev/CALIBRATION_$VAR.txt
done 


gnuplot -persist -e " set yrange [4400000:5500000] ; plot  'UNIT4000_11.txt' , 'UNIT4000_21.txt' , 'UNIT4000_31.txt' ,  'UNIT4000_41.txt' ,  'UNIT4000_51.txt' ,  'UNIT4000_61.txt' ,  'UNIT4000_71.txt' ,  'UNIT4000_81.txt' , 'UNIT4000_91.txt' , 'UNIT4000_101.txt' ,  'UNIT4000_111.txt' , 'UNIT4000_121.txt' , 'UNIT4000_131.txt' , 'UNIT4000_141.txt' , 'UNIT4000_151.txt' , 'UNIT4000_161.txt' , 'UNIT4000_171.txt' "

gnuplot -persist -e " set yrange [24800000:27000000] ; plot  'UNIT3753_11.txt' , 'UNIT3753_21.txt' , 'UNIT3753_31.txt' ,  'UNIT3753_41.txt' ,  'UNIT3753_51.txt' ,  'UNIT3753_61.txt' ,  'UNIT3753_71.txt' ,  'UNIT3753_81.txt' , 'UNIT3753_91.txt' , 'UNIT3753_101.txt' ,  'UNIT3753_111.txt' , 'UNIT3753_121.txt' , 'UNIT3753_131.txt' , 'UNIT3753_141.txt' , 'UNIT3753_151.txt' , 'UNIT4000_161.txt' , 'UNIT4000_171.txt' "

gnuplot -persist -e " set yrange [29000000:33000000] ; plot  'CALIBRATION_11.txt' , 'CALIBRATION_21.txt' , 'CALIBRATION_31.txt' ,  'CALIBRATION_41.txt' ,  'CALIBRATION_51.txt' ,  'CALIBRATION_61.txt' ,  'CALIBRATION_71.txt' ,  'CALIBRATION_81.txt' , 'CALIBRATION_91.txt' , 'CALIBRATION_101.txt' ,  'CALIBRATION_111.txt' , 'CALIBRATION_121.txt' , 'CALIBRATION_131.txt' , 'CALIBRATION_141.txt' , 'CALIBRATION_151.txt' , 'CALIBRATION_161.txt' , 'CALIBRATION_171.txt' "
 
# best combination 200 log ; 120 depth ;  151 diamiter stdev ;  30798730 

