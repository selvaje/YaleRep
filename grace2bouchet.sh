sed -i \
-e 's|/gpfs/gibbs/pi/hydro/hydro|/nfs/roberts/pi/pi_ga254/hydro|g' \
-e 's|/vast/palmer/scratch/sbsc/hydro/|/nfs/roberts/scratch/pi_ga254/ga254/hydro/|g' \
-e 's|/gpfs/gibbs/pi/hydro/hydro/stderr|/nfs/roberts/scratch/pi_ga254/ga254/stderr|g' \
-e 's|/gpfs/gibbs/pi/hydro/hydro/stdout|/nfs/roberts/scratch/pi_ga254/ga254/stdout|g' \
-e 's|/vast/palmer/scratch/sbsc/ga254/|/nfs/roberts/scratch/pi_ga254/ga254/|g' \
-e 's|~/bin/gdal3|~/bin/gdal|g' \
$1    
