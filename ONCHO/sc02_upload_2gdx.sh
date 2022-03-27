#!/bin/bash
#SBATCH -p transfer
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 10:00:00 
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_upload_2gdx.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_upload_2gdx.sh.%J.err
#SBATCH --job-name=sc02_upload_2gdx.sh
#SBATCH --mem=5G

module purge
module load miniconda/4.10.3
conda activate gdx_env

##### sbatch /vast/palmer/home.grace/ga254/scripts/ONCHO/sc02_upload_2gdx.sh

ONCHO=/gpfs/loomis/project/sbsc/ga254/dataproces/ONCHO

# for file in  $ONCHO/input/chelsa/*.tif  ; do 
# python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_upload.py  $file 69252e85-9554-4375-bcbf-8a51d6160bab 
# echo uploaded $file
# done 

# for file in  $ONCHO/input/geomorpho90m/*.tif  ; do 
# python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_upload.py  $file 3f172123-1679-4a6f-80eb-c93068342c85
# echo uploaded $file
# done 

# for file in  $ONCHO/input/hydrography90m/*.tif  ; do 
# python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_upload.py  $file d08729d3-2feb-490d-8f7f-2e6a9700cb61
# echo uploaded $file
# done


for file in  $ONCHO/input/soilgrids/*.tif  ; do 
python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_upload.py  $file a7c90d1f-34ba-4f5e-89aa-35f4bc495ad2
echo uploaded $file
done

for file in  $ONCHO/input/soiltemp/*.tif  ; do 
python /vast/palmer/home.grace/ga254/scripts/ONCHO/gdx_upload.py  $file 86a24a34-42e6-4896-9689-7c47412b0f02
echo uploaded $file
done

conda  deactivate

