

cd /gpfs/gibbs/pi/hydro/hydro/dataproces/CAMELS/input/shp
awk -F '\t' '{if (NR>1) print $5,$4}'  gauge_information.txt  >  gauge_x_y.txt 
awk -F '\t' '{if (NR>1) print $5,$4,$6}'  gauge_information.txt  >  gauge_x_y_area.txt 


paste -d "" gauge_x_y_area.txt $( gdallocationinfo -valonly -geoloc /gpfs/gibbs/pi/hydro/hydro/dataproces/MERIT_HYDRO/flow_tiles/all_tif_dis.vrt   <  gauge_x_y.txt ) > gauge_x_y_area_flowarea.txt

