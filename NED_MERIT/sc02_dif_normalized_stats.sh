#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc02_dif_normalized_stats.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc02_dif_normalized_stats.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc02_derivative_stats.sh 

# sbatch /home/fas/sbsc/ga254/scripts/NED_MERIT/sc02_dif_normalized_stats.sh
# module load Apps/R/3.0.3  
module load Apps/R/3.1.1-generic

cd /project/fas/sbsc/ga254/dataproces/NED_MERIT

#   NA_072_048.tif  
#   NA_072_018.tif 

# cat <(echo elevation aspect-cosine aspect-sine eastness northness slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 1 bash -c $' echo $1 $(  pkinfo   -nodata -9999 -stats -i $1/tiles/NA_072_048_dif_norm.tif    )  ' _   ) >  txt/NA_072_048_dif_norm_stats.txt 

# cat <(echo elevation aspect-cosine aspect-sine eastness northness slope dx dxx dxy dy dyy pcurv roughness tcurv tpi tri vrm spi cti convergence | xargs -n 1 -P 1 bash -c $' echo $1 $(  pkinfo   -nodata -9999 -stats -i $1/tiles/NA_072_018_dif_norm.tif    )  ' _   ) >  txt/NA_072_018_dif_norm_stats.txt 

R  --vanilla --no-readline   -q  <<EOF
library(ggplot2) 

NA_072_048 = read.table("txt/NA_072_048_dif_norm_stats.txt")
NA_072_018 = read.table("txt/NA_072_018_dif_norm_stats.txt")

NA_072_018.ord = NA_072_018[NA_072_018$V1=="elevation",]
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="roughness",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="tri",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="tpi",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="vrm",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="cti",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="spi",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="aspect-cosine",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="aspect-sine",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="slope",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="eastness",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="northness",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="pcurv",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="tcurv",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="dx",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="dy",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="dx",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="dyy",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="dxy",] )
NA_072_018.ord = rbind (   NA_072_018.ord ,   NA_072_018[NA_072_018$V1=="convergence",] )

NA_072_048.ord = NA_072_048[NA_072_048$V1=="elevation",]
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="roughness",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="tri",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="tpi",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="vrm",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="cti",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="spi",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="aspect-cosine",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="aspect-sine",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="slope",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="eastness",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="northness",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="pcurv",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="tcurv",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="dx",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="dy",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="dx",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="dyy",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="dxy",] )
NA_072_048.ord = rbind (   NA_072_048.ord ,   NA_072_048[NA_072_048$V1=="convergence",] )

NA_072_048.ord\$ID  = as.numeric(seq(1,20)) 
NA_072_018.ord\$ID  = as.numeric(seq(1,20)) 

pdf( paste ("/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/plot_normalize_equi7.pdf", sep="") , width=8, height=8 )

    pd <- position_dodge(1) # move them .05 to the left and right 

ggplot() +
    geom_line(data = NA_072_048.ord , aes(x=ID , y = V7),  color = "orange") +
    geom_line(data = NA_072_018.ord , aes(x=ID , y = V7), color = "blue" ) +
  geom_errorbar(data = NA_072_048.ord, aes(x=ID , ymin=V7-(V9/2), ymax=V7+(V9/2)), width=0.2 , color = "orange" , position=pd ) + 
  geom_line(position=pd) +  geom_point(position=pd) + 
  geom_errorbar(data = NA_072_018.ord, aes(x=ID , ymin=V7-(V9/2), ymax=V7+(V9/2)), width=0.2 , color = "blue"  , position=pd ) + 
  geom_line(position=pd) +  geom_point(position=pd) +  
  theme(plot.margin = unit(c(1,1,1,1), "cm")) +
  theme(panel.border = element_blank(), panel.grid.minor = element_blank()) +
  theme(axis.text.x = element_text(angle=45 , hjust=1,  size=16 , color="black" )) +
  theme(axis.text.y = element_text( size=16 , color="black")) +
  theme(axis.title.x=element_text(size=20 , vjust=-5 )) +
  theme(axis.title.y=element_text(size=20 , vjust=2 )) +
  scale_x_discrete( limits=seq(1, 20), breaks=seq(1,20) , labels=c("elevation","roughness","tri","tpi","vrm","cti","spi","aspect-cosine","aspect-sine","slope","eastness","northness","pcurv","tcurv","dx","dy","dxx","dyy","dxy","convergence")) + 
  labs(x = "Geomorphometry variables" , y = "Normalized difference" )

dev.off()

EOF



