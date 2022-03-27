#!/bin/bash
#SBATCH -p day
#SBATCH -J sc73_box_plot_ws_bin_areaMap.R.sh
#SBATCH -n 1 -c 1 -N 1
#SBATCH -t 24:00:00
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc73_box_plot_ws_bin_areaMap.R.sh.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc73_box_plot_ws_bin_areaMap.R.sh.%J.err
#SBATCH --mail-user=email
#SBATCH --mem-per-cpu=5000
# sbatch /gpfs/home/fas/sbsc/ga254/scripts/GSHL/sc73_box_plot_ws_bin_areaMap.R.sh

ulimit

find  /dev/shm  -user $USER -mtime +1   2>/dev/null  | xargs -n 1 -P 1 rm -ifr 

export  FIG=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures
export  SCRATCH=/gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country


cd /gpfs/scratch60/fas/sbsc/ga254/dataproces/GSHL/ws_bin_country

module load Apps/R/3.3.2-generic

R --vanilla --no-readline   -q  <<'EOF'


cairo_ps("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area_boxplot.eps" , onefile = FALSE ,  width=8 , height=5   ) 

par ( oma=c(1,0.5,1,1) ,  mar=c(1.5,4,0,0)    ,   mfrow=c(2,1)  ) 


CHN = read.table("ws_areaKM2_CT49.txt") 
CAN = read.table("ws_areaKM2_CT42.txt")
NLD = read.table("ws_areaKM2_CT158.txt")
IND = read.table("ws_areaKM2_CT105.txt") 
ITA = read.table("ws_areaKM2_CT112.txt")
GBR = read.table("ws_areaKM2_CT242.txt")
USA = read.table("ws_areaKM2_CT243.txt")
AUS = read.table("ws_areaKM2_CT15.txt")
EGY = read.table("ws_areaKM2_CT69.txt")
ZAF = read.table("ws_areaKM2_CT211.txt")
PER = read.table("ws_areaKM2_CT178.txt")
PHL = read.table("ws_areaKM2_CT179.txt")

boxplot (log(ITA$V2) , log(GBR$V2)  , log(USA$V2)  , log(NLD$V2)  , log(CAN$V2) , log(CHN$V2) , log(IND$V2) ,  log(AUS$V2) , log(EGY$V2) , log(ZAF$V2) , log(PER$V2) , log(PHL$V2)  ,xaxt = 'n'  , ylab="Watershed-unit area (km2)" , mar=c(2,3,2,2) , yaxt='n' )
axis(1, at=1:12 , labels=F)
axis(2, at=c(0,2.3,6.9,11.51)  ,    labels= c(1,10,1000,"100000"))

CHN = read.table("bin_areaKM2_CT49.txt") 
CAN = read.table("bin_areaKM2_CT42.txt")
NLD = read.table("bin_areaKM2_CT158.txt")
IND = read.table("bin_areaKM2_CT105.txt") 
ITA = read.table("bin_areaKM2_CT112.txt")
GBR = read.table("bin_areaKM2_CT242.txt")
USA = read.table("bin_areaKM2_CT243.txt")
AUS = read.table("bin_areaKM2_CT15.txt")
EGY = read.table("bin_areaKM2_CT69.txt")
ZAF = read.table("bin_areaKM2_CT211.txt")
PER = read.table("bin_areaKM2_CT178.txt")
PHL = read.table("bin_areaKM2_CT179.txt")

boxplot (log(ITA$V2) , log(GBR$V2)  , log(USA$V2)  , log(NLD$V2)  , log(CAN$V2) , log(CHN$V2) , log(IND$V2) ,  log(AUS$V2) , log(EGY$V2) , log(ZAF$V2) , log(PER$V2),  log(PHL$V2) ,  xaxt = 'n'  , xlab="Country"  ,ylab="Bin-unit area (km2)"   , yaxt='n' )
axis(1, at=1:12, labels=c("ITA" , "GBR" , "USA"  , "NLD" , "CAN" ,"CHN" ,"IND" ,   "AUS" , "EGY" , "ZAF" , "PER"  , "PHL")  )
axis(2, at=c(0,2.3,4.6,6.9)  ,    labels= c(1,10,100,1000))
dev.off()
EOF

# log($V2)

# ps2pdf /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area_boxplot.ps /gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area_boxplot.eps

dropbox_uploader.sh upload  "/gpfs/loomis/project/fas/sbsc/ga254/dataproces/GSHL/figures/ws_area_boxplot.eps" "./Apps/Overleaf/Urban Segmentation"
