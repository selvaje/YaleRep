for var in cec bdod cfvo nitrogen ocd soc phh2o; do sbatch --job-name=sc11_tiling20d --export=var=$var sc11_tiling20d_SOILGRIDS_top_layer.sh; done 


#for VAR in cec bdod cfvo nitrogen ocs ocd soc phh2o;do   echo $VAR >> /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/variableNames.txt; done
