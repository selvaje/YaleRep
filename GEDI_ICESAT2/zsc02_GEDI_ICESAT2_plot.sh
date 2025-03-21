#!/bin/bash

#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 1:00:00       # 
#SBATCH -o /gpfs/gibbs/pi/hydro/hydro/stdout1/sc02_GEDI_ICESAT2_plot.sh.%J.out
#SBATCH -e /gpfs/gibbs/pi/hydro/hydro/stderr1/sc02_GEDI_ICESAT2_plot.sh.%J.err
#SBATCH --job-name=sc02_GEDI_ICESAT2_plot.sh
#SBATCH --mem=2G
### -p scavenge

### for NUM in 70 75 80 85 90 95 ; do sbatch --export=DIR=icesat2_${NUM} /gpfs/gibbs/pi/hydro/hydro/scripts/GEDI_ICESAT2/sc02_GEDI_ICESAT2_plot.sh ; done

find  /tmp/       -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  
find  /dev/shm/   -user $USER  -mtime +3  2>/dev/null  | xargs -n 1 -P 2 rm -ifr  

export RAM=/dev/shm
export labely="All Filtered"

export TXT=/gpfs/gibbs/pi/hydro/hydro/dataproces/GEDI_ICESAT2/overlay_txt/${DIR}
mkdir -p $TXT

cat $TXT/filter_*.txt >  $TXT/af_${DIR}_4plot.txt

cat $TXT/filter_*.txt | awk '{if ($1>3 && $2>3) print}' > $TXT/af_${DIR}_over3m_4plot.txt

cd $TXT

# module load R/3.4.4-foss-2018a-X11-20180131 
module load R/4.0.3-foss-2020b

R  --vanilla --no-readline   -q  <<'EOF'
library(ggplot2) 
library(RColorBrewer)
library(viridisLite)
library(viridis)
library(ggpubr)
# library(extrafont)
# library(ggpmisc)
# loadfonts(device="win")   

rm(list=ls())

setwd('C:/Users/tangzhi/Downloads/tree_height_mapping/ggplot_scatter')
#labely = Sys.getenv('labely')
labely <- c('Others')
font_ty <- c("Times New Roman")

plot_file <- list.files(, pattern = 'over3m_4plot.txt')
plot_table <- read.table(plot_file)

# names(plot_table) = c("All filtered", substr(plot_file, 4, 5) )
names(plot_table) = c("All filtered", labely  )

lm_eqn <- function(df){
  m <- lm(y ~ x, df);
  eq <- substitute(italic(y) == a + b %.% italic(x)*","~~italic(r)^2~"="~r2, 
                   list(a = format(unname(coef(m)[1]), digits = 2),
                        b = format(unname(coef(m)[2]), digits = 2),
                        r2 = format(summary(m)$r.squared, digits = 3)))
  as.character(as.expression(eq));
}

get_accuracy <- function(plot_table) {
  
  fit <- plot_table[,1]
  obs <- plot_table[,2]
  res_df <- data.frame(RMSE = numeric(0),rRMSE = numeric(0),r2 = numeric(0))
  colnames(res_df) <- c('RMSE', 'rRMSE', 'r2')
  
  
  model1 <- lm(fit ~ obs)
  summary(model1)
  r2  <- summary(model1)$adj.r.squared
  
  res_i <- abs(fit - obs)
  RMSE <- sqrt(sum(res_i^2)/length(res_i))
  RMSE_per <- RMSE/ mean(obs, na.rm=TRUE) *100
  
  res_df[ 1, 'RMSE'] <- as.numeric(format(RMSE,dig=2))
  res_df[ 1, 'rRMSE'] <- as.numeric(round(RMSE_per,1))
  res_df[ 1, 'r2'] <- as.numeric(format(r2, dig=2))
  return(res_df)
}

