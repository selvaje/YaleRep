export MAKEFLAGS="-j$(nproc)"
apptainer build /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.sif  /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84.def 

### run grass8.4.0 as  /usr/local/grass-8.4.0/bin/grass
### run grass8.4.1 as  /usr/local/grass-8.4.1/bin/grass 

### To build as a sandbox:
export MAKEFLAGS="-j$(nproc)"
apptainer build --sandbox /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass8 /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass8.def 


## Then, to run the container and update it:
apptainer shell --writable /gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF/grass84
# Inside the container
apt update
apt upgrade -y
