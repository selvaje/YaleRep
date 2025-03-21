#!/bin/bash

# calculate pearson's coefficient r
# # cheak automaticaly if the $2 and $3 are digit number
# $ $1 file.asc 
# $ $2 column of the file.asc 
# $ $3 column of the file.asc
# e.g.  calculate r from column 1 and column 2 of the file.asc 
# e.g.  sh ~/sh/pearson_awk.sh file.asc 1 2 

awk  -v col1=$2 -v col2=$3   '{  
if($col2 ~ /[[:digit:]]/  &&  $col3 ~ /[[:digit:]]/  )
{
obs++
xysum=($col1*$col2)+xysum
xsum=$col1+xsum
ysum=$col2+ysum
x2sum=($col1*$col1)+x2sum
y2sum=($col2*$col2)+y2sum
}}
END{ 
  print (obs * xysum - xsum * ysum)/((sqrt(obs*x2sum - xsum*xsum)) * (sqrt(obs*y2sum - ysum*ysum)))
    }' $1 