energy_density <- function(plot_table) {
  
  fit <- plot_table[,1]
  obs <- plot_table[,2]
  
  res_df <- get_accuracy(plot_table)

  ## add the RMSE and R2 between 0-20 m and larger than 20 m
  sep_height <- 15 # seperate tree height is 20 m
  plot_LT20 <- plot_table[plot_table[,2] <= sep_height,]
  plot_GT20 <- plot_table[plot_table[,2] > sep_height,]
  
  res_df_LT20 <- get_accuracy(plot_LT20)
  res_df_GT20 <- get_accuracy(plot_GT20)
  
  format_accuracy <- function(res_df) {
  rp = vector('expression',2)
  RMSE <- res_df[1, 1]
  r2 <- res_df[1, 3]
  
  rp[1] = substitute(expression(RMSE == MYRMSEPerVALUE), 
                     list(MYRMSEPerVALUE = format(round(RMSE, 3), nsmall = 1)))[2] 
  rp[2] = substitute(expression(italic(R)^2 == MYVALUE), 
                     list(MYVALUE = format(round(r2, 2), nsmall = 2)))[2]
  return(rp)
}
  
  rp <- format_accuracy(res_df)
  rp_LT20 <- format_accuracy(res_df_LT20)
  rp_GT20 <- format_accuracy(res_df_GT20)
  
  i=1
  xlim_max <- 80
  
  { rp = vector('expression',2)
    RMSE <- res_df[i, 1]
    r2 <- res_df[i, 3]
    
    rp[1] = substitute(expression(RMSE == MYRMSEPerVALUE), 
                       list(MYRMSEPerVALUE = format(round(RMSE, 3), nsmall = 1)))[2] 
    rp[2] = substitute(expression(italic(R)^2 == MYVALUE), 
                       list(MYVALUE = format(round(r2, 2), nsmall = 2)))[2]
    
    y <- fit
    x <- obs
    
    df <- data.frame(x = x, y = y, d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(7, end = 3/5)))))
    ggplot( data = df   , aes(x = x , y = y)) + 
      geom_point(aes(x, y, col = d), size = 0.1) +
      geom_abline(intercept = 0, slope = 1, color="black", linetype = "dashed", size=0.2 ) +
      # geom_smooth(method = "lm", se = FALSE, formula=y ~ x, xseq = seq(0,xlim_max, length=8), size=0.2)  +
      stat_smooth(method = "lm", formula = y ~ x) +
      stat_regline_equation(
        aes(label =  paste(..eq.label.., sep = "~~~~")),
        formula = y ~ x ,
        size = 5
      ) +
      xlim(3, xlim_max) +
      ylim(3, xlim_max) + 
      scale_color_identity() +
      labs(x = "All filtered",y = labely )  + 
      theme(axis.text.x=element_text(size=0.3),axis.text.y=element_text(size=0.3)) +
      theme_classic(base_size = 20) +
      ggtitle("") +
      #theme(text=element_text(family=font_ty)) +
      annotate("text", label = rp[1], x = (xlim_max*0.5), y = 0.97*xlim_max, size = 5) +
      annotate("text", label = rp[2], x = (xlim_max*0.75), y = 0.97*xlim_max, size = 5) +
      annotate("text", label = c('H=20m: '), x = (xlim_max*0.13), y = 0.9*xlim_max, size = 5) +
      annotate("text", label = rp_LT20[1], x = (xlim_max*0.35), y = 0.9*xlim_max, size = 5) +
      annotate("text", label = rp_LT20[2], x = (xlim_max*0.6), y = 0.9*xlim_max, size = 5) +
      annotate("text", label = c('H>20m: '), x = (xlim_max*0.13), y = 0.83*xlim_max, size = 5) +
      annotate("text", label = rp_GT20[1], x = (xlim_max*0.35), y = 0.83*xlim_max, size = 5) +
      annotate("text", label = rp_GT20[2], x = (xlim_max*0.6), y = 0.83*xlim_max, size = 5)
      
    }
  
  
  ## ggsave("energy_den.jpg",fig, width = 15, height = 15, units = 'in')  
  
}


pdf( 'tree_height_over3m4.pdf', width=5, height=5)
#par(mar=c(5,5,1,1))
energy_density(plot_table)

dev.off()


EOF
