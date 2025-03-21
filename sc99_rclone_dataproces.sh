#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout/sc99_rclone_dataproces.sh.%J.out  
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr/sc99_rclone_dataproces.sh.%J.err
#SBATCH --mem=1G
#SBATCH --job-name=sc99_rclone_dataproces.sh
ulimit -c 0

## sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/sc99_rclone_dataproces.sh


cd /gpfs/gibbs/pi/hydro/hydro

# rclone copy   dataproces/CHELSA            remote:dataproces/CHELSA
# rclone copy   dataproces/ESALC_GFC         remote:dataproces/ESALC_GFC
# rclone copy   dataproces/GARID             remote:dataproces/GARID
# rclone copy   dataproces/GEDI_ICESAT2  
# rclone copy   dataproces/GFC               remote:dataproces/GFC       
# rclone copy   dataproces/GLAD_GSWD         remote:dataproces/GLAD_GSWD  
# rclone copy   dataproces/GOODD             remote:dataproces/GOODD  
# rclone copy   dataproces/GRDC              remote:dataproces/GRDC       
# rclone copy   dataproces/GSIM              remote:dataproces/GSIM  
# rclone copy   dataproces/HWSD              remote:dataproces/HWSD     
# rclone copy   dataproces/LSTM              remote:dataproces/LSTM         
# rclone copy   dataproces/MERIT_HYDRO_DEM   remote:dataproces/MERIT_HYDRO_DEM  
# rclone copy   dataproces/NHNO              remote:dataproces/NHNO
# rclone copy   dataproces/SOILMOIST         remote:dataproces/SOILMOIST
rclone copy   dataproces/MERIT_HYDRO  remote:dataproces/MERIT_HYDRO 
# rclone copy   dataproces/TERRA             remote:dataproces/TERRA 
# rclone copy   dataproces/ENVTABLES  
# rclone copy   dataproces/FLOW       
# rclone copy   dataproces/GCN250  
# rclone copy   dataproces/GEO_AREA      
# rclone copy   dataproces/GIA 
# rclone copy   dataproces/GLHYMPS 
# rclone copy   dataproces/GPGDT
# rclone copy   dataproces/GRWL
# rclone copy   dataproces/GSW
# rclone copy   dataproces/HYSOGS   
# rclone copy   dataproces/MERIT        
# rclone copy   dataproces/MERIT_Hydro–Vector  
# rclone copy   dataproces/PEATMAP    
# rclone copy   dataproces/SOILRESP    
# rclone copy   dataproces/WOKAM
# rclone copy   dataproces/ESALC 
# rclone copy   dataproces/FLOW1k
# rclone copy   dataproces/GEDI
# rclone copy   dataproces/GEVAPT
# rclone copy   dataproces/GLAD_ARD
# rclone copy   dataproces/GLW_3
# rclone copy   dataproces/GRAND
# rclone copy   dataproces/GSCD_v1.9
# rclone copy   dataproces/GWM 
# rclone copy   dataproces/ICESAT2 

# rclone copy   dataproces/MNP 
# rclone copy   dataproces/SOILGRIDS
# rclone copy   dataproces/STREAM_SHP
