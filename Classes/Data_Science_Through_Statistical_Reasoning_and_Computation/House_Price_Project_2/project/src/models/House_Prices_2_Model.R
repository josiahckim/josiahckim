library(caret)
library(data.table)
library(tidyverse)
library(GGally)
library(xgboost)
library(Metrics)
library(Boruta)

set.seed(77)

# Import data 
train<-fread("/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/train_final.csv")
test<-fread("/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/test_final.csv")
validation <- fread("/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/interim/validation_final.csv")


#############
# REMOVE NA #
#############
train_na <- train %>%
  filter(is.na(LotFrontage) == FALSE) 





#####################
# FEATURE SELECTION #
#####################
# Stepwise in both directions 
base.mod <- lm(SalePrice ~ GrLivArea , data=train_na)  
all.mod <- lm(SalePrice ~ . , data= train_na) 
stepMod <- step(base.mod, scope = list(lower = base.mod, upper = all.mod), direction = "both", trace = 0, steps = 1000)  
shortlistedVars <- names(unlist(stepMod[[1]])) 
shortlistedVars <- shortlistedVars[!shortlistedVars %in% "(Intercept)"] # remove intercept
print(shortlistedVars)


# Make data frame with the selected features. 
train <- train[, c("GrLivArea", "OverallQual", "TotalBsmtSF", "YearBuilt", "OverallCond", "LotArea", "FullBath",
                            "BedroomAbvGr", "BldgType_1Fam", "LotFrontage", "CentralAir_N", "TotRmsAbvGrd", "BldgType_Duplex", 
                            "SalePrice", "Id")]
validation <- train[, c("GrLivArea", "OverallQual", "TotalBsmtSF", "YearBuilt", "OverallCond", "LotArea", "FullBath",
                                 "BedroomAbvGr", "BldgType_1Fam", "LotFrontage", "CentralAir_N", "TotRmsAbvGrd", "BldgType_Duplex", 
                                 "SalePrice", "Id")]
test <- test[, c("GrLivArea", "OverallQual", "TotalBsmtSF", "YearBuilt", "OverallCond", "LotArea", "FullBath",
                        "BedroomAbvGr", "BldgType_1Fam", "LotFrontage", "CentralAir_N", "TotRmsAbvGrd", "BldgType_Duplex", 
                        "Id")]




#############
# DATA PREP #
#############
# Isolate the outcome feature: SalePrice
train_y <- train$SalePrice
validation_y <- validation$SalePrice

# Drop feature(s): Id, SalePrice
test_id <- test$Id # Save the column for submission 
test <- test[,-"Id"]
train <- train[,-c("Id", "SalePrice")]
validation <- validation[,-c("Id", "SalePrice")]



# Convert data frames to matrices
train_mat <- as.matrix(train)
validation_mat <- as.matrix(validation)
test_mat <- as.matrix(test)

dtrain <- xgb.DMatrix(train_mat, label = train_y, missing = NA)
dvalidation <- xgb.DMatrix(validation_mat, missing=NA)
dtest <- xgb.DMatrix(test_mat, missing=NA)
hyper_perm_tune<-NULL






########################
# Use cross validation #
########################

param <- list(  objective           = "reg:linear",
                gamma               =0.02,
                booster             = "gbtree",
                eval_metric         = "rmse",
                eta                 = 0.02,
                max_depth           = 5,
                min_child_weight    = 1,
                subsample           = 1.0,
                colsample_bytree    = 1.0,
                tree_method = 'hist'
)

XGBm<-xgb.cv( params=param,nfold=5,nrounds=10000,missing=NA,data=dtrain,print_every_n=1,early_stopping_rounds=25)

best_ntrees<-unclass(XGBm)$best_iteration

new_row<-data.table(t(param))

new_row$best_ntrees<-best_ntrees

test_error<-unclass(XGBm)$evaluation_log[best_ntrees,]$test_rmse_mean
new_row$test_error<-test_error
hyper_perm_tune <- rbind(new_row, hyper_perm_tune)


watchlist <- list( train = dtrain)



##########################
# PREDICT VALIDATION SET #
##########################
XGBm<-xgb.train( params=param,nrounds=best_ntrees,missing=NA,data=dtrain,watchlist=watchlist,print_every_n=1)
pred<-predict(XGBm, newdata = dvalidation)
rmse(validation_y, pred)



####################
# PREDICT TEST SET #
####################
pred_final<-predict(XGBm, newdata = dtest)
submission_final <- data.frame(Id = test_id, SalePrice = pred_final)




###################
# SAVE SUBMISSION #
###################
fwrite(submission_final, "/Users/josiahkim/Desktop/STAT380/House_Price_Project_2/project/volume/data/processed/submission.csv")

