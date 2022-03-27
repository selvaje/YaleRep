#!/bin/bash
#SBATCH -p week
#SBATCH -n 1 -c 1  -N 1  
#SBATCH -t 168:00:00
#SBATCH --mail-user=email
#SBATCH -o /gpfs/scratch60/fas/sbsc/ga254/stdout/sc08_hysdrosheds_width_aggregation_ploting.R.%J.out
#SBATCH -e /gpfs/scratch60/fas/sbsc/ga254/stderr/sc08_hysdrosheds_width_aggregation_ploting.R.%J.err
#SBATCH --job-name=sc08_hysdrosheds_width_aggregation_ploting.R.sh
#SBATCH --mem-per-cpu=10000

# sbatch /gpfs/home/fas/sbsc/ga254/scripts/NITRO/sc09_hysdrosheds_width_aggregation_ploting.R.sh


export OUTDIR=/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL
export RAM=/dev/shm

cd /gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL
# awk ' {   if ($2 > 1 ) print   }'  $OUTDIR/FLO1K_qav_grwl_1km_clean.txt > $OUTDIR/FLO1K_qav_grwl_1km_clean_moreW1.txt


module load Apps/R/3.3.2-generic


# R --vanilla --no-readline   -q  <<'EOF'

# library(ggplot2)
# table=read.table("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/FLO1K_qav_grwl_1km_clean_moreW1.txt")
# colnames(table)[1] = "Q"  # FLO1K
# colnames(table)[2] = "W"  # GRWL 


# # lm = lm(  log(table$W) ~  log(table$Q)) 

# # y <- log(table$W) 
# # x <- log(table$Q)

# y = log( table$W[table$Q > 1 ])
# x = log( table$Q[table$Q > 1 ])

# mod <- nls(y ~ exp(a + b * x), start = list(a = 0, b = 0))

# lm = lm(  x ~ y) 
# df <- data.frame(x = x, y = y,
#   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
# p <- ggplot( data = df   , aes(x = x , y = y)) + 
#     geom_point(aes(x, y, col = d), size = 0.4) +
#     scale_color_identity() +
#     geom_smooth(method = "nls", se = FALSE , color = "black" , formula=y ~ exp(a + b * x^2)  )  +
#     labs(x = "log(Q-FLO1K) (m3/s)")  + 
#     labs(y = "log(W-GRWL) (m)")  + 
#     theme_bw()
# # print(p)
# ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/Q_FLO1K_vs_W_GRWL.png")


# w_pete1  <- (0.510 * x ) + 1.86
# w_pete2  <- (0.423 * x ) + 2.56
# # a-coefficient = 8.5 and b-exponent = 0.47 
# w_georg  <- (0.47  * x ) + log(8.5)

# # GRWL vs W calculate with Pete1 formula 
# x <- w_pete1 
# lm = lm(  x ~ y) 
# df <- data.frame(x = x, y = y,
#   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
# p <- ggplot( data = df   , aes(x = x , y = y)) + 
#     geom_point(aes(x, y, col = d), size = 0.4) +
#     scale_color_identity() +
#     geom_smooth(method = "lm", se = FALSE , color = "black"  )  +
#     labs(x = "log(W-Pete1) (M)")  + 
#     labs(y = "log(W) (m)")  + 
#     theme_bw()
# # print(p)

# ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/W_GRWL_W_Pete1.png")

# # GRWL vs W calculate with Pete2 formula 

# x <- w_pete2 
# lm = lm(  x ~ y) 
# df <- data.frame(x = x, y = y,
#   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
# p <- ggplot( data = df   , aes(x = x , y = y)) + 
#     geom_point(aes(x, y, col = d), size = 0.4) +
#     scale_color_identity() +
#     geom_smooth(method = "lm", se = FALSE , color = "black"  )  +
#     labs(x = "log(W-Pete2) (m)")  + 
#     labs(y = "log(W) (m)")  + 
#     theme_bw()
# # print(p)

# ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/W_GRWL_W_Pete2.png")

# # GRWL vs W calculate with George formula 

# x <- w_georg 
# lm = lm(  x ~ y) 
# df <- data.frame(x = x, y = y,
#   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6)))))
# p <- ggplot( data = df   , aes(x = x , y = y)) + 
#     geom_point(aes(x, y, col = d), size = 0.4) +
#     scale_color_identity() +
#     geom_smooth(method = "lm", se = FALSE , color = "black"  )  +
#     labs(x = "log(W-George) (m)")  + 
#     labs(y = "log(W) (m)")  + 
#     theme_bw()
# # print(p)

# ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/W_GRWL_W_Georg.png")

# EOF



R --vanilla --no-readline   -q  <<'EOF'

library(ggplot2)
library(car)
library(quantreg)
library(mblm)

table=read.table("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/FLO1K_qav_grwl_1km_new.txt")
colnames(table)[1] = "Q"  # FLO1K
colnames(table)[2] = "W"  # GRWL 

y <- table$W
x <- table$Q

y <- as.numeric(table$W[table$Q > 200 ])
x <- table$Q[table$Q > 200 ]
 
x=log(x)
y=log(y)

ts_fit <- mblm(x  ~ y  ,  repeated = FALSE ) 


df <- data.frame(x = x, y = y,
   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6))))   )
   p <- ggplot( data = df   , aes(x = x, , y = y)) + 
      geom_point(aes(x, y, col = d), size = 0.4) +
      geom_smooth(method = "lm", se = FALSE , color = "black") +
      geom_abline(intercept = coef(ts_fit)[1], slope = coef(ts_fit)[2] , color = "red"  ) +
      geom_quantile(quantiles = 0.5) +
      geom_quantile(quantiles = 0.25) +
      geom_quantile(quantiles = 0.75) +
      scale_color_identity() +
      labs(x = "ln(Q-FLO1K) (m3/s)")  + 
      labs(y = "ln(W-GRWL) (m)")  + 
      theme_bw()
  print(p)
  ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/Q_FLO1K_vs_W_GRWL_logQ200_F.png")

Qreg75=rq( y ~ x , tau=0.75)
Qreg25=rq( y ~ x , tau=0.25)
Qreg50=rq( y ~ x , tau=0.50)

# as in https://stats.stackexchange.com/questions/129200/r-squared-in-quantile-regression#129246 

Qreg1=rq( y ~ 1 , tau=0.5)

rho <- function(u,tau=.5)u*(tau - (u < 0))
R1 <- 1 - Qreg50$rho/Qreg1$rho

print (R1) 

print(Qreg75)   
print(Qreg25)   
print(Qreg50)   

Lreg=lm( y ~ x )
print ( summary(Lreg) ) 

# plot original data 
y <- table$W
x <- table$Q

df <- data.frame(x = x, y = y,
   d = densCols(x, y, colramp = colorRampPalette(rev(rainbow(10, end = 4/6))))   )
   p <- ggplot( data = df   , aes(x = x, , y = y)) + 
      geom_point(aes(x, y, col = d), size = 0.4) +
      scale_color_identity() +
      labs(x = "Q-FLO1K (m3/s)")  + 
      labs(y = "W-GRWL (m)")  + 
      theme_bw()
print(p)
ggsave("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/Q_FLO1K_vs_W_GRWL_Q200_F.png")

save.image("/gpfs/loomis/project/fas/sbsc/ga254/dataproces/NITRO/GRWL/Q_FLO1K_vs_W_GRWL.R")





EOF





exit 

