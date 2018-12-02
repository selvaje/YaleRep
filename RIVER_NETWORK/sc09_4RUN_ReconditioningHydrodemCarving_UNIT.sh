
for UNIT in $( awk '{print $1}' /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt | uniq ) ; do 
    grep ^$UNIT  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_N_DIM.txt | awk '{ if($2 > 100 ) { print }  }' > /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_${UNIT}_DIM.txt
done 


for RADIUS in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151  ; do 
for UNIT in 3753 4000 ; do 
for file in $( ls /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_200_DIM.txt ) ; do 
     echo lunch the start scritp 
     PREV_JOB=$(bsub -W 00:01  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/start.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/start.err bash /gpfs/home/fas/sbsc/ga254/scripts/general/start_bsub.sh | cut -d'<' -f2 | cut -d'>' -f1 )  
     for LINE in  $(cat $file  | tr " " "_"  )  ; do
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT  
         N=$( echo $LINE   | tr "_" " "  | awk '{  print $1  }' ) ; 
         DIM=$( echo $LINE | tr "_" " "  | awk '{  print $2  }' ) ; 
         RAM=$(grep $UNIT  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt | awk -F "_" '{print $2}' )
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT   RAM $RAM  PREV_JOB  $PREV_JOB 
	 NEXT_JOB=$( bsub -w "ended($PREV_JOB)"  -W 24:00 -M ${RAM}   -R "rusage[mem=${RAM}]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $N $DIM  $UNIT   GLOBE  $RADIUS 8  | cut -d'<' -f2 | cut -d'>' -f1   ) 
 	 PREV_JOB=$NEXT_JOB 
     done 
done
done
done 

# slurm 
# for RADIUS in 11 21 31 41 51 61 71 81 91 101 111 121 131 141 151  ; do 

for RADIUS in 161 171 ; do 
for UNIT in 3753 4000 ; do 
for file in $( ls /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_200_DIM.txt ) ; do 
     echo lunch the start scritp 
     PREV_JOB=$(sbatch  /gpfs/home/fas/sbsc/ga254/scripts/general/start_bsub.sh | awk '{ print $4  }'  )  
     for LINE in  $(cat $file  | tr " " "_"  )  ; do
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT  
         N=$( echo $LINE   | tr "_" " "  | awk '{  print $1  }' ) ; 
         DIM=$( echo $LINE | tr "_" " "  | awk '{  print $2  }' ) ; 
         RAM=$(grep $UNIT  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt | awk -F "_" '{print $2}' )
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT   RAM $RAM  PREV_JOB  $PREV_JOB 
	 NEXT_JOB=$(  sbatch    -d afterany:$PREV_JOB    --export=N=$N,DIM=$DIM,UNIT=$UNIT,GEO=GLOBE,RADIUS=$RADIUS,TRH=8 -J sc06_ReconditioningHydrodemCarving_UNIT${UNIT}_N${N}_DIM${DIM}_STDEV${RADIUS}_TRH${TRH}.sh   --mem-per-cpu=$RAM  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc09_ReconditioningHydrodemCarving_UNIT.sh | awk '{ print $4  }'  )  
 	 PREV_JOB=$NEXT_JOB 
     done 
done
done
done 


#









EUROASIA 

for UNIT in 497_338_3562_333  ; do 
for file in $( ls /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/occurance_???_DIM.txt ) ; do 
     echo lunch the start scritp 
     PREV_JOB=$(bsub -W 00:01  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/start.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/start.err bash /gpfs/home/fas/sbsc/ga254/scripts/general/start_bsub.sh | cut -d'<' -f2 | cut -d'>' -f1 )  
     for LINE in  $(cat $file | tr " " "_"  )  ; do
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT  
         N=$( echo $LINE   | tr "_" " "  | awk '{  print $1  }' ) ; 
         DIM=$( echo $LINE | tr "_" " "  | awk '{  print $2  }' ) ; 
         RAM=$(grep $UNIT  /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK/grassdb/UNIT_RAM.txt  | awk -F  "_" '{  print $2  }' )     
         echo lunch the start scritp N $N DIM $DIM  UNIT  $UNIT   RAM $RAM  PREV_JOB  $PREV_JOB 
	 NEXT_JOB=$( bsub -w "ended($PREV_JOB)"  -W 24:00 -M ${RAM}   -R "rusage[mem=${RAM}]" -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh $N $DIM  $UNIT  EUROASIA   | cut -d'<' -f2 | cut -d'>' -f1   ) 
 	 PREV_JOB=$NEXT_JOB 
     done 
done
done







PREV_JOB=$(bsub -W 00:01  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/start.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/start.err bash /gpfs/home/fas/sbsc/ga254/scripts/general/start_bsub.sh | cut -d'<' -f2 | cut -d'>' -f1 )  
for TRH in 1 2 3 4 5 6 7 8 9 10 ; do 
NEXT_JOB=$( bsub -w "ended($PREV_JOB)"  -W 24:00  -n 1  -R "span[hosts=1]"   -M 5000   -R "rusage[mem=5000]"     -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc06_ReconditioningHydrodemCarving.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc06_ReconditioningHydrodemCarving.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK/sc06_ReconditioningHydrodemCarving_UNIT.sh 200 110  3753  GLOBE 81 $TRH  | cut -d'<' -f2 | cut -d'>' -f1   ) 
PREV_JOB=$NEXT_JOB 
done 




