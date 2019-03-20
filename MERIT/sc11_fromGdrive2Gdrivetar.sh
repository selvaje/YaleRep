#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 1:00:00
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc11_fromGdrive2Gdrivetar.sh.%A.%a.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc11_fromGdrive2Gdrivetar.sh.%A.%a.err
#SBATCH --array=1-57


# for TOPO in geom dev-magnitude dev-scale rough-magnitude rough-scale elev-stdev aspect aspect-sine aspect-cosine northness eastness dx dxx dxy dy dyy pcurv tcurv roughness tpi tri vrm cti spi slope convergence ; do sbatch --export=TOPO=$TOPO   /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc11_fromGdrive2Gdrivetar.sh  ; done 

# sbatch  --export=TOPO=geom    /gpfs/home/fas/sbsc/ga254/scripts/MERIT/sc11_fromGdrive2Gdrivetar.sh  

# SLURM_ARRAY_TASK_ID=1
# TOPO=geom


export SC=/gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT
string=$( head -n  $SLURM_ARRAY_TASK_ID  /gpfs/loomis/project/fas/sbsc/ga254/dataproces/MERIT/input_gz/tar_tiles.txt | tail -1 ) 

cd $SC/gdrive90m/$TOPO

GZIP=-9 
tar -czvf  $SC/gdrive90m_tar/$TOPO/${TOPO}_90M_$(echo $string | cut -d " " -f 1).tar.gz   $( for tile in $(echo $string) ; do ls  ${TOPO}_90M_${tile}.tif 2>/dev/null  ; done )  

exit 




