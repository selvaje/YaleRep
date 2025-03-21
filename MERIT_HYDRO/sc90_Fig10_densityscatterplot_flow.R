library(fields)
library(data.table)

table=fread("./flow_HYDRO_NHDP_gt1_log.txt" , sep=" " )
colnames(table)[1] = "NHDP"
colnames(table)[2] = "HYDRO"

cr <- colorRampPalette(c("white","blue","green","yellow", "orange" , "red", "brown", "black"))
add_density_legend <- function(){
  xm <- get('xm', envir = parent.frame(1))
  ym <- get('ym', envir = parent.frame(1))
  z  <- get('dens', envir = parent.frame(1))
  colramp <- get('colramp', parent.frame(1))
  fields::image.plot(xm,ym,z, col = colramp(1000), legend.only = T, add =F)
}


pdf("./flow_NHDP_vs_HYDRO.pdf" ,  width=10.8, height=10) 

par(mfrow=c(1, 1), bty='n', mar=c(9, 7, 7, 13.3 ) ) 
smoothScatter(table$NHDP ~ table$HYDRO, nrpoints = 0, nbin=1000, colramp=cr,
              ylab=expression(paste("Hygrography90m flow accumulation (log km"^"2",")")),
	      xlab=expression(paste("NHDPlus HR flow accumulation (log km"^"2",")")),
	      cex=4,  bty='l', cex.axis=1.5, cex.lab=2, mgp = c(3, 1.2, 0),  postPlotHook = add_density_legend , bandwidth = 0.5 , useRaster=TRUE )

axis(4,  at=c(0,4.60,9.2,14.9), labels=c(1,100,10000,3000000) , las=0 ,  cex=3,  bty='l', cex.axis=1.5, cex.lab=2 ,  col="black",col.axis="black")
axis(3,  at=c(0,4.60,9.2,14.9), labels=c(1,100,10000,3000000) , las=0 ,  cex=3,  bty='l', cex.axis=1.5, cex.lab=2 ,  col="black",col.axis="black")

mtext(expression(paste("NHDPlus HR flow accumulation (km"^"2",")"))     , side=3, line=3 , cex=2 ,   las=0 )
mtext(expression(paste("Hygrography90m flow accumulation (km"^"2",")")) , side=4, line=4 , cex=2 ,   las=0 )

text( 19.8 , 15.4 , "Density"   , xpd=T ,  cex=1.5 )

text( 2.15 , 14.8 , "MAD=0.597"   , xpd=NA , cex=2 )
text( 1.85 , 13.8 , "rho=0.709"   , xpd=NA , cex=2 ) 

dev.off()



system("cp flow_NHDP_vs_HYDRO.pdf /home/selv/Dropbox/Apps/Overleaf/Global_hydrographies_at_90m_resolution_new_template/figure")

q()


