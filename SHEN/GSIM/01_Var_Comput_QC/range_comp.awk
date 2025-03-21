BEGIN{flag=0}
{if(NR==1) {
	minOri=$2;
	maxOri=$3;
	rangOri=$0}
 else {
     minCur=$2;
     maxCur=$3;
     if(minCur < minOri || maxCur > maxOri)
        {print $0;
	flag=1}
   }    
}
END{if(flag==1)
      print rangOri	
}
