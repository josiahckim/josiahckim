library(caret)
library(data.table)
library(tidyverse)
library(ISLR)
library(fastDummies)

set.seed(77)

# Import data 
samp<-fread('/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/raw/Stat_380_sample_submission.csv')
test<-fread('/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/raw/Stat_380_test.csv')
train<-fread('/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/raw/Stat_380_train.csv')



#####################################    
# FEATURE ENGINEERING: TRAINING SET #
#####################################
# Take a peek
unique(train$BldgType) # See which unique variables to turn into dummies 
unique(train$Heating)
unique(train$CentralAir)

# Make dummies 
train_dummies <- dummy_cols(train, select_columns = c('BldgType', 'Heating', 'CentralAir'))
train_dummies = train_dummies[,-c('BldgType', 'Heating', 'CentralAir')]

# Count the NAs 
# LotFrontage has 1769 NAs
colSums(is.na(train_dummies)) 

# Drop NAs
#train_NAs <- train_dummies %>%
#  filter(is.na(LotFrontage) == FALSE) 

# Standardize 
train_processed <- preProcess(train_dummies[,-c("SalePrice", "Id")], method=c("range"))
train_processed <- predict(train_processed, train_dummies)



#################################    
# FEATURE ENGINEERING: TEST SET #
################################# 
test_dummies <- dummy_cols(test, select_columns = c('BldgType', 'Heating', 'CentralAir'))
test_dummies = test_dummies[,-c('BldgType', 'Heating', 'CentralAir')]

# Standardize 
test_processed <- preProcess(test_dummies[,-c("Id")], method=c("range"))
test_processed <- predict(test_processed, test_dummies)




#########################
# CREATE VALIDATION SET #
#########################
rand_inx <- sample(1:nrow(train_processed),8000)
train_final <- train_processed[rand_inx,]
validation <- train_processed[!rand_inx,]





########
# SAVE #
########
# Save traing and test sets
fwrite(train_final, "/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/train_final.csv")
fwrite(test_processed, "/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/test_final.csv")
fwrite(validation, "/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/validation_final.csv")

