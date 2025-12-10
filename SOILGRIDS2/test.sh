
export tifname=tifname
export box=box 
apptainer exec --env=SC=$SC /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project SE_data/exercise/tree_height_V1/geodata_raster/glad_ard_SVVI_max_msk.tif    <<'EOF'
echo varare_acc1_tile-000-000 varare_acc1_tile-000-001 varare_acc1_tile-001-000 varare_acc1_tile-001-001 | xargs -n 1 -P 4 bash -c $'
tile=\$1
echo \$tile 
export tile=\$1    
export tilen=\$(echo \$1 | cut -d e -f 3)       
export GDAL_CACHEMAX=2G         
export GDAL_NUM_THREADS=2  
echo r.out.gdal --o -f -c -m createopt=\'PREDICTOR=2,COMPRESS=DEFLATE,ZLEVEL=5,BIGTIFF=YES,NUM_THREADS=2,TILED=YES\' nodata=0 type=UInt32  input=\$tile outpu=/tmp/\${tifname}_\${box}\${tilen}_acc_sfd_Int_g84.tif --overwrite 
' _

EOF
"

