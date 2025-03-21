#!/bin/sh
# derived by average.sh remove the /obs
# calculate average of column txt files base on CLASS/ID column
# the CLASS/ID column can be a number or a string
# all the row and column  are processed
# in case no CLASS/ID column in the file crate a dummy variable (e.g 1 ) for all che row
# the file has to be sorted base on the  CLASS/ID column!!!
# input_s.asc 
# ID V1 V2 V3 
# 1  3  5  3
# 1  5  7  5
# 2  2  1  1
# output.asc 
# 1  4  6  4
# 2  2  1  1
# 
# $ $1 input.asc
# $ $2 output.asc
# e.g.  sort -k 1,1 input.asc > input_s.asc 
# e.g.  sh ~/sh/average.sh input_s.asc output.asc 
# in case of bash script use EOF sintax
# sh ./average.sh input_s.asc output.asc <<EOF 
# y/n
# 1/2/3/4/...
# 1/2/3/4/...
# EOF


echo -n  "The first row is an header (y/n) = "
read header 

echo -n "Position of the master ClASS/ID column (1/2/3/4/....)  = "
read colID

echo -n "Precision of the average results (Decimal number 1/2/3/... ) = "
read Dec

if [ $header = "y" ] ; then 
awk -v Dec=$Dec -v  colID=$colID  '{ 
    if (NR ==1)
	print $0;
	else{
	    if (NR == 2)
		old = $colID
		if($colID == old){
			nobs++;
			for(a=1; a<colID ; a++)
			sum[a] = sum[a]+$a
			for(i=colID+1 ; i<= NF ; i++)
			sum[i] = sum[i]+$i
		    } else {
			for(a=1; a<colID ; a++){ 
			    printf("%."Dec"f ",sum[a]) 
			    sum[a]=$a 
                         }
		        printf("%s ",old);
			for(i=colID+1; i<= NF ; i++){  
			    printf("%."Dec"f ",sum[i]) 
			    sum[i]=$i 
                        }
                        printf("\n")
		        old = $colID
			nobs = 1;
		    }
	}
}
END{
	for(a=1; a<colID ; a++){ printf("%."Dec"f ",sum[a]) } ;
	printf("%s ",old);
	for(i=colID+1; i<= NF ; i++){  printf("%."Dec"f ",sum[i])} ; 
	printf("\n") ;
    }'  $1 > $2

else 
    
awk -v Dec=$Dec -v  colID=$colID  '{ 
    	    if (NR == 1)
		old = $colID
		if($colID == old){
			nobs++;
			for(a=1; a<colID ; a++)
			sum[a] = sum[a]+$a
			for(i=colID+1 ; i<= NF ; i++)
			sum[i] = sum[i]+$i
			
		    } else {
			for(a=1; a<colID ; a++){ 
			    printf("%."Dec"f ",sum[a]) 
			    sum[a]=$a }
		        printf("%s ",old);
			for(i=colID+1; i<= NF ; i++){  
			    printf("%."Dec"f ",sum[i]) 
			    sum[i]=$i }
                        printf("\n")
		        old = $colID
			nobs = 1;
		    }
	}
END{
	for(a=1; a<colID ; a++){ printf("%."Dec"f ",sum[a]) } ;
	printf("%s ",old);
	for(i=colID+1; i<= NF ; i++){  printf("%."Dec"f ",sum[i])} ; 
	printf("\n") ;
    }'  $1 > $2
fi 

