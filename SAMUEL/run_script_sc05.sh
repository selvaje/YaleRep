for var in cec bdod cfvo nitrogen ocd soc phh2o; do sbatch --job-name=sc05_weighted_average --export=var=$var sc05_weighted_average.sh  ;done 


#for VAR in cec bdod cfvo nitrogen ocs ocd soc phh2o;do   echo $VAR >> /gpfs/gibbs/pi/hydro/st929/SOILGRIDS2/dataprocess/variableNames.txt; done
