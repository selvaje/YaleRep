

cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/MERIT 

for TOPO in aspect dx dxx dxy dy dyy pcurv roughness slope tcurv tpi tri vrm cti spi convergence ; do
    for file in $TOPO/tiles/??_???_???.tif ; do
	filename=$(basename $file .tif )
	mv $file  $TOPO/tiles/${TOPO}_100M_MERIT_$filename.tif 
    done
done


for TOPO in aspect ; do for file in $TOPO/tiles/??_???_???_sin.tif ; do filename=$(basename $file _sin.tif) ;  mv $file  $TOPO/tiles/${TOPO}-sine_100M_MERIT_$filename.tif ; done ; done
for TOPO in aspect ; do for file in $TOPO/tiles/??_???_???_cos.tif ; do filename=$(basename $file _cos.tif) ;  mv $file  $TOPO/tiles/${TOPO}-cosine_100M_MERIT_$filename.tif ; done ; done

for TOPO in aspect ; do for file in $TOPO/tiles/??_???_???_Nw.tif ; do filename=$(basename $file _Nw.tif) ;  mv $file  northness/tiles/northness_100M_MERIT_$filename.tif ; done ; done
for TOPO in aspect ; do for file in $TOPO/tiles/??_???_???_Ew.tif ; do filename=$(basename $file _Ew.tif) ;  mv $file  easthness/tiles/easthness_100M_MERIT_$filename.tif ; done ; done


for TOPO in stdev  ; do for file in $TOPO/tiles/??_???_???.tif ; do filename=$(basename $file .tif) ;  mv $file  $TOPO/tiles/elev-stdev_100M_MERIT_$filename.tif ; done ; done


for TOPO in deviation ; do for file in $TOPO/tiles/??_???_???_devi_mag.tif ; do filename=$(basename $file _devi_mag.tif) ;  mv $file  deviation/tiles/dev-magnitute_100M_MERIT_$filename.tif ; done ; done
for TOPO in deviation ; do for file in $TOPO/tiles/??_???_???_devi_sca.tif ; do filename=$(basename $file _devi_sca.tif) ;  mv $file  deviation/tiles/dev-scale_100M_MERIT_$filename.tif ; done ; done


for TOPO in multirough ; do for file in $TOPO/tiles/??_???_???_roug_mag.tif ; do filename=$(basename $file _roug_mag.tif) ;  mv $file multirough/tiles/rough-magnitute_100M_MERIT_$filename.tif ; done ; done
for TOPO in multirough ; do for file in $TOPO/tiles/??_???_???_roug_sca.tif ; do filename=$(basename $file _roug_sca.tif) ;  mv $file multirough/tiles/rough-scale_100M_MERIT_$filename.tif     ; done ; done


for TOPO in forms  ; do for file in $TOPO/tiles/??_???_???.tif ; do filename=$(basename $file .tif) ; echo  mv $file geom/tiles/geom_100M_MERIT_$filename.tif ; done ; done



cd  



