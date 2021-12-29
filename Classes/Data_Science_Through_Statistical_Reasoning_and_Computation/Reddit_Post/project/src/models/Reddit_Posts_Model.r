library(caret)
library(data.table)
library(tidyverse)
library(ISLR)
#library(fastDummies)
library(ClusterR)
library(Rtsne)
library(dplyr)
library(xgboost)
require(nnet)
library(Metrics)


set.seed(77)

# Import data 
samp <- fread('/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/raw/examp_sub.csv')
test <- fread('/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/raw/test_file.csv')
train <- fread('/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/raw/training_data.csv')
test_emb <- fread('/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/raw/test_emb.csv')
train_emb <- fread('/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/raw/training_emb.csv')



#######################
# MAKE MASTER DATASET #
#######################
reddit = train$reddit # Save reddit column.

train_bind <- cbind(train, train_emb)
train_bind <- train_bind[, -c("reddit", "text")]
test_bind <- cbind(test, test_emb)
test_bind <- test_bind[, -c("id", "text")]
master_dt <- rbind(train_bind, test_bind)



#########################
# PCA ON MASTER DATASET #
#########################
pca <- prcomp(master_dt) # Do PCA

screeplot(pca) # Visualize the percent variances for the PCs 

pca # View PCs and their variances

summary(pca) # Summarize PCs 

biplot(pca) # View biplot of PC1 and PC2

pca_dt<-data.table(unclass(pca)$x) # use the unclass() function to get the data in PCA space

#pca_dt$breed <- NA

#pca_dt$breed[1] <- 'breed_3'
#pca_dt$breed[5] <- 'breed_2'
#pca_dt$breed[6] <- 'breed_4'


pca_dt %>% # see a plot with the id data 
  ggplot(aes(x=PC1, y=PC2)) + 
  geom_point()


###############
# TSNE ON PCA #
###############

# Run TSNE
tsne<-Rtsne(pca_dt, pca = F, perplexity=10, check_duplicates = F) 

tsne_dt<-data.table(tsne$Y) # Grab coordinates. 


#######################
# FEATURE ENGINEERING #
#######################

train_x <-  tsne_dt[1:nrow(train),] # Split into training set
test_x <- tsne_dt[nrow(train)+1:nrow(test),]# Split into test set.
train_x$reddit <- reddit # Place back output column. 

train_x$reddit[train_x$reddit == "cars"] <- 0 # Replace categorical values with numerics.
train_x$reddit[train_x$reddit == "CFB"] <- 1
train_x$reddit[train_x$reddit == "Cooking"] <- 2
train_x$reddit[train_x$reddit == "MachineLearning"] <- 3
train_x$reddit[train_x$reddit == "magicTCG"] <- 4
train_x$reddit[train_x$reddit == "politics"] <- 5
train_x$reddit[train_x$reddit == "RealEstate"] <- 6
train_x$reddit[train_x$reddit == "science"] <- 7
train_x$reddit[train_x$reddit == "StockMarket"] <- 8
train_x$reddit[train_x$reddit == "travel"] <- 9
train_x$reddit[train_x$reddit == "videogames"] <- 10

train_y <- train_x$reddit
train_x <- train_x[,-"reddit"]



#####################################
# MODELLING: XGBOOST ON TSNE OUTPUT #
#####################################
#reddit <- tsne_dt$reddit # Save output variable.
#tsne_dt <- tsne_dt[, -c("id", "V1", "V2")] # Drop id and reddit. 

#dummies <- dummyVars(reddit~ ., data = train_x)

#x.train<-predict(dummies, newdata = train_x)

#x.test<-predict(dummies, newdata = test)
dtrain <- xgb.DMatrix(as.matrix(train_x),label=train_y,missing=NA)
dtest <- xgb.DMatrix(as.matrix(test_x),missing=NA)

hyper_perm_tune<-NULL

param <- list(  objective           = "multi:softprob",
                num_class           = 11,
                gamma               =0.02,
                booster             = "gbtree",
                eval_metric         = "mlogloss",
                eta                 = 0.02,
                max_depth           = 5,
                min_child_weight    = 1,
                subsample           = 1.0,
                colsample_bytree    = 1.0,
                tree_method = 'hist'
)


XGBm<-xgb.cv(params=param, 
             nfold=5,
             nrounds=10000,
             missing=NA,
             data=dtrain,
             print_every_n=1,
             early_stopping_rounds=25,
             verbose = FALSE,
             prediction = TRUE)

best_ntrees<-unclass(XGBm)$best_iteration

new_row<-data.table(t(param))

new_row$best_ntrees<-best_ntrees

test_error<-unclass(XGBm)$evaluation_log[best_ntrees,]$test_rmse_mean
new_row$test_error<-test_error
hyper_perm_tune<-rbind(new_row,hyper_perm_tune)


# the watchlist will let you see the evaluation metric of the model for the current number of trees.
# in the case of the house price project you do not have the true houseprice on hand so you do not add it to the watchlist, just the dtrain
watchlist <- list( train = dtrain)

# now fit the full model
# I have removed the "early_stop_rounds" argument, you can use it to have the model stop training on its own, but
# you need an evaluation set for that, you do not have that available to you for the house data. You also should have 
# figured out the number of trees (nrounds) from the cross validation step above. 

XGBm<-xgb.train( params = param, 
                 nrounds=best_ntrees, 
                 missing=NA, 
                 data=dtrain, 
                 watchlist=watchlist,
                 print_every_n=1, 
                 verbose = 1)


# just like the other model fitting methods we have seen, we can use the predict function to get predictions from the 
# model object as long as the new data is identical in format to the training data. Note that this code saves the
# predictions as a vector, you will need to get this vector into the correct column to make a submission file. 
#pred<-predict(XGBm, newdata = dtest)

# Predict outcomes with the test data
pred = predict(XGBm, dtest, reshape=T)
predictions <- data.table(pred)



####################################
# GET DATASET READY FOR SUBMISSION #
####################################
predictions %>% setnames("V1", "redditcars") 
predictions %>% setnames("V2", "redditCFB") 
predictions %>% setnames("V3", "redditCooking")
predictions %>% setnames("V4", "redditMachineLearning")
predictions %>% setnames("V5", "redditmagicTCG") 
predictions %>% setnames("V6", "redditpolitics")
predictions %>% setnames("V7", "redditRealEstate") 
predictions %>% setnames("V8", "redditscience") 
predictions %>% setnames("V9", "redditStockMarket") 
predictions %>%  setnames("V10", "reddittravel") 
predictions %>%  setnames("V11", "redditvideogames") 

predictions$id <- 1:nrow(predictions) # Add an id column.
predictions <- predictions[,c(12, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11)] # Reorder. 


########
# SAVE #
########
# Save traing and test sets
fwrite(predictions, "/Users/josiahkim/Desktop/STAT380/Reddit_Post/project/volume/data/processed/predictions1.csv")


