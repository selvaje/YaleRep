#!/bin/bash
#SBATCH -p day
#SBATCH -n 1 -c 1 -N 1 
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc31_arrow_plot.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc31_arrow_plot.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH -J sc31_arrow_plot.R.sh

# sbatch   /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc31_arrow_plot.R.sh

module load Apps/R/3.0.3

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/GHS_BUILT_LDS2014_GLOBE_R2016A_54009_1k_v1_0_lst_ws_bin

# R  --vanilla --no-readline   -q  <<EOF

library(plotrix)


files <- list.files(pattern = ".txt")

for (i in seq_along(files)) {

    assign(paste("Df", i, sep = "."), read.csv(files[i]))

    assign(paste(paste("Df", i, sep = ""), "summary", sep = "."), 

}






b = read.table("LST_MOYDmax_Day_value_369258rec_bin_meanLST.txt" , header=F) 
a = read.table("LST_MOYDmax_Day_value_369222rec_bin_meanLST.txt" , header=F) 

y=seq(10,40)
x=seq(0,9)


xydist<-sqrt(y*y+x*x)
plot(a$V1,a$V5,main="LST increment vs build up",xlab="X",ylab="Y",type="n",  xmax=9, xmin=0, ymax=40, ymin=10)
color.scale.lines(a$V1,a$V5,c(1,1,0),0,c(0,1,1),colvar=xydist,lwd=2)



lines(b$V1,b$V5,xlab="X",ylab="Y",type="n" ,  xlim=c(0,9) , ylim=c(10,40)   )


color.scale.lines(b$V1,b$V5,c(1,1,0),0,c(0,1,1),colvar=xydist,lwd=2)


# EOF
