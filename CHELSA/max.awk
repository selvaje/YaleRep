# compute a maximum value for the colum 13 based on the index 1

{
  
	if (NR==1){
	    old = $1 ;
	    }
	if ($1==old) {
	  if ($2>=max) { max = $2 }
	} else {
	    print old , 31 ,  max , 31, 30, 31, 30, 31, 31, 30, 31,  30 , 31 ; 
	  old = $1
	    max=$2
	    } 
}

END{print old , 31 ,   max , 31, 30, 31, 30, 31, 31, 30, 31,  30 , 31 ; }
