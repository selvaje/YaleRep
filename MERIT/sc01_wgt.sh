#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 8 -N 1  
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc01_wgt.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc01_wgt.sh.%J.err 
#SBATCH --mail-user=email

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc01_wgt.sh


cd /project/fas/sbsc/ga254/dataproces/MERIT/input_gz

for file in dem_tif_n60w180.tar dem_tif_n60e000.tar dem_tif_n60w150.tar dem_tif_n60e030.tar dem_tif_n60w120.tar dem_tif_n60e060.tar dem_tif_n60w090.tar dem_tif_n60e090.tar dem_tif_n60w060.tar dem_tif_n60e120.tar dem_tif_n60w030.tar dem_tif_n60e150.tar dem_tif_n30w180.tar dem_tif_n30e000.tar dem_tif_n30w150.tar dem_tif_n30e030.tar dem_tif_n30w120.tar dem_tif_n30e060.tar dem_tif_n30w090.tar dem_tif_n30e090.tar dem_tif_n30w060.tar dem_tif_n30e120.tar dem_tif_n30w030.tar dem_tif_n30e150.tar dem_tif_n00w180.tar dem_tif_n00e000.tar n00w150  dem_tif_n00e030.tar dem_tif_n00w120.tar dem_tif_n00e060.tar dem_tif_n00w090.tar dem_tif_n00e090.tar dem_tif_n00w060.tar dem_tif_n00e120.tar dem_tif_n00w030.tar dem_tif_n00e150.tar dem_tif_s30w180.tar dem_tif_s30e000.tar dem_tif_s30w150.tar dem_tif_s30e030.tar dem_tif_s30w120.tar dem_tif_s30e060.tar dem_tif_s30w090.tar dem_tif_s30e090.tar dem_tif_s30w060.tar dem_tif_s30e120.tar dem_tif_s30w030.tar dem_tif_s30e150.tar dem_tif_s60w180.tar dem_tif_s60e000.tar dem_tif_s60e030.tar dem_tif_s60e060.tar dem_tif_s60w090.tar dem_tif_s60e090.tar dem_tif_s60w060.tar dem_tif_s60e120.tar dem_tif_s60w030.tar dem_tif_s60e150.tar ; do 
wget --user=globaldem  --password=preciseelevation   http://hydro.iis.u-tokyo.ac.jp/~yamadai/MERIT_DEM/distribute/v1.0.2/$file                            
done

export DIR=/project/fas/sbsc/ga254/dataproces/MERIT
ls *.tar   | xargs -n 1 -P 8 bash -c $'  
file=$1 
tar xvf $file 
dir=$(basename  $file .tar )
for tif  in  $DIR/input_gz/$dir/*.tif ; do 
filename=$(basename  $tif  )
gdal_translate -co COMPRESS=DEFLATE -co ZLEVEL=9 $tif $DIR/input_tif/$filename
done 
rm -r  $DIR/input_gz/$dir/*.tif 
' _ 



exit 

# create a list to recreate the tar.gz 
# lanciato a manon in /project/fas/sbsc/ga254/dataproces/MERIT/input_gz 
for TAR in *.tar ; do   
tar tf  $TAR    | awk -F/ '{  if (NR==1 ) { printf ("%s ", substr($1,9,7) )  }  else {     if($NF != "") printf ("%s ", substr($NF,0,7) ) } END {  printf ("\n")  }'  
done 

