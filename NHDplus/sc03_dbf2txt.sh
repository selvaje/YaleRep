# bsub   -W 24:00  -n 1  -R "span[hosts=1]"  -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc03_dbf2txt.sh.%J.out -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc03_dbf2txt.sh.%J.err bash /gpfs/home/fas/sbsc/ga254/scripts/NHDplus/sc03_dbf2txt.sh


# for file in /project/fas/sbsc/ga254/dataproces/NHDplus/dbf/*/PlusFlowlineVAA.dbf ; do 

#     export filename=$( basename $(dirname  $file ))
#     export file

# module load Apps/R/3.1.1-generic
 
# R --vanilla --no-readline   -q  <<'EOF'

# library("foreign") 
# filename = Sys.getenv(c('filename'))
# file = Sys.getenv(c('file'))
# dbf = read.dbf(file)
# write.table(dbf , paste("/project/fas/sbsc/ga254/dataproces/NHDplus/txt/",filename,".txt" , sep="" )  , sep=" ")
# EOF

# done 

# add order to the shp 

DIR=/project/fas/sbsc/ga254/dataproces/NHDplus

# ogrinfo temp.shp -sql "ALTER TABLE temp DROP COLUMN field_to_drop" 

for file in   $DIR/shp/NHDPlusV21_*/NHDFlowline.shp ; do 
    namefile=$( basename  $( dirname $file ))
    base=$( echo $namefile | awk -F _ '{  print $1"_"$2"_"$3  }')
    awk '{if(NR>1) {print $2,$5}}' $DIR/txt/${base}_NHDPlusAttributes_*.txt > $DIR/txt/${base}_order.txt
    ogrinfo $file  -sql "ALTER TABLE NHDFlowline DROP COLUMN StreamOrde "
    oft-addattr-new.py  $file  COMID StreamOrde Int  $DIR/txt/${base}_order.txt    0 
done 
