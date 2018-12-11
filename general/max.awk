# compute a maximum value for the colum 13 based on the index 1

{
  if (NR==1){ 
    print $13
      } else {  
	if (NR==2){
	  old = $1
	    }
	if ($1==old) {
	  if ($13>=max) { max = $13 }
	} else {
	  print max;
	  old = $1
	    max=$13
	    } 
      }
}
END{print max}
