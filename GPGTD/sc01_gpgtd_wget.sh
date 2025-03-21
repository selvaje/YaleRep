#!/bin/bash

DIR=/gpfs/gibbs/pi/hydro/hydro/dataproces/GPGDT
cd $DIR

wget http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/monthlymeans/SAMERICA_WTD_monthlymeans.nc
wget http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/monthlymeans/OCEANIA_WTD_monthlymeans.nc
wget http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/monthlymeans/NAMERICA_WTD_monthlymeans.nc
wget http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/monthlymeans/EURASIA_WTD_monthlymeans.nc
wget http://thredds-gfnl.usc.es/thredds/fileServer/GLOBALWTDFTP/monthlymeans/AFRICA_WTD_monthlymeans.nc
