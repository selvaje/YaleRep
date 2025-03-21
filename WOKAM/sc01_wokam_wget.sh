## scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/WOKAM/sc01_wokam_wget.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/WOKAM

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/WOKAM
cd $DIR
wget https://download.bgr.de/bgr/grundwasser/whymap/shp/WHYMAP_WOKAM_v1.zip
unzip WHYMAP_WOKAM_v1.zip
mv  WHYMAP_WOKAM/shp/ .


###    The WOKAM dataset provides a point shapefile with springs (201) and the value of the Minimum and maximum flow discharge in m3/s
