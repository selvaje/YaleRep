#!/bin/bash
#SBATCH -p scavenge
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 2:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/zt226/stdout/sc06_GEDI_ICESAT2_plot_new_usa.sh.%A_%a.out  
#SBATCH -e /gpfs/scratch60/fas/sbsc/zt226/stderr/sc06_GEDI_ICESAT2_plot_new_usa.sh.%A_%a.err
#SBATCH --mem=30G
#SBATCH --array=66
#SBATCH --job-name=sc06_GEDI_ICESAT2_plot_new_usa.sh
ulimit -c 0

#### sbatch /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc06_GEDI_ICESAT2_plot_new_usa.sh

export RH=$SLURM_ARRAY_TASK_ID
# export RH=70
export RAM=/dev/shm
export labely="All Filtered"
export DIR=icesat2_$RH
export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt_usa/${DIR}
mkdir -p $TXT

# cat $TXT/filter_*.txt >  $TXT/af_${DIR}_4plot.txt

cat $TXT/filter_*slope.txt | awk '{if ($1>3 && $2>3) print}' > $TXT/af_${DIR}_over3m_4plot.txt

cd $TXT

module load R/3.5.3-foss-2018a-X11-20180131

R  --vanilla --no-readline   -q  <<'EOF'

RH <- Sys.getenv(c('RH'))

## ...  in your ~/R library repository ...
## install.packages("fields",dependence=T)  
## install.packages("data.table",dependence=T)  
## install.packages("zyp",dependence=T)  
## install.packages("mblm",dependence=T)  

library(fields)  ; library(data.table) ; library(mblm)  
## library(zyp)

cr <- colorRampPalette(c("white","blue","green","yellow", "orange" , "red", "brown", "black"))
add_density_legend <- function(){
  xm <- get('xm', envir = parent.frame(1))
  ym <- get('ym', envir = parent.frame(1))
  z  <- get('dens', envir = parent.frame(1))
  colramp <- get('colramp', parent.frame(1))
  fields::image.plot(xm,ym,z, col = colramp(1000), legend.only = T, add =F)
}

get_accuracy <- function(plot_table) {
  fit <- plot_table[[1]]      
  obs <- plot_table[[2]]
  res_df <- data.frame(RMSE = numeric(0),rRMSE = numeric(0),r2 = numeric(0), r = numeric(0) ,  MAD = numeric(0),rho = numeric(0))
        
  colnames(res_df) <- c('RMSE', 'rRMSE', 'r2', 'r', 'MAD', 'rho')      
  model1 <- lm(fit ~ obs)                                                                                                                       
  summary(model1)
  r2  <- summary(model1)$adj.r.squared                                                                                            
  
  res_i <- abs(fit - obs)                                                                                                                   
  RMSE <- sqrt(sum(res_i^2)/length(res_i))                                                     
  RMSE_per <- RMSE/ mean(obs, na.rm=TRUE) *100                                                                             
  MAD = round(mad(res_i), 3)
  rho = cor.test(fit, obs, method = 'spearman', exact=FALSE)
  rho = round(as.numeric(rho$estimate), 3)

  r = cor.test(fit, obs, method = 'pearson', exact=FALSE)
  r = round(as.numeric(r$estimate), 3)

  res_df[1, 'RMSE']  <- as.numeric(format(RMSE,dig=2))                                                                                                     
  res_df[1, 'rRMSE'] <- as.numeric(round(RMSE_per,1))                                                                                                     
  res_df[1, 'r']     <- as.numeric(format(r, dig=3))                                 
  res_df[1, 'MAD'] = MAD
  res_df[1, 'rho'] = rho

  return(res_df)
}

table=fread(paste0("/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt/icesat2_",RH,"/af_icesat2_",RH,"_over3m_4plot.txt") , sep=" " )
colnames(table)[1] = "ICESAT"
colnames(table)[2] = "GEDI"
get_accu = get_accuracy(table)

model1 <- lm(table$ICESAT ~ table$GEDI)


# sample 
the_sample = sample(nrow(table), 2000)
model_Theil_Sen_mblm  <- mblm(ICESAT~GEDI , dataframe=table[the_sample,])        


#  model_Theil-Sen_zyp   <- zyp.sen(ICESAT~GEDI , data=table)        
pdf(paste0("/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt/af_icesat2_",RH,"_over3m_4plot.pdf"), width=10.8, height=10) 

par(mfrow=c(1, 1), bty='n', mar=c(7, 7, 7, 6.8) ) 
smoothScatter(table$ICESAT ~ table$GEDI, nrpoints = 0, nbin=500, colramp=cr,
              ylab="GEDI",
	      xlab="ICESAT",
	      cex=4,  bty='n', xlim=c(0,80), ylim=c(0,80), 
              cex.axis=1.5, cex.lab=2, mgp = c(2, 0.5, -1.2),  postPlotHook = add_density_legend , bandwidth = 1 , useRaster=TRUE )

# axis(4,  at=c(0,4.60,9.2,14.9), labels=c(1,100,10000,3000000) , las=0 ,  cex=3,  bty='l', cex.axis=1.5, cex.lab=2 ,  col="black",col.axis="black")
# axis(3,  at=c(0,4.60,9.2,14.9), labels=c(1,100,10000,3000000) , las=0 ,  cex=3,  bty='l', cex.axis=1.5, cex.lab=2 ,  col="black",col.axis="black")
# mtext(expression(paste("ICESAT-2 (m"^"2",")"))     , side=3, line=3 , cex=2 ,   las=0 )
# mtext(expression(paste("GEDI (km"^"2",")")) , side=4, line=4 , cex=2 ,   las=0 )
# text( 19.8 , 15.4 , "Density"   , xpd=T ,  cex=1.5 )

abline(a = 0, b = 1, col="black" , lwd=2)
# abline(model1,         col="purple" , lwd=3)   
abline(model_Theil_Sen_mblm, col="brown" , lwd=3)   
# abline(model_Theil_Sen_zyp , col="red" , lwd=3)   


text( 5, 86.8 , paste0("MAD=", get_accu[1, 5]), xpd=NA , cex=2, pos=4 )
text( 5, 81.8 , paste0("rho=", get_accu[1, 6]), xpd=NA , cex=2, pos=4 ) 
text( 5, 76.8 , paste0("RMSE=",get_accu[1, 1]), xpd=NA , cex=2, pos=4 )
# text( 5, 71.8 , paste0(expression(italic(R)^2 ==),get_accu[1, 3]), xpd=NA , cex=2, pos=4 ) 
text( 5, 71.8 , paste0("R=", get_accu[1, 4])  , xpd=NA , cex=2, pos=4 ) 

dev.off()

print(summary(model_Theil_Sen))

q()

EOF

# system("cp flow_NHDP_vs_HYDRO.pdf /home/selv/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure")
