



echo elevation aspect-cosine aspect-sine eastness northness slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 1 bash -c $' 
pksetmask -m $1/tiles/NA_066_048_dif_norm.tif  -msknodata 0 -nodata 0 -p ">"  -i $1/tiles/NA_066_048_dif_norm.tif  -o $1/tiles/NA_066_048_dif_neg_norm_msk.tif &>/dev/null
pksetmask -m $1/tiles/NA_066_048_dif_norm.tif  -msknodata 0 -nodata 0 -p "<"  -i $1/tiles/NA_066_048_dif_norm.tif  -o $1/tiles/NA_066_048_dif_pos_norm_msk.tif &>/dev/null

echo $1 $( pkinfo -nodata 0 -stats -i $1/tiles/NA_066_048_dif_neg_norm_msk.tif)  $( pkinfo -nodata 0 -stats -i $1/tiles/NA_066_048_dif_pos_norm_msk.tif) 
' _   > NA_066_048_dif_norm_stats_pos-neg.txt


