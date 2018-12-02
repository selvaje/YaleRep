# https://ragrawal.wordpress.com/2011/05/16/visualizing-confusion-matrix-in-r/
cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces


tile=NA_078_036

export tile 

gdal_translate -projwin     $( getCorners4Gtranslate $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif )     NED/forms/tiles/${tile}.tif /tmp/${tile}_tmp.tif 
gdal_edit.py    -a_ullr     $( getCorners4Gtranslate $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif )    /tmp/${tile}_tmp.tif 

gdal_translate -srcwin 0 0 3000 3000 /tmp/${tile}_tmp.tif   /tmp/${tile}.tif 
gdal_translate -srcwin 0 0 3000 3000 $PR/MERIT/geom/tiles/geom_100M_MERIT_NA_078_036.tif    /dev/shm/${tile}.tif 

# pkdiff  -nodata 0  -cm  -ref   /tmp/$tile.tif  -i  /dev/shm/${tile}.tif    -cmo NED_MERIT/confusion/${tile}.txt

# pkstat  -nodata 0  -hist2d -i   /tmp/$tile.tif  -i /dev/shm/${tile}.tif |  awk '{ if (NF==3) print   }'   > NED_MERIT/confusion/${tile}_hist2d.txt  # confusion 
# pkstat  -nodata 0  -hist   -i   /tmp/$tile.tif                                                            > NED_MERIT/confusion/${tile}_hist.txt    # actual 


gdal_translate -of XYZ   /tmp/${tile}.tif       /tmp/geom_100M_NED_NA_078_036.txt 
gdal_translate -of XYZ   /dev/shm/${tile}.tif   /dev/shm/geom_100M_MERIT_NA_078_036.txt 

paste -d " "  <( awk '{  print $3  }'   /tmp/geom_100M_NED_NA_078_036.txt  )   <(  awk '{ print $3  }'    /dev/shm/geom_100M_MERIT_NA_078_036.txt ) >  /dev/shm/geom_NED_MERIT.txt 



module load Apps/R/3.3.2-generic

R --vanilla --no-readline -q  << 'EOF'
library (ggplot2)
library (ggcorrplot)


ggcorrplot2 = function (corr, method = c("square", "circle"), type = c("full", 
                                                         "lower", "upper"), ggtheme = ggplot2::theme_minimal, title = "", 
          show.legend = TRUE, legend.title = "Corr", show.diag = FALSE, 
          colors = c("blue", "white", "red"), outline.color = "gray", 
          hc.order = FALSE, hc.method = "complete", lab = FALSE, lab_col = "black", 
          lab_size = 4, p.mat = NULL, sig.level = 0.05, insig = c("pch", 
                                                                  "blank"), pch = 4, pch.col = "black", pch.cex = 5, tl.cex = 12, 
          tl.col = "black", tl.srt = 45, digits = 2) 
{
  type <- match.arg(type)
  method <- match.arg(method)
  insig <- match.arg(insig)
  if (!is.matrix(corr) & !is.data.frame(corr)) {
    stop("Need a matrix or data frame!")
  }
  corr <- as.matrix(corr)
  corr <- base::round(x = corr, digits = digits)
  if (hc.order) {
    ord <- .hc_cormat_order(corr)
    corr <- corr[ord, ord]
    if (!is.null(p.mat)) {
      p.mat <- p.mat[ord, ord]
      p.mat <- base::round(x = p.mat, digits = digits)
    }
  }
  if (type == "lower") {
    corr <- .get_lower_tri(corr, show.diag)
    p.mat <- .get_lower_tri(p.mat, show.diag)
  }
  else if (type == "upper") {
    corr <- .get_upper_tri(corr, show.diag)
    p.mat <- .get_upper_tri(p.mat, show.diag)
  }
  corr <- reshape2::melt(corr, na.rm = TRUE)
  colnames(corr) <- c("Var1", "Var2", "value")
  corr$pvalue <- rep(NA, nrow(corr))
  corr$signif <- rep(NA, nrow(corr))
  if (!is.null(p.mat)) {
    p.mat <- reshape2::melt(p.mat, na.rm = TRUE)
    corr$coef <- corr$value
    corr$pvalue <- p.mat$value
    corr$signif <- as.numeric(p.mat$value <= sig.level)
    p.mat <- subset(p.mat, p.mat$value > sig.level)
    if (insig == "blank") {
      corr$value <- corr$value * corr$signif
    }
  }
  corr$abs_corr <- abs(corr$value) * 10
  p <- ggplot2::ggplot(corr, ggplot2::aes_string("Var1", "Var2", 
                                                 fill = "value"))
  if (method == "square") {
    p <- p + ggplot2::geom_tile(color = outline.color)
  }
  else if (method == "circle") {
    p <- p + ggplot2::geom_point(color = outline.color, shape = 21, 
                                 ggplot2::aes_string(size = "abs_corr")) + ggplot2::scale_size(range = c(4, 
                                                                                                         10)) + ggplot2::guides(size = FALSE)
  }
  p <- p + ggplot2::scale_fill_gradient2(low = colors[1], high = colors[3], 
                                         mid = colors[2], midpoint = 0, limit = c(-1, 1), space = "Lab", 
                                         name = legend.title)
  if (class(ggtheme)[[1]] == "function") {
    p <- p + ggtheme()
  }
  else if (class(ggtheme)[[1]] == "theme") {
    p <- p + ggtheme
  }
  p <- p + ggplot2::theme(axis.text.x = ggplot2::element_text(angle = tl.srt, 
                                                              vjust = 1, size = tl.cex, hjust = 1), axis.text.y = ggplot2::element_text(size = tl.cex)) + 
    ggplot2::coord_fixed()
  label <- round(corr[, "value"], 4) * 100    # multiplication for the label 
  if (lab) {
    p <- p + ggplot2::geom_text(ggplot2::aes_string("Var1", 
                                                    "Var2"), label = label, color = lab_col, size = lab_size)
  }
  if (!is.null(p.mat) & insig == "pch") {
    p <- p + ggplot2::geom_point(data = p.mat, ggplot2::aes_string("Var1", 
                                                                   "Var2"), shape = pch, size = pch.cex, color = pch.col)
  }
  if (title != "") {
    p <- p + ggplot2::ggtitle(title)
  }
  if (!show.legend) {
    p <- p + ggplot2::theme(legend.position = "none")
  }
  p <- p 
  p
}


