#!/bin/bash
#SBATCH -p scavenge 
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc35_arrow_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc35_arrow_plot.R.sh.%J.err
#SBATCH --mail-type=ALL
#SBATCH --mail-user=email
#SBATCH -J sc35_arrow_plot_bin_buf.R.sh

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc35_arrow_plot_bin_buf.R.sh

# module load Apps/R/3.0.3  
module load Apps/R/3.1.1-generic

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin

R  --vanilla --no-readline   -q  <<EOF

library(ggplot2)

BIN="/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin/LST_plot_bin/"
BUF="/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin/LST_plot_buf/"
BINBUF="/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin/LST_plot_bin_buf/"


Madrid.bin  = read.table(paste (BIN,"LST_MOYDmax_Day_value_378441rec_bin_meanLST.txt", sep=""))
London.bin  = read.table(paste (BIN,"LST_MOYDmax_Day_value_371544rec_bin_meanLST.txt", sep="")) 
Birminghan.bin = read.table(paste (BIN,"LST_MOYDmax_Day_value_370731rec_bin_meanLST.txt", sep="")) 
Paris.bin     = read.table(paste (BIN,"LST_MOYDmax_Day_value_373596rec_bin_meanLST.txt", sep="")) 
Lyon.bin      =  read.table(paste (BIN,"LST_MOYDmax_Day_value_375291rec_bin_meanLST.txt", sep=""))       
Barcelona.bin = read.table(paste (BIN,"LST_MOYDmax_Day_value_377588rec_bin_meanLST.txt", sep="")) 
Lisbon.bin    =  read.table(paste (BIN,"LST_MOYDmax_Day_value_379662rec_bin_meanLST.txt", sep="")) 
Milan.bin     =  read.table(paste (BIN,"LST_MOYDmax_Day_value_375468rec_bin_meanLST.txt", sep="")) 
Roma.bin     =   read.table(paste (BIN,"LST_MOYDmax_Day_value_377328rec_bin_meanLST.txt", sep="")) 
Palermo.bin  = read.table(paste (BIN,"LST_MOYDmax_Day_value_380007rec_bin_meanLST.txt", sep="")) 
Athens.bin   =  read.table(paste (BIN,"LST_MOYDmax_Day_value_380044rec_bin_meanLST.txt", sep="")) 
Dusseldorf.bin = read.table(paste (BIN,"LST_MOYDmax_Day_value_371779rec_bin_meanLST.txt", sep="")) 
Munchen.bin   = read.table(paste (BIN,"LST_MOYDmax_Day_value_373976rec_bin_meanLST.txt", sep="")) 
Amsterdam.bin = read.table(paste (BIN,"LST_MOYDmax_Day_value_370773rec_bin_meanLST.txt", sep="")) 



Madrid.buf  = read.table(paste (BUF,"LST_MOYDmax_Day_value_66232_meanLST.txt", sep=""))
London.buf   = read.table(paste (BUF,"LST_MOYDmax_Day_value_17101_meanLST.txt", sep=""))
Birminghan.buf = read.table(paste (BUF,"LST_MOYDmax_Day_value_12288_meanLST.txt", sep=""))
Paris.buf     = read.table(paste (BUF,"LST_MOYDmax_Day_value_32205_meanLST.txt", sep=""))
Lyon.buf      = read.table(paste (BUF,"LST_MOYDmax_Day_value_47150_meanLST.txt", sep=""))
Barcelona.buf  = read.table(paste (BUF,"LST_MOYDmax_Day_value_61362_meanLST.txt", sep=""))
Lisbon.buf    = read.table(paste (BUF,"LST_MOYDmax_Day_value_71506_meanLST.txt", sep=""))
Milan.buf    = read.table(paste (BUF,"LST_MOYDmax_Day_value_48694_meanLST.txt", sep=""))
Roma.buf     = read.table(paste (BUF,"LST_MOYDmax_Day_value_60392_meanLST.txt", sep=""))
Palermo.buf  = read.table(paste (BUF,"LST_MOYDmax_Day_value_74285_meanLST.txt", sep=""))
Athens.buf   = read.table(paste (BUF,"LST_MOYDmax_Day_value_75119_meanLST.txt", sep=""))
Dusseldorf.buf  = read.table(paste (BUF,"LST_MOYDmax_Day_value_18120_meanLST.txt", sep=""))
Munchen.buf   = read.table(paste (BUF,"LST_MOYDmax_Day_value_35520_meanLST.txt", sep=""))
Amsterdam.buf  = read.table(paste (BUF,"LST_MOYDmax_Day_value_13064_meanLST.txt", sep=""))



