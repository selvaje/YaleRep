
apptainer exec  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif bash -c "
/usr/bin/grass -f --text --tmp-project /home/ga254/SE_data/exercise/tree_height_V1/geodata_raster/glad_ard_SVVI_max_msk.tif   <<'EOF'
r.external input=/home/ga254/SE_data/exercise/tree_height_V1/geodata_raster/glad_ard_SVVI_max_msk.tif        output=msk  --overwrite 
g.region raster=msk zoom=msk
r.mask raster=msk --o
export tilex=\$(g.region -p | grep cols | cut -d ' ' -f 8)
export tiley=\$(g.region -p | grep rows | cut -d ' ' -f 8)
echo matrix size tilex \$tilex tiley \$tiley

EOF
"


exit
# 
# $(g.region -p | grep rows | cut -d ' ' -f 8)
