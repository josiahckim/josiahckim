library(caret)
library(data.table)
library(tidyverse)
set.seed(77)

samp<-fread('/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/raw/Stat_380_sample_submission.csv')
test<-fread('/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/raw/Stat_380_test2021.csv')
train<-fread('/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/raw/Stat_380_train2021.csv')

# Make an initial submission file to get above the 10-point marker 
# Make a new data frame with just the house price column 


#First try
# Took the average that includes every single home and made that the sale price for each home 
# This did not exceed the 10-point marker 
init_submission <- train[,.(SalePrice = mean(SalePrice))]
test$SalePrice <- init_submission  
init_submission <- test[,.(Id, SalePrice)]
fwrite(init_submission,"/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/processed/submission.csv")
######################
# Second try
# Took the average of homes BY LIVING AREA, then made the sale price according to the living area
# This exceeded the 10-point marker 
df1 <- train %>%
  group_by(GrLivArea) %>%
  summarise(SalePrice = mean(SalePrice))

submission_2 <- test %>%
  left_join(df1, by = "GrLivArea")

fwrite(submission_2[,.(Id, SalePrice)],"/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/processed/submission.csv")
#####################
# Third try 
# First attempt at logistic regression 
# First, I want to preprocess (normalize) the training data 
processed <- preProcess(train[,-"SalePrice"], method=c("range"))
train_processed <- predict(processed, train)
# Model
mylogit <- lm(SalePrice ~ LotFrontage + LotArea + BldgType + OverallQual + OverallCond + FullBath + HalfBath + TotRmsAbvGrd + YearBuilt + TotalBsmtSF + BedroomAbvGr + Heating + CentralAir + GrLivArea + PoolArea + YrSold, data = train_processed)
summary(mylogit)
# Preprocess the test data 
processed2 <- preProcess(test[,-"Id"], method=c("range"))
# Run model on test data
test_processed <- predict(processed2, test)
test_processed$SalePrice <- predict(mylogit, newdata = test_processed, type = "response")
# There are 874 "NA" values in LotFrontage 
colSums(is.na(test))
# Take the average of LotFrontage and replace the NAs with this value 
LotFrontage_avg <- mean(test_processed$LotFrontage, na.rm = TRUE)
LotFrontage_avg
test_processed$LotFrontage[is.na(test_processed$LotFrontage)] <- LotFrontage_avg
colSums(is.na(test_processed))
# Run model again 
test_processed$SalePrice <- predict(mylogit, newdata = test_processed, type = "response")
test_processed
fwrite(test_processed[,.(Id, SalePrice)],"/Users/josiahkim/Desktop/STAT380/A - House_Price_Project/project/volume/data/processed/submission.csv")





