#######################
# LIBRARYIES AND DATA #
#######################
library(caret)
library(data.table)
library(tidyverse)
library(ISLR)
library(ClusterR)
library(Rtsne)

set.seed(77)

data <-fread('/Users/josiahkim/Desktop/STAT380/Dog_Breed_Project/project/volume/data/raw/data.csv')
example <- fread('/Users/josiahkim/Desktop/STAT380/Dog_Breed_Project/project/volume/data/raw/example_sub.csv')



########################
# PRELIMINARY ANALYSIS #
########################
id = data$id # Save the id column 

data_dropped <- data[, -"id"] # Drop the sample names

pca <- prcomp(data_dropped) # Do PCA

screeplot(pca) # Visualize the percent variances for the PCs 

pca # View PCs and their variances

summary(pca) # Summarize PCs 

biplot(pca) # View biplot of PC1 and PC2

pca_dt<-data.table(unclass(pca)$x) # use the unclass() function to get the data in PCA space

pca_dt$breed <- NA

pca_dt$breed[1] <- 'breed_3'
pca_dt$breed[5] <- 'breed_2'
pca_dt$breed[6] <- 'breed_4'



pca_dt %>% # see a plot with the id data 
  ggplot(aes(x=PC1, y=PC2, col=breed)) + 
  geom_point()




#############
# RUN T-SNE #
#############

# run t-sne on the PCAs, note that if you already have PCAs you need to set pca=F or it will run a pca again. 
# pca is built into Rtsne, ive run it seperatly for you to see the internal steps

tsne<-Rtsne(pca_dt,pca = F,perplexity=50,check_duplicates = F)

# grab out the coordinates
tsne_dt<-data.table(tsne$Y)



# use a gaussian mixture model to find optimal k and then get probability of membership for each row to each group

# this fits a gmm to the data for all k=1 to k= max_clusters, we then look for a major change in likelihood between k values
k_bic<-Optimal_Clusters_GMM(tsne_dt[,.(V1,V2)],max_clusters = 10,criterion = "BIC")

# now we will look at the change in model fit between successive k values
delta_k<-c(NA,k_bic[-1] - k_bic[-length(k_bic)])

# I'm going to make a plot so you can see the values, this part isnt necessary
del_k_tab<-data.table(delta_k=delta_k,k=1:length(delta_k))

# plot 
ggplot(del_k_tab,aes(x=k,y=-delta_k))+geom_point()+geom_line()+
  scale_x_continuous(breaks = scales::pretty_breaks(n = 10))+
  geom_text(aes(label=k),hjust=0, vjust=-1)



opt_k<-4

# now we run the model with our chosen k value
gmm_data<-GMM(tsne_dt[,.(V1,V2)],opt_k)

# the model gives a log-likelihood for each datapoint's membership to each cluster, me need to convert this 
# log-likelihood into a probability

l_clust<-gmm_data$Log_likelihood^10

l_clust<-data.table(l_clust)

net_lh<-apply(l_clust,1,FUN=function(x){sum(1/x)})

cluster_prob<-1/l_clust/net_lh

# we can now plot to see what cluster 1 looks like

tsne_dt$Cluster_1_prob<-cluster_prob$V1
tsne_dt$Cluster_2_prob<-cluster_prob$V2
tsne_dt$Cluster_3_prob<-cluster_prob$V3
tsne_dt$Cluster_4_prob<-cluster_prob$V4

tsne_dt %>%
  ggplot(aes(x=V1,y=V2,col=Cluster_4_prob)) +
  geom_point() 



#############
# SAVE DATA #
#############

output <- cluster_prob
output <- output %>% 
  mutate(across(starts_with("V"), round, 5))


output$id <- id
output <- output[,c(5, 1, 2, 3, 4)]
colnames(output) <- c("id", "breed_1", "breed_2", "breed_4", "breed_3")
output <- output[,c(1, 2, 3, 5, 4)]


fwrite(output, "/Users/josiahkim/Desktop/STAT380/Dog_Breed_Project/project/volume/data/external/submission.csv")