table = read.table("/dev/shm/geom_NED_MERIT.txt")

pdf("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NED_MERIT/figure/confusion_plots_ggcorr.pdf" , width=11.5, height=10   )




# P=c(1,1,1,1,1)     # for P label in the x  
# T=c(1,1,1,2,2)     # for T lable in the y 
# table= table(P,T)
# rownames(table)  = c("unoR","dueR")
# colnames(table)  = c("unoC","dueC")
# ggcorrplot(table , lab= TRUE   ) 

# P rappresented in the X 
# T rappresented in the Y



accuracy=table(table$V1 , table$V2 )
acc_perc = prop.table(accuracy, margin = 1 )


rownames(acc_perc)  = c("flat","summit","ridge","shoulder","spur","slope","hollow","footslope","valley","depression")
colnames(acc_perc)  = c("flat","summit","ridge","shoulder","spur","slope","hollow","footslope","valley","depression")

ggcorrplot2(acc_perc , lab= TRUE , digits =4  , lab_size = 7 )  +  labs(x="3DEP-1 geomorphologic forms", y="MERIT geomorphologic forms\n"  ) + 
theme(axis.text.y=element_text(size=20 , color="black" )) + theme(axis.text.x=element_text(size=20 , color="black" )) + 
theme(axis.title.y=element_text(size=22)) +  theme(axis.title.x=element_text(size=22)) 

acc_perc = prop.table(accuracy, margin = 2 )

rownames(acc_perc)  = c("flat","summit","ridge","shoulder","spur","slope","hollow","footslope","valley","depression")
colnames(acc_perc)  = c("flat","summit","ridge","shoulder","spur","slope","hollow","footslope","valley","depression")
ggcorrplot2(acc_perc , lab= TRUE , digits =4  , lab_size = 7 )  +  labs(x="3DEP-1 geomorphologic forms", y="MERIT geomorphologic forms\n"  ) + 
theme(axis.text.y=element_text(size=20 , color="black" )) + theme(axis.text.x=element_text(size=20 , color="black" )) + 
theme(axis.title.y=element_text(size=22)) +  theme(axis.title.x=element_text(size=22))  


dev.off()
EOF

