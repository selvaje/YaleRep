
# calculate spearman's coefficient rho
# $ $1 file.asc 
# $ $2 column of the file.asc 
# $ $3 column of the file.asc
# e.g.  calculate rho from column 1 and column 2 of the file.asc 
# e.g.  sh ~/sh/pearson_awk.sh file.asc 1 2 

 awk -v col1=$2 -v col2=$3   '{ if($col1 ~ /[[:digit:]]/  &&  $col2 ~ /[[:digit:]]/  ) { print $col1 , $col2 }  }' $1  | sort -k 1,1 -g | awk  '{ print $1 , $2 ,  NR  }'  |   sort -k 2,2 -g  | awk '{ print $1 , $2 ,  $3 , NR  }'   > sort_$1


awk '{ obs++ ;  rankxysum=(($3-$4)**2) + rankxysum 
}
END{ 
  print  1-(( 6 * rankxysum ) / ( obs * ( obs**2 - 1)))   
}' sort_$1
