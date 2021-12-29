library(caret)
library(data.table)
library(tidyverse)
library(ISLR)

set.seed(77)

train <- fread("/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/interim/train_final.csv") 
test <- fread("/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/interim/test_final.csv")

# Linear Regression
mylogit <- lm(future_price ~ rarity, data = train)
summary(mylogit)

# Run model on test data
test$future_price <- predict(mylogit, newdata = test, type = "response")

# Save data
fwrite(test[,c("id", "future_price")], "/Users/josiahkim/Desktop/STAT380/MTG_Prices/project/volume/data/external/submission.csv")
