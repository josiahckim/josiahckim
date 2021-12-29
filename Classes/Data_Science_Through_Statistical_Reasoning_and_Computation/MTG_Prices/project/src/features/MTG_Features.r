library(caret)
library(data.table)
library(tidyverse)
library(ISLR)

set.seed(77)

samp <-fread('/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/raw/example_submission.csv')
card <- fread('/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/raw/card_tab.csv') 
set <- fread('/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/raw/set_tab.csv')
test <- fread('/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/raw/start_test.csv')
train <- fread('/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/raw/start_train.csv')

# Merge set and card -> set_card
set_card <- set[card, on="set"] 

# Merge card_set and train -> train_final
train_final <- train[set_card, on="id", nomatch=0]

# Remove redundant and un-usables columns 
train_final <- train_final[,-c("set_name","text", "test")]

# Make test_final
test <- test[-1,]
test$id <- test$V1
test <- test[,-c("V1", "V2", "V3")]
test_final <-  set_card[test, on="id", nomatch=0]
test_final <- test_final[,-c("set_name","text", "test")]



# To-Do: Make dummy variables


# Save test and training datasets
fwrite(test_final, "/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/interim/test_final.csv")
fwrite(train_final, "/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/interim/train_final.csv")
