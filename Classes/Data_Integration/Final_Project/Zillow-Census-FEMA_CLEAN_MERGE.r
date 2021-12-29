library(data.table)
library(tidyverse)
library(stringr)



####################
# READ IN THE DATA #
####################
fema <- fread("/Users/josiahkim/OneDrive\ -\ The\ Pennsylvania\ State\ University/PSU\ Semester\ 9/DS320/Project/femadata.csv")
zillow <- fread("/Users/josiahkim/OneDrive\ -\ The\ Pennsylvania\ State\ University/PSU\ Semester\ 9/DS320/Project/zillowdata.csv")



#########################
# GET ZILLOW JOIN-READY #
#########################
# We need to join by CountyName and RegionID. 
# There are county names that start just "0" - fitler these out. 
zillow <- zillow %>%
  filter(CountyName != "0")

# CountyNames have "County" at the end of the name - remove these.
zillow <- zillow %>%
  mutate_at("CountyName", str_replace, " County", "")

# Change column names to match fema. 
zillow %>%
  setnames("CountyName","county")
zillow %>%
  setnames("State","stateCode")
zillow %>%
  setnames("RegionID", "region")





##############
# LET'S JOIN #
##############
fema_zillow_joined <- fema %>%
  left_join(zillow, by = c("county", "stateCode"))





############################
# GET THE DATA MODEL-READY #
############################
# There are different measures of house prices - let's narrow is down to one measure.
# Measure: City_Zhvi_AllHomes
View(fema_zillow_joined %>%
  filter(which_measurement == "City_Zhvi_AllHomes"))




fwrite(fema_zillow_joined, "/Users/josiahkim/OneDrive\ -\ The\ Pennsylvania\ State\ University/PSU\ Semester\ 9/DS320/Project/fema_zillow_joined.csv")




