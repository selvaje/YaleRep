#!/bin/sh
#
# This script installs an apptainer container for PyJeo use in SBSC HPC cluster
#

BASE=/gpfs/gibbs/pi/hydro/hydro/scripts/APTAINER_SIF

mkdir $BASE || true

rm -rf $BASE/pyjeo $BASE/pyjeo-install $BASE/pip-cache $BASE/pyjeo-venv
mkdir $BASE/pyjeo

( cd $BASE/pyjeo \
&& curl -L --output mialib.tar.gz https://github.com/ec-jrc/jeolib-miallib/archive/refs/tags/v1.1.1.tar.gz \
&& curl -L --output jiplib.tar.gz https://github.com/ec-jrc/jeolib-jiplib/archive/refs/tags/v1.1.3.tar.gz \
&& curl -L --output pyjeo.tar.gz https://github.com/ec-jrc/jeolib-pyjeo/archive/refs/tags/v1.1.7.tar.gz \
)

cp -v pyjeo*.def $BASE/.

( cd $BASE \
&& apptainer build $BASE/pyjeo1.sif $BASE/pyjeo1.def \
&& apptainer build $BASE/pyjeo2.sif $BASE/pyjeo2.def \
&& apptainer run --bind /gpfs/gibbs/project/sbsc/hydro $BASE/pyjeo2.sif $BASE/pyjeo2.def \
)

# if ! grep PYJEO_BASE $HOME/.bashrc
# then
# cat >> $HOME/.bashrc <<EOF
# #--- Begin stuff added to run PyJeo in apptainer ---
# if [ $(printenv|grep SLURM|wc -l) -gt 1 ]
# then
# export PYJEO_BASE=$BASE
# [ -f \$PYJEO_BASE/pyjeovenv/bin/activate ] && source \$PYJEO_BASE/pyjeovenv/bin/activate
# export PYJEO_RUN="apptainer exec --bind /gpfs/gibbs/project/sbsc/hydro --bind /gpfs/gibbs/pi/hydro/hydro --bind /vast/palmer/scratch/sbsc/hydro \$PYJEO_BASE/pyjeo2.sif bash -i -c python3"
# fi
# #--- End ---
# EOF
# fi
