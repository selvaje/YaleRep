
# bsub -W 1:00  -n 1  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_unzip.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_unzip.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc02_unzip.sh

DIR=/project/fas/sbsc/ga254/dataproces/NHDplus
cd /project/fas/sbsc/ga254/dataproces/NHDplus

# for file in /project/fas/sbsc/ga254/dataproces/NHDplus/download/*NHDSnapshot*.7z  ; do 
#     7za e   $file  -o$DIR/shp/$(basename $file .7z)  
# done 



for file in /project/fas/sbsc/ga254/dataproces/NHDplus/download/*NHDPlusAttributes*.7z  ; do 
     7za e   $file  -o$DIR/dbf/$(basename $file .7z)  
done 


