### scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/Nextcloud/scripts/global-environmental-variables/HYSOGS/sc01_wget_HYSOGS.sh jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/scripts/HYSOGS


###   Link to download site :  needs to log in
###   https://daac.ornl.gov/cgi-bin/dsviewer.pl?ds_id=1566
###   wget https://daac.ornl.gov/daacdata/global_soil/Global_Hydrologic_Soil_Group/data/HYSOGs250m.tif
###   Downloaded locally and copied to GRACE
scp -i ~/.ssh/JG_PrivateKeyOPENSSH /home/jaime/data/GCN250/HYSOGs250m.tif jg2657@grace1.hpc.yale.edu:/gpfs/gibbs/pi/hydro/hydro/dataproces/HYSOGS

gdal_edit.py -a_ullr -180 84 180 -56 /gpfs/gibbs/pi/hydro/hydro/dataproces/HYSOGS/HYSOGs250m.tif
