
# scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/GLHYMPS/sc01_wget_glhy.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/GLHYMPS

#wget does not work directly
#wget https://my.pcloud.com/publink/show?code=XZLUqlkZa8zAR3dzXQ5paB4HRxneH5aaAa9X


#download manually and copy to grace
####  scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Data/GLHYMPS/GLHYMPS.7z jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS


## unzip
7za x GLHYMPS.7z

# remove un-useful files
rm GLHYMPS.cpg GLHYMPS.dbf GLHYMPS.prj GLHYMPS.sbn GLHYMPS.sbx GLHYMPS.shp GLHYMPS.shp.xml GLHYMPS.shx

module load R
source ~/bin/gdal

### Check projection (EPSG)
gdalsrsinfo -e GLHYMPS.gdb | grep PROJ.4

### Reproject original file to EPSG:4326
ogr2ogr -f GPKG -s_srs "+proj=cea +lon_0=0 +lat_ts=0 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -t_srs EPSG:4326 glhymps_ll.gpkg GLHYMPS.gdb

#scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/data/GLHYMPS/glhymps_ll.gpkg jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS


##################################################
############   PREPARATON OF TEILS 20 DEGRRES

### example of the table used in MERIT processing: this one does not cover all the extension of the GLHYMPS dataset
#cp /gpfs/gibbs/pi/hydro/hydro/dataproces//GEO_AREA/tile_files/tile_lat_long_20d_MERIT_noheader.txt  /gpfs/gibbs/pi/hydro/hydro/dataproces/GLHYMPS

###  Table creation in R with the coordinates of each tile (20 x 20 degreees) in the format xmin ymin xmax ymax and a fifth collumn representing with letters the vertical tiles (North-South teils)  and with numbers the horizontal teils (West-East)

R --vanilla --no-readline -q  << "EOF"

DIR = Sys.getenv(c("DIR"))
setwd(DIR)

tiles = as.data.frame(matrix(NA, nrow=162, ncol=5))

tiles[,1] = rep(seq(-180 , 160, 20), 9)
tiles[,2] = rep(seq(70,-90,-20), each= 18)
tiles[,3] = rep(seq(-160 , 180, 20), 9)
tiles[,4] = rep(seq(90,-70,-20), each= 18)
tiles[,5] = paste(rep(LETTERS[seq( from = 1, to = 9)], each=18), sprintf("%02d", seq(1:18)), sep="")
write.table(tiles, file="tiles20D.txt", sep=" ", col.names = FALSE, quote = FALSE, row.names = FALSE)

EOF

# replace the coordinate 90 N with 85 to save some computational processing

sed -i '/-90/!s/90/85/' tiles20D.txt
