# https://ragrawal.wordpress.com/2011/05/16/visualizing-confusion-matrix-in-r/
cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces


for tile in n45w120 n40w100 ; do 

export tile 
# pkdiff     -cm     -ref   NED/forms/tiles/$tile.tif  -i    MERIT/forms/tiles/${tile}_dem.tif    -cmo NED_MERIT/confusion/${tile}.txt

# pkstat -hist2d -i   NED/forms/tiles/$tile.tif  -i    MERIT/forms/tiles/${tile}_dem.tif |  awk '{ if (NF==3) print   }'   > NED_MERIT/confusion/${tile}_hist2d.txt  # confusion 
# pkstat -hist  -i    NED/forms/tiles/$tile.tif                                                                            > NED_MERIT/confusion/${tile}_hist.txt    # actual 



module load Apps/R/3.3.2-generic


R --vanilla --no-readline -q  << 'EOF'
library (ggplot2)


tile  <- Sys.getenv(c('tile'))

class=c("flat","peak","ridge","shoulder","spur","slope","hollow","footslope","valley","pit" )

actual     = read.table(paste0("NED_MERIT/confusion/",tile,"_hist.txt"))
names(actual) = c("Actual","ActualFreq")

actual$actual_class  =  class 

confusion =  read.table(paste0("NED_MERIT/confusion/",tile,"_hist2d.txt"))
names(confusion) = c("Actual","Predicted","Freq")

confusion$predicted_class = c(class)

#calculate percentage of test cases based on actual frequency
confusion = merge(confusion, actual, by=c("Actual"))
confusion$Percent = confusion$Freq/confusion$ActualFreq*100


pdf(paste0("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/confusion_matrix_",tile,".pdf") , width=9.7, height=8   )
 
#render plot
# we use three different layers
# first we draw tiles and fill color based on percentage of test cases

tile <- ggplot() +
geom_tile(aes(x=actual_class, y=predicted_class,fill=Percent), data=confusion, color="black", size=0.1) +
labs(x="NED geomorphologic forms", y="MERIT geomorphologic forms\n" ) + 
theme(plot.margin = unit(c(1,1,1,1), "cm")) +
theme(axis.text.y=element_text(size=18 , color="black" )) +
theme(axis.text.x=element_text( angle = 45 , hjust=1  , size=18 , color="black" )) +
theme(axis.title.x=element_text(vjust=-4 , size=20)) +
theme(axis.title.y=element_text(size=20)) +
theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    panel.background = element_blank()) +
theme( legend.title=element_text(size=18), legend.text=element_text(size=16))

tile = tile + 
geom_text(aes(x=Actual,y=Predicted, label=sprintf("%.1f", Percent)),data=confusion, size=5, colour="black") +
scale_fill_gradient(low="grey",high="red")

# lastly we draw diagonal tiles. We use alpha = 0 so as not to hide previous layers but use size=0.3 to highlight border
tile = tile + 
geom_tile(aes(x=Actual,y=Predicted),data=subset(confusion, as.character(Actual)==as.character(Predicted)), color="blue",size=0.6, fill="black", alpha=0) 
 
#render
tile

dev.off()

EOF

done 

