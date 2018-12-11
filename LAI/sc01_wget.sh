


# wget ftp://ftp.glcf.umd.edu/glcf/GLASS/LAI/AVHRR/1982/

# BBE ? 
# DSSR 
# EMT 
# FAPAR
# GPP
# LAI
# PAR



for file in *.hdf ; do   filename=$(basename $file .hdf) ;   J=$(echo  $filename  | awk -F "." '{ gsub("A","") ; print int(substr($3,5,7))  }') ; echo $filename.hdf $filename.$(date -d "`date +%Y`-01-01 +$(( ${J} - 1 ))days" +%m  ).hdf     ; done > julian_month.txt 



echo 01 02 03 04 05 06 07 08 09 10 11 12 | xargs -n 1 -P 4 bash -c $' 
MM=$1
gdalbuildvrt  -overwrite -separate  -srcnodata -9999 -vrtnodata -9999   $MM.vrt $(grep $MM.hdf julian_month.txt | awk \'{ print $1   }\')
pkstatprofile   -nodata -9999  -f mean  -i  $MM.vrt -o ${MM}_mean.tif 
' _ 

rm julian_month.txt 
