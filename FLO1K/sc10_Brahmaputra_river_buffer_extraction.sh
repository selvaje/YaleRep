#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 24:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc10_Brahmaputra_river_buffer_extraction.sh.%A_%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc10_Brahmaputra_river_buffer_extraction.sh.%A_%a.err
#SBATCH --mem-per-cpu=5000


# for file in  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSW/brahmaputra/brahmaputra*_ct.tif ; do   sbatch --export=file=$file    /gpfs/home/fas/sbsc/ga254/scripts/FLO1K/sc10_Brahmaputra_river_buffer_extraction.sh  ; done 


export  FLO=/project/fas/sbsc/ga254/dataproces/FLO1K
export  SHP=/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/shp
export  EXT=/project/fas/sbsc/ga254/dataproces/FLO1K/brahmaputra/extract_flo1k
export  RAM=/dev/shm 

# paste -d " " <(ogrinfo -al $SHP/point.shp | grep " id" | awk '{ print $4 }' ) <(ogrinfo -al $SHP/point.shp | grep POINT | awk '{ gsub ("[(),]"," ") ; print $2, $3 }') | sort -g | awk '{  print $2 , $3  }' >  $SHP/point.txt 

for P in $(seq 1 10 ) ; do 
gdallocationinfo -geoloc -valonly $FLO/FLO1K.ts.1960.2015.qma_invertlatlong.nc  < <( head -$P $SHP/point.txt | tail -1  ) > $EXT/point${P}_max.txt 
done 

# gdal_rasterize -a_srs EPSG:4326 -a_nodata 0 -co COMPRESS=DEFLATE -co ZLEVEL=9 -a ID  -init 0 -l buffer_point   -a_srs EPSG:4326 -tr 0.000277777777778 0.000277777777778 \
#  -te $(getCorners4Gwarp /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSW/brahmaputra/brahmaputra2015_ct.tif)   -ot Byte $SHP/buffer_point.shp $SHP/buffer_point_tif.tif 
# gdal_translate -projwin  $( getCornersOgr4Gtranslate  $SHP/buffer_point.shp )   -co COMPRESS=DEFLATE -co ZLEVEL=9   ../shp/buffer_point_tif.tif     ../shp/buffer_point_tif_crop.tif 


filename=$(basename $file .tif )
gdal_translate -projwin  $( getCornersOgr4Gtranslate  $SHP/buffer_point.shp )   -co COMPRESS=DEFLATE -co ZLEVEL=9  $file  $RAM/$filename.tif 
pkstat -i  $RAM/$filename.tif -hist2d -i  $SHP/buffer_point_tif_crop.tif | awk '{ if($3!=0 && $1!="" ) print  }'  | awk  '{ gsub("0.136364","0") ;  gsub("0.954545","1")  ; gsub("2.04545" , "2") ; gsub("2.86364" , "3") ;    printf ("%i %i %i\n" , $1 , $2 , $3)  }' > $EXT/$filename.txt
rm  $RAM/$filename.tif 










