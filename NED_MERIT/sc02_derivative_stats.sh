#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_derivative_stats.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_derivative_stats.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc02_derivative_stats.sh 

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NED_MERIT/sc02_derivative_stats.sh 

# module load Apps/R/3.0.3  
module load Apps/R/3.1.1-generic

cd /project/fas/sbsc/ga254/dataproces/NED_MERIT

#   NA_072_048.tif  
#   NA_072_018.tif 

# cat <(echo input_tif slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi tci convergence | xargs -n 1 -P 1 bash -c $' echo $1 $(  pkinfo   -nodata -9999 -stats -i $1/tiles/NA_072_048.tif    )  ' _  ; echo  sin cos Nw Ew  | xargs -n 1 -P 1 bash -c $' echo $1 $( pkinfo   -nodata -9999 -stats -i aspect/tiles/NA_072_048_$1.tif ) ' _  ) >  txt/NA_072_048_der_stats.txt 


# cat <(echo input_tif slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi tci convergence | xargs -n 1 -P 1 bash -c $' echo $1 $(  pkinfo   -nodata -9999 -stats -i $1/tiles/NA_072_018.tif   )  ' _  ; echo  sin cos Nw Ew  | xargs -n 1 -P 1 bash -c $' echo $1 $( pkinfo   -nodata -9999 -stats -i aspect/tiles/NA_072_018_$1.tif ) ' _  ) >  txt/NA_072_018_der_stats.txt 



R  --vanilla --no-readline   -q  <<EOF
library(ggplot2) 

NA_072_048 = read.table("txt/NA_072_048_der_stats.txt")
NA_072_018 = read.table("txt/NA_072_018_der_stats.txt")

NA_072_048.ord =   NA_072_048[1,]
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[9,] ) 
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[12,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[11,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[13,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[15,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[14,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[18,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[17,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[2,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[20,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[19,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[8,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[10,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[3,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[6,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[4,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[7,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[5,] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[16,] )


NA_072_018.ord =   NA_072_018[1,]
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[9,] ) 
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[12,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[11,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[13,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[15,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[14,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[18,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[17,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[2,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[20,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[19,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[8,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[10,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[3,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[6,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[4,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[7,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[5,] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[16,] )

NA_072_048.ord\$ID = as.numeric(seq(1,20)) 
NA_072_018.ord\$ID = as.numeric(seq(1,20)) 

pdf( paste ("/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/plot_derivative_equi7.pdf", sep="") , width=8, height=8 )

ggplot() +
    geom_line(data = NA_072_048.ord , aes(x=ID , y = V7),  color = "orange") +
    geom_line(data = NA_072_018.ord , aes(x=ID , y = V7),  color = "blue"  ) +
    geom_errorbar(data = NA_072_048.ord, aes(x=ID , ymin=V7-(V9/2), ymax=V7+(V9/2)), width=0.05 ,  color = "orange") +
    geom_errorbar(data = NA_072_018.ord, aes(x=ID , ymin=V7-(V9/2), ymax=V7+(V9/2)), width=0.05 ,  color = "blue")   +
    theme(plot.margin = unit(c(1,1,1,1), "cm")) +
    theme(panel.border = element_blank(),  panel.grid.minor = element_blank()) +
    theme(axis.text.x = element_text(angle=45 , hjust=1,   size=16 , color="black" ))  +
    theme(axis.text.y = element_text( size=16 , color="black"))  +
    theme(axis.title.x=element_text(size=20 , vjust=-5  )) +
    theme(axis.title.y=element_text(size=20 , vjust=2  )) +
    scale_x_discrete( limits=seq(1, 20),  breaks=seq(1,20) , labels=c("elevation","roughness","tri","tpi","vrm","cti","spi","aspectcosine","aspectsine","slope","eastness","northness","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) + 
    labs(x = "Geomorphometry variables" , y = "First order derivative (degrees)" )

dev.off()

EOF



