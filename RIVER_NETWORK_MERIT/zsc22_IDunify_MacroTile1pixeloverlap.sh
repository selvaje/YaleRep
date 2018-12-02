#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 10:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc22_IDunify_MacroTile1pixeloverlap.sh.%J.out 
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc22_IDunify_MacroTile1pixeloverlap.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH --job-name=sc22_IDunify_MacroTile1pixeloverlap.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/RIVER_NETWORK_MERIT/sc22_IDunify_MacroTile1pixeloverlap.sh

find  /tmp/     -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  
find  /dev/shm  -user $USER  -mtime +2  2>/dev/null  | xargs -n 1 -P 1 rm -ifr  

# Upper Left  (-180.0000000,  85.0000000) (180d 0' 0.00"W, 85d 0' 0.00"N)
# Lower Left  (-180.0000000, -60.0000000) (180d 0' 0.00"W, 60d 0' 0.00"S)
# Upper Right ( 180.0000000,  85.0000000) (180d 0' 0.00"E, 85d 0' 0.00"N)
# Lower Right ( 180.0000000, -60.0000000) (180d 0' 0.00"E, 60d 0' 0.00"S)

export DIR=/project/fas/sbsc/ga254/dataproces/GEO_AREA/tile_files
export RAM=/dev/shm
export INDIR=/gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_1pixel_reclass 
export ORIZ=$INDIR/../lbasin_tiles_1pixel_reclass_oriz_stripe
export VERT=$INDIR/../lbasin_tiles_1pixel_reclass_vert_stripe

paste <(awk '{ if ($4==-140) print $1}' $DIR/tile_lat_long_40d_MERIT_noheader.txt) <(awk '{ if ($2==-140) print $1}' $DIR/tile_lat_long_40d_MERIT_noheader.txt) > $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt

paste <(awk '{ if ($4==-100) print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==-100) print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt) >> $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==-60)  print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==-60) print $1  }'   $DIR/tile_lat_long_40d_MERIT_noheader.txt) >> $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==-20)  print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==-20) print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  >>  $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==20)   print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==20) print $1  }'    $DIR/tile_lat_long_40d_MERIT_noheader.txt) >>  $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==60)   print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==60) print $1  }'    $DIR/tile_lat_long_40d_MERIT_noheader.txt) >>  $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==100)  print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==100) print $1  }'   $DIR/tile_lat_long_40d_MERIT_noheader.txt) >>  $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 
paste <(awk '{ if ($4==140)  print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($2==140) print $1  }'   $DIR/tile_lat_long_40d_MERIT_noheader.txt) >> $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt 

paste <(awk '{ if ($5==45)  print $1 }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($3==45) print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)   >  $DIR/tile_lat_long_40d_MERIT_noheader_orizontal_stripe.txt 
paste <(awk '{ if ($5==5)   print $1 }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($3==5)  print $1  }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)   >>  $DIR/tile_lat_long_40d_MERIT_noheader_orizontal_stripe.txt 
paste <(awk '{ if ($5==-35) print $1 }'  $DIR/tile_lat_long_40d_MERIT_noheader.txt)  <(awk '{ if ($3==-35) print $1  }' $DIR/tile_lat_long_40d_MERIT_noheader.txt) >>  $DIR/tile_lat_long_40d_MERIT_noheader_orizontal_stripe.txt 

MAX=$(pkstat -max -i /gpfs/scratch60/fas/sbsc/ga254/dataproces/RIVER_NETWORK_MERIT/lbasin_tiles_1pixel_reclass/lbasin_h08v03.tif  | awk ' { print $2  }' )

cat  $DIR/tile_lat_long_40d_MERIT_noheader_vertical_stripe.txt | head -1  | xargs -n 2 -P 1 bash -c  $'      
LEFT=$1
RIGH=$2

echo convert to asc file 
gdal_translate -of AAIGrid -srcwin $(pkinfo -ns -i $INDIR/lbasin_$LEFT.tif | awk \'{print $2 - 1}\') 0 1 $(pkinfo -nl -i $INDIR/lbasin_$LEFT.tif | awk \'{print $2 }\'  ) $INDIR/lbasin_$LEFT.tif $RAM/lbasin_left${LEFT}_stripe.asc

gdal_translate -of AAIGrid -srcwin 0 0 1 $( pkinfo -nl -i $INDIR/lbasin_$RIGH.tif | awk \'{ print $2 }\')  $INDIR/lbasin_$RIGH.tif $RAM/lbasin_righ${RIGH}_stripe.asc

echo merge the ${LEFT} ${RIGH} stripe
paste <(awk \'{if(NR>6) print}\' $RAM/lbasin_left${LEFT}_stripe.asc) <(awk \'{if(NR>6) print}\' $RAM/lbasin_righ${RIGH}_stripe.asc ) | uniq | sort -k 1 -g  | uniq  > $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe.txt

echo uniq new id 
awk -v MAX=$MAX  \'{ if($1 == 0) { print $1 , $2 , 0  ;  old1 = $1  ;  old2 = $2 ; nobs = (MAX + 1) }
	    else{
	        if (NR == 0 ) { old1 = $1 ; old2 = $2 ; nobs = (MAX + 1) }
		    if($1 == old1 || $2 == old2  ){ print $1 , $2 , nobs }
                      else { nobs++ ;  print $1 , $2 , nobs ; old1 = $1 ; old2 = $2 }
	    }
}\' $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe.txt >  $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe_reclas.txt

MAX=$( awk \'END{ print $3 }\' $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe_reclas.txt )

echo join 
join -a 2 -1 1 -2 1 <(pkstat -hist -i $INDIR/lbasin_$LEFT.tif | awk \'{ if ($2 != 0) print $1 }\' | sort )  <( awk \'{ print $1 , $3 }\'  $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe_reclas.txt | sort ) |  awk \'{ if (NF==1) { print $1 , $1 } else { print $1 , $2   }  }\'  > $RAM/lbasin_left${LEFT}_stripe_reclas.txt

join -a 2 -1 1 -2 1 <(pkstat -hist -i $INDIR/lbasin_$RIGH.tif | awk \'{ if ($2 != 0) print $1 }\' | sort )  <( awk \'{ print $2 , $3 }\'  $RAM/lbasin_left${LEFT}_righ${RIGH}_stripe_reclas.txt | sort ) |  awk \'{ if (NF==1) { print $1 , $1 } else { print $1 , $2   }  }\'  > $RAM/lbasin_righ${RIGH}_stripe_reclas.txt

pkreclass -ot UInt32 -code $RAM/lbasin_left${LEFT}_stripe_reclas.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $INDIR/lbasin_$LEFT.tif -o $VERT/lbasin_$LEFT.tif 
pkreclass -ot UInt32 -code $RAM/lbasin_righ${RIGH}_stripe_reclas.txt -co COMPRESS=DEFLATE -co ZLEVEL=9 -i $INDIR/lbasin_$RIGH.tif -o $VERT/lbasin_$RIGH.tif 

' _ 