# Standard error of the mean
# geom_line(data = Madrid.buf, aes(x=V1 , y = V5), color = "red") +

# move position http://www.cookbook-r.com/Graphs/Plotting_means_and_error_bars_(ggplot2)/ 

postscript( paste (BINBUF,"plot_BUF.ps", sep="") , width=4, height=8 , paper="special" ,  horizo=F)

pd <- position_dodge(10) 

#     geom_line(data = Lyon.buf, aes(x=V1 , y = V5),  color = "black") +
#     geom_errorbar(data = Lyon.buf, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "black") +

ggplot() + 
    geom_line(data = London.buf, aes(x=V1 , y = V5),  color = "orange") +
    geom_line(data = Birminghan.buf, aes(x=V1 , y = V5),  color = "green") +
    geom_line(data = Paris.buf, aes(x=V1 , y = V5),  color = "yellow") +
    geom_line(data = Barcelona.buf, aes(x=V1 , y = V5),  color = "grey") +
    geom_line(data = Lisbon.buf, aes(x=V1 , y = V5),  color = "purple") +
    geom_line(data = Milan.buf, aes(x=V1 , y = V5),  color = "blue") +
    geom_line(data = Roma.buf, aes(x=V1 , y = V5),   color = "purple" ,   linetype = "dashed"  ) +
    geom_line(data = Palermo.buf, aes(x=V1 , y = V5),  color = "yellow" , linetype = "dashed"  ) +
    geom_line(data = Athens.buf, aes(x=V1 , y = V5),  color = "green" ,  linetype = "dashed"  ) +
    geom_line(data = Dusseldorf.buf, aes(x=V1 , y = V5),  color = "blue", linetype = "dashed"  ) +
    geom_line(data = Munchen.buf, aes(x=V1 , y = V5),  color = "orange",  linetype  = "dashed" ) +
    geom_line(data = Amsterdam.buf, aes(x=V1 , y = V5),  color = "red" ,  linetype = "longdash") +
    geom_errorbar(data = London.buf, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "orange") +
    geom_errorbar(data = Birminghan.buf, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "green") +
    geom_errorbar(data = Paris.buf, aes(x=V1-0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "yellow") +
    geom_errorbar(data = Barcelona.buf, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "grey") +
    geom_errorbar(data = Lisbon.buf, aes(x=V1+0.2 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "purple") +
    geom_errorbar(data = Milan.buf, aes(x=V1-0.2 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "blue") +
    geom_errorbar(data = Roma.buf, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "purple" ,    linetype = "dashed"   ) +
    geom_errorbar(data = Palermo.buf, aes(x=V1-0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "yellow" , linetype = "dashed"  ) +
    geom_errorbar(data = Athens.buf, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "green" ,  linetype = "dashed"  ) +
    geom_errorbar(data = Dusseldorf.buf, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "blue", linetype = "dashed"  ) +
    geom_errorbar(data = Munchen.buf, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "orange",  linetype  = "dashed" ) +
    geom_errorbar(data = Amsterdam.buf, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=.05 ,  color = "red" ,  linetype = "longdash") +
    annotate("text",  x=9.9, y=London.buf\$V5[10] , label=sprintf("%.2f", mean(London.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Birminghan.buf\$V5[10]-0.4 , label=sprintf("%.2f", mean(Birminghan.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Paris.buf\$V5[10] ,          label=sprintf("%.2f", mean(Paris.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Barcelona.buf\$V5[10] ,      label=sprintf("%.2f", mean(Barcelona.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Lisbon.buf\$V5[10] , label=sprintf("%.2f", mean(Lisbon.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Milan.buf\$V5[10] , label=sprintf("%.2f", mean(Milan.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Roma.buf\$V5[10] , label=sprintf("%.2f", mean(Roma.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Palermo.buf\$V5[10] , label=sprintf("%.2f", mean(Palermo.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Athens.buf\$V5[10] , label=sprintf("%.2f", mean(Athens.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Dusseldorf.buf\$V5[9] , label=sprintf("%.2f", mean(Dusseldorf.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Munchen.buf\$V5[10] , label=sprintf("%.2f", mean(Munchen.buf\$V6)) ) +
    annotate("text",  x=9.9, y=Amsterdam.buf\$V5[9]+0.4 , label=sprintf("%.2f", mean(Amsterdam.buf\$V6)) ) +
    annotate("text",  x=-2,   y=London.buf\$V5[1] , label="London") +
    annotate("text",  x=-2,   y=Birminghan.buf\$V5[1] , label="Birminghan") +
    annotate("text",  x=-2,   y=Paris.buf\$V5[1]-0.3 , label="Paris") +
    annotate("text",  x=-2,   y=Barcelona.buf\$V5[1] , label="Barcelona") +
    annotate("text",  x=-2,   y=Lisbon.buf\$V5[1] , label="Lisbon") +
    annotate("text",  x=-2,   y=Milan.buf\$V5[1] , label="Milan") +
    annotate("text",  x=-2,   y=Roma.buf\$V5[1] , label="Rome") +
    annotate("text",  x=-2,   y=Palermo.buf\$V5[1] , label="Palermo") +
    annotate("text",  x=-2,   y=Athens.buf\$V5[1] , label="Athens") +
    annotate("text",  x=-2,   y=Dusseldorf.buf\$V5[1] , label="Dusseldorf") +
    annotate("text",  x=-2,   y=Munchen.buf\$V5[1]+0.3 , label="Munchen") +
    annotate("text",  x=-2,   y=Amsterdam.buf\$V5[1] , label="Amsterdam") +
    theme(panel.border = element_blank(),  panel.grid.minor = element_blank()) + 
    scale_x_continuous( limits=c(-3, 10) , breaks=seq(0,9) , labels=c(-5,-4,-3,-2,-1,0,1,2,3,4)  ) +
    scale_y_continuous( limits=c(22, 46) , breaks=c(25,30,35,40,45)          ) +
    labs(x = "Buffer-aggregation level (km)" , y = "Land Surface Temperature")

dev.off()

postscript( paste (BINBUF,"plot_BIN.ps", sep="") , width=4, height=8 , paper="special" ,  horizo=F)
ggplot() + 
    geom_line(data = London.bin, aes(x=V1 , y = V5),  color = "orange") +
    geom_line(data = Birminghan.bin, aes(x=V1 , y = V5),  color = "green") +
    geom_line(data = Paris.bin, aes(x=V1 , y = V5),  color = "yellow") +
    geom_line(data = Barcelona.bin, aes(x=V1 , y = V5),  color = "grey") +
    geom_line(data = Lisbon.bin, aes(x=V1 , y = V5),  color = "purple") +
    geom_line(data = Milan.bin, aes(x=V1 , y = V5),  color = "blue") +
    geom_line(data = Roma.bin, aes(x=V1 , y = V5),   color = "purple" ,   linetype = "dashed"  ) +
    geom_line(data = Palermo.bin, aes(x=V1 , y = V5),  color = "yellow" , linetype = "dashed"  ) +
    geom_line(data = Athens.bin, aes(x=V1 , y = V5),  color = "green" ,  linetype = "dashed"  ) +
    geom_line(data = Dusseldorf.bin, aes(x=V1 , y = V5),  color = "blue", linetype = "dashed"  ) +
    geom_line(data = Munchen.bin, aes(x=V1 , y = V5),  color = "orange",  linetype  = "dashed" ) +
    geom_line(data = Amsterdam.bin, aes(x=V1 , y = V5),  color = "red" ,  linetype = "longdash") +
    geom_errorbar(data = London.bin, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "orange") +
    geom_errorbar(data = Birminghan.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "green") +
    geom_errorbar(data = Paris.bin, aes(x=V1-0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "yellow") +
    geom_errorbar(data = Barcelona.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "grey") +
    geom_errorbar(data = Lisbon.bin, aes(x=V1+0.2 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "purple") +
    geom_errorbar(data = Milan.bin, aes(x=V1-0.2 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "blue") +
    geom_errorbar(data = Roma.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "purple" ,    linetype = "dashed"   ) +
    geom_errorbar(data = Palermo.bin, aes(x=V1-0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "yellow" , linetype = "dashed"  ) +
    geom_errorbar(data = Athens.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "green" ,  linetype = "dashed"  ) +
    geom_errorbar(data = Dusseldorf.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "blue", linetype = "dashed"  ) +
    geom_errorbar(data = Munchen.bin, aes(x=V1+0.1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=0.05 ,  color = "orange",  linetype  = "dashed" ) +
    geom_errorbar(data = Amsterdam.bin, aes(x=V1 , ymin=V5-(V6/2), ymax=V5+(V6/2)), width=.05 ,  color = "red" ,  linetype = "longdash") +
    annotate("text",  x=9.9, y=London.bin\$V5[10] , label=sprintf("%.2f", mean(London.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Birminghan.bin\$V5[10] , label=sprintf("%.2f", mean(Birminghan.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Paris.bin\$V5[10] ,          label=sprintf("%.2f", mean(Paris.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Barcelona.bin\$V5[10] ,      label=sprintf("%.2f", mean(Barcelona.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Lisbon.bin\$V5[10] , label=sprintf("%.2f", mean(Lisbon.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Milan.bin\$V5[10]+0.2 , label=sprintf("%.2f", mean(Milan.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Roma.bin\$V5[10] , label=sprintf("%.2f", mean(Roma.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Palermo.bin\$V5[10] , label=sprintf("%.2f", mean(Palermo.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Athens.bin\$V5[10]-0.2 , label=sprintf("%.2f", mean(Athens.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Dusseldorf.bin\$V5[9] , label=sprintf("%.2f", mean(Dusseldorf.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Munchen.bin\$V5[10] , label=sprintf("%.2f", mean(Munchen.bin\$V6)) ) +
    annotate("text",  x=9.9, y=Amsterdam.bin\$V5[9] , label=sprintf("%.2f", mean(Amsterdam.bin\$V6)) ) +
    annotate("text",  x=-2,   y=London.bin\$V5[1] , label="London") +
    annotate("text",  x=-2,   y=Birminghan.bin\$V5[1] , label="Birminghan") +
    annotate("text",  x=-2,   y=Paris.bin\$V5[1] , label="Paris") +
    annotate("text",  x=-2,   y=Barcelona.bin\$V5[1]+0.2 , label="Barcelona") +
    annotate("text",  x=-2,   y=Lisbon.bin\$V5[1]-0.2 , label="Lisbon") +
    annotate("text",  x=-2,   y=Milan.bin\$V5[1]-0.2 , label="Milan") +
    annotate("text",  x=-2,   y=Roma.bin\$V5[1] , label="Rome") +
    annotate("text",  x=-2,   y=Palermo.bin\$V5[1]+0.2 , label="Palermo") +
    annotate("text",  x=-2,   y=Athens.bin\$V5[1] , label="Athens") +
    annotate("text",  x=-2,   y=Dusseldorf.bin\$V5[1] , label="Dusseldorf") +
    annotate("text",  x=-2,   y=Munchen.bin\$V5[1] , label="Munchen") +
    annotate("text",  x=-2,   y=Amsterdam.bin\$V5[1] , label="Amsterdam") +
    theme(panel.border = element_blank(),  panel.grid.minor = element_blank()) + 
    scale_x_continuous( limits=c(-3, 10) , breaks=seq(0, 9, 1)  ) +
    scale_y_continuous( limits=c(22, 46) , breaks=c(25,30,35,40,45)          ) +
    labs(x = "Bin-aggregation level" , y = "Land Surface Temperature")
dev.off()
   
EOF

cd LST_plot_bin_buf

ps2epsi plot_BUF.ps  plot_BUF.eps
ps2epsi plot_BIN.ps  plot_BIN.eps
