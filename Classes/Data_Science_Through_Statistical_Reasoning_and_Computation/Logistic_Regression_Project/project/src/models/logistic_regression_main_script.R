library(caret)
library(data.table)
library(tidyverse)
library(ISLR)

set.seed(77)

samp <-fread('/Users/josiahkim/Desktop/STAT380/Logistic_Regression_Project/project/volume/data/raw/samp_sub.csv')
train <- fread('/Users/josiahkim/Desktop/STAT380/Logistic_Regression_Project/project/volume/data/raw/train_file.csv') 
test <- fread('/Users/josiahkim/Desktop/STAT380/Logistic_Regression_Project/project/volume/data/raw/test_file.csv')


# Model
coin_model <- glm(result ~ V1 + V2 + V3 + V4 + V5 + V6 + V7 + V8 + V9 + V10 , data = train)
summary(coin_model)


# Predict
test$result <- predict(coin_model, newdata = test, type="response")

#Save
fwrite(test[,.(id, result)],"/Users/josiahkim/Desktop/STAT380/Logistic_Regression_Project/project/volume/data/processed/submission.csv")
