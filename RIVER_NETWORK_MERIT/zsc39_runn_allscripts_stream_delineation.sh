

sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc01_wget_merit_river.sh
sleep 60 
sbatch  --dependency=afterok:$(qmys | grep sc01_wget_merit_river.sh  | awk '{  print $1 }'  | uniq )    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc02_layers_preparation.sh
sleep 60


sbatch   /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc20_build_dem_location_4streamMacroTile.sh
sleep 60
sbatch -d afterany:$(qmys | grep  sc20_build_dem_location_4streamTile.sh | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc21_broken_basin_manip.sh
sleep 60
sbatch -d afterany:$(qmys | grep sc21_broken_basin_manip.sh  | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc22_broken_basin_clumping.sh 
sleep 60
sbatch -d afterany:$(qmys | grep sc22_broken_basin_clumping.sh  | awk '{ print $1}' | uniq)  /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc23_build_dem_location_broken_basin.sh
sleep 60
batch  -d afterany:$(qmys | grep sc23_build_dem_location_broken_basin.sh | awk '{ print $1  }' | uniq)    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc25_reclass_lbasin_intb.sh
sleep 60
batch  -d afterany:$(qmys | grep sc25_reclass_lbasin_intb.sh  | awk '{ print $1  }' | uniq)    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc26_reclass_lbasin_broken.sh 
sleep 60
batch  -d afterany:$(qmys | grep sc26_reclass_lbasin_broken.sh   | awk '{ print $1  }' | uniq)    /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc27_tiling_merge_lbasin_intb_broken.sh
sleep 60

sleep 60

exit 






exit 




for TOPO in altitude ; do
for MATH in min ; do 
for  KM in 0.2 0.3 0.4 0.5 ; do  
sbatch --dependency=afterok:$(qmys | grep sc01_wget_merit_river.sh  | awk '{  print $1 }'  | uniq )  \
 -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out \
 -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err \
 -J sc04_elvCorrect_MultiResKM${KM}TOPO${TOPO}MATH${MATH}.sh --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc04_elvCorrect_MultiRes.sh  
done   
done 
done
sleep 30 
for TOPO in altitude ; do  
for MATH in min ; do 
for  KM in 0.2 0.3 0.4 0.5 ; do  
sbatch  --dependency=afterok$( qmys | grep sc04_elvCorrect_MultiRes  | awk '{  printf (":%i" ,  $1 ) }'  | uniq  )  \
 -o  /gpfs/scratch60/fas/sbsc/ga254/stdout/sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.out \
 -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh.%J.err \
-J sc05_elvCorrect_MultiResMergingKM${KM}TOPO${TOPO}MATH${MATH}.sh  --export=TOPO=$TOPO,MATH=$MATH,KM=$KM /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc05_elvCorrect_MultiResMerging.sh 
done
done
done
sleep 30 

