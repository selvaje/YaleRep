
### Save all layers as netCDF's

# qsub  /lustre/scratch/client/fas/sbsc/sd566/global_wsheds/scripts_wsheds_omega/omega_ram/access_node.sh
# qsub  /lustre/scratch/client/fas/sbsc/sd566/global_wsheds/scripts_wsheds_omega/omega_ram/access_node_devel.sh


### Access the node for 4 h
tmp=$(qmy | grep access_node_deve)
job=$( cut -d '.' -f 1 <<< "$tmp" ) # cut at first point
node_tmp=$(qstat -n $job | grep compute)
node=$( cut -d '/' -f 1 <<< "$node_tmp" ) # cut at first slash
ssh -x  ${node% *} 

### Access the node for 24 h
tmp=$(qmy | grep access_node)
job=$( cut -d '.' -f 1 <<< "$tmp" ) # cut at first point
node_tmp=$(qstat -n $job | grep compute)
node=$( cut -d '/' -f 1 <<< "$node_tmp" ) # cut at first slash
ssh -x  ${node% *} 



### Omega:
# > modulefind | grep netcdf
# Applications/CESM/1.0.4-netcdf4
# Apps/CESM/1.0.4-netcdf4
# Libraries/HDF4/4.2.9-nonetcdf-gcc
# Libs/HDF4/4.2.9-nonetcdf-gcc


### Set modules. Only gdal-test does netCDF!

module load Tools/CDO/1.6.4
module load Tools/NCO/4.4.4


INDIR=/lustre/scratch/client/fas/sbsc/sd566/global_wsheds/global_results_merged/filled_str_ord_maximum_max50x_lakes_manual_correction
OUTDIR=/lustre/scratch/client/fas/sbsc/sd566/global_wsheds/global_results_merged/netCDF
TEMPDIR=/lustre/scratch/client/fas/sbsc/sd566/global_wsheds/global_results_merged/netCDF/tmp


### Scale factors:
### Only global as character, but not as "double" in the variables (as otherwise the data is multiplied by the scale factor; can be useful but is likely to lead to confusion, if e.g. Bioclims have several scales?



###====================================
### Landcover average
###====================================
varname_raw=lu
varname=tpi
outname=landcover_average


nodata=-9999
add_scale=1


longname=Topographic_position_index
VAR=tpi_max_km
for km  in 10 50 100 ;  do
    if [ $km -eq 10  ] ; then b=1 ; fi 
    if [ $km -eq 50  ] ; then b=2 ; fi 
    if [ $km -eq 100 ] ; then b=3 ; fi 

    gdal_translate -of netCDF    -co ZLEVEL=9  -co  COMPRESS=DEFLATE  -co FORMAT=NC4C   $VAR$km.tif   $VAR$km.nc 

### Change the dimension number
    ncatted  -O -a long_name,Band1,o,c,${longname}        $VAR$km.nc -h 
    ncatted  -O -a long_name,lon,o,c,Longitude            $VAR$km.nc -h
    ncatted  -O -a long_name,lat,o,c,Latitude             $VAR$km.nc -h
    ncatted  -O -a _FillValue,Band1,o,i,-9999        $VAR$km.nc -h
    ncrename -v Band1,${VAR}${km}   $VAR$km.nc -h

done
ncecat --gag  tpi_max_km10.nc tpi_max_km50.nc tpi_max_km100.nc    out.nc 


### Edit NoData values
# ncatted -a _FillValue,,o,f,$nodata  $TEMPDIR/${varname}_$var.nc   -h
# ncatted -a missing_value,,o,f,$nodata   $TEMPDIR/${varname}_$var.nc   -h # not needed any more (causes a conflict?)




 nccopy -u -d9   # compress more 

### Append the layers along a common z-axis (- u <axis-name> ). Keep general name ("variable"), cannot be identical to variable name in raster
ncecat -u variable  $TEMPDIR/${varname}_??.nc    $TEMPDIR/$outname.nc  -h 
### --> OK, works in R and single bands are numbered from 1, 2, 3,...


### Change variable name
ncrename -v Band1,$varname    $TEMPDIR/$outname.nc  -h 

### Change long name
ncatted -O -a long_name,${varname},o,c,$longname   $TEMPDIR/$outname.nc  -h
ncatted -O -a long_name,lon,o,c,Longitude   $TEMPDIR/$outname.nc  -h
ncatted -O -a long_name,lat,o,c,Latitude  $TEMPDIR/$outname.nc  -h


# cp $TEMPDIR/$outname.nc  $TEMPDIR/copy  ### NoData and _FillValue both -1, and are identified correctly in R!!!
# the copy has the original -1 values for "NoData values" and "_FillValue"


### Set NoData value (slow..). This information is lost in the ncecat-command
### # https://www.ncl.ucar.edu/Document/Language/fillval.shtml
ncatted -a _FillValue,${varname},o,f,$nodata  $TEMPDIR/$outname.nc  -h

### Remove global NoData
# ncatted -O -a _FillValue,,d,, $TEMPDIR/$outname.nc  -h

# Add Units to global metadata
ncatted -O -a units,global,a,c,"Percent cover [%]" $TEMPDIR/$outname.nc  -h

# Add scale factor to global metadata
# ncatted -a scale_factor,global,d,, $TEMPDIR/$outname.nc  -h  # remove global scale factor 
ncatted -O -a scale_factor,global,a,c,$add_scale $TEMPDIR/$outname.nc  -h  # c for character, d for double

### Set scale factor for variable
# ncatted -a scale_factor,${varname},d,, $TEMPDIR/$outname.nc  -h # remove scale factor for variable
# ncatted -O -a scale_factor,${varname},o,d,$add_scale $TEMPDIR/$outname.nc  -h


### Set units for variable
ncatted -O -a units,${varname},o,c,"Percent cover [%]" $TEMPDIR/$outname.nc  -h
### Delete the extra spatial_ref and Geotransform-attributes --> not used and cause annoying warnings in R.
ncatted -O -a spatial_ref,,d,, $TEMPDIR/$outname.nc  -h
ncatted -O -a GeoTransform,,d,, $TEMPDIR/$outname.nc  -h

# Add the source data to global metadata
ncatted -O -a Source,global,a,c,"Consensus landcover dataset, Tuanmu & Jetz (2014)" $TEMPDIR/$outname.nc  -h
# Add dataset description in global metadata
ncatted -O -a Dataset,global,a,c,"Upstream average landcover" $TEMPDIR/$outname.nc  -h
# Add email address in global metadata
# ncatted -O -a Author,global,d,,"sami.domisch@yale.edu" $TEMPDIR/$outname.nc  -h # delete the author
ncatted -O -a Author,global,a,c,"sami.domisch@yale.edu & giuseppe.amatulli@gmail.com" $TEMPDIR/$outname.nc  -h

### Add software
# ncatted -O -a Software,global,d,,"GRASS 7 using the add-ons r.stream.watersheds & r.stream.variables" $TEMPDIR/$outname.nc  -h # delete
ncatted -O -a Software,global,a,c,"GRASS 7 using the add-ons r.stream.watersheds & r.stream.variables" $TEMPDIR/$outname.nc  -h

# Delete history
# ncatted -O -a history,global,d,,,,  $TEMPDIR/$outname.nc  -h
ncatted -a history,global,d,, $TEMPDIR/$outname.nc  -h

gdalinfo $TEMPDIR/$outname.nc

### Copy the final file
cp $TEMPDIR/$outname.nc  $OUTDIR/$outname.nc

### Remove tmp-files
rm $TEMPDIR/${varname}_??.nc

