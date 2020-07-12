#FNMM_analysis_helper script by Joshua Peterson: https://github.com/J-PTRson/Cell-Image-Analysis


#install and load the required packages 
if (!require(ggplot2)){ install.packages('ggplot2')}
library(ggplot2)

#Import the output results file.
path = choose.files(default = "", caption = "Select the FNMM output results") #Results.csv
mydata = read.csv(path, sep = "," , row.names = NULL, header = T) 

#calculate nuclear area
dapi_cells<- subset(mydata, mydata$Label == "DAPI")
dapi_nuclear_area <- sum(dapi_cells$Area)

gfp_cells<- subset(mydata, mydata$Label == "GFP")
gfp_nuclear_area<- sum(gfp_cells$Area)

#calculate percentages
perc_gfp <- round(gfp_nuclear_area/dapi_nuclear_area*100, digits = 0)
perc_non_gfp <- round(100-perc_gfp,digits = 0)

#create dataframe
df <- data.frame(group = c("GFP positive cells", "GFP negative cells"), value = c(perc_gfp, perc_non_gfp))

#plot chart
ggplot(df, aes(x="", y=value, fill=group)) +  
  geom_bar(stat="identity", width=3, color="white") +
  coord_polar("y", start=0) + 
  scale_fill_manual(values=c("gray77", "springgreen4")) +
  geom_text(aes(y = value/2  + c(0, cumsum(value)[-length(value)]), label=c(paste(perc_gfp,"%",sep=""), paste(perc_non_gfp,"%",sep=""))), vjust=0, color="white", size=10) +
  theme_void() # remove background, grid, numeric labels
