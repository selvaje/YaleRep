



### install gsutil https://cloud.google.com/storage/docs/gsutil_install 
## https://console.cloud.google.com/storage/browser/_details/earthenginepartners-hansen/water/00N_070W/2001_percent.tif

source ~/bin/gdal3
source ~/bin/pktools 

# for year in $(seq 1999 2019 ) ; do 
# gsutil cp  gs://earthenginepartners-hansen/water/10N_060W/${year}_percent.tif  .
# done 

for year in 01_Jan 02_Feb 03_Mar 04_Apr 05_May 06_Jun 07_Jul 08_Aug 09_Sep 10_Oct 11_Nov 12_Dec  ; do 
gsutil cp  gs://earthenginepartners-hansen/water/10N_060W/${year}_percentv1.tif  .
done
 
