
cd /gpfs/gibbs/pi/hydro/hydro/dataproces/GSIM/GSIM_indices/TIMESERIES/monthly_snaping/extract4mod

module load R/4.3.0-foss-2022b

Rscript --vanilla  -e   '


library(data.table)

pdf("scatterplotMEANtrain.pdf", width = 8, height = 8)
# Create the plot

table=fread("obs_pred_train.txt" , sep=" " )

plot(table$MEANp, table$MEANo, xlab = "Prediction", ylab = "Observation")
# Close the pdf device
dev.off()

library(data.table)

pdf("scatterplotMEANtest.pdf", width = 8, height = 8)
# Create the plot

table=fread("obs_pred_test.txt" , sep=" " )

plot(table$MEANp, table$MEANo, xlab = "Prediction", ylab = "Observation")
# Close the pdf device
dev.off()


'
