# Unsupervised Learning and Clustering With H2O KMeans

###### This tutorial shows how a [KMeans](http://en.wikipedia.org/wiki/K-means_clustering) model is trained. This file is both valid R and markdown code. We will use a variety of well-known datasets that are used in published papers, which evaluate various KMeans implementations.

### Start H2O and build a KMeans model on iris

###### Initialize the H2O server and import the datasets we need for this session.

    library(h2o)
    h2oServer  <- h2o.init(nthreads=-1)
    homedir    <- "/data/h2o-training/clustering/"
    iris.h2o    <- as.h2o(h2oServer, iris)
    

### Our first KMeans model

###### It's easy to run KMeans, it's just like the `kmeans` method available in the stats package. We'll leave out the `Species` column and cluster on the iris flower attributes.

    km.model <- h2o.kmeans(data = iris.h2o, centers = 5, cols = 1:4, init="furthest")

###### Let's look at the model summary:

    km.model
    km.model@model$centers       # The centers for each cluster
    km.model@model$tot.withinss  # total within cluster sum of squares
    km.model@model$cluster       # cluster assignments per observation

###### To see the model parameters that were used, access the model@model$params field:
    
    km.model@model$params
    
###### You can get the R documentation help here:

    ?h2o.kmeans
    
### Use the Gap Statistic (Beta) To Find the Optimal Number of Clusters
###### This is essentially a grid search over KMeans.

###### You can get the R documentation help here:

    ?h2o.gapStatistic
    
###### The idea is that, for each 'k', generate WCSS from a reference distribution and examine the gap between the expected WCSS and the observed WCSS. To obtain the W_k from the reference distribution, 'B' Monte Carlo replicates are drawn from the reference distribution. For each replicate, a KMeans is constructed and the WCSS reported back.

    gap_stat <- h2o.gapStatistic(data = iris.h2o, K = 10, B = 100, boot_frac = .1, cols=1:4)
                                
###### Let's take a look at the output. The default output display will show the number of KMeans models that were run and the optimal value of k:

    gap_stat
    
###### We can also run summary on the gap_stat model:

    summary(gap_stat)
    
###### We can also plot our gap_stat model:

    plot(gap_stat)
    
### Comparison against other KMeans implementations.
###### Let's use the [Census 1990 dataset](https://archive.ics.uci.edu/ml/datasets/US+Census+Data+%281990%29), which has 2.5 million data points with 68 integer features.

    # census1990 <- "Census1990.csv.gz"
    # census.1990 <- h2o.importFile(h2oServer, path = paste0(homedir,census1990), header = F, sep = ',', key = 'census.1990.hex')

    # dim(census.1990)                                                            
    # km.census <- h2o.kmeans(data = census.1990, centers = 24, init="furthest")  # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                

###### We can compare the result with the published result from [Fast and Accurate KMeans on Large Datasets](http://papers.nips.cc/paper/4362-fast-and-accurate-k-means-for-large-datasets.pdf) where the cost for k = 24 and ~2GB of RAM was approximately 3.50E+18. This paper implements a streaming KMeans, so of course accuracy in the streaming case will not be as good as a batch job, but results are comparable within a few orders of magnitude. H2O gives the ability to work on datasets that don't fit in a single box's RAM without having to stream the data from cold storage: simply use distributed H2O.                                                                                                                                                                                                                                                                 

###### We can also compare with [StreamKM++: A Clustering Algorithm for Data Streams](http://www.cs.uni-paderborn.de/uploads/tx_sibibtex/2012_AckermannMRSLS_StreamKMpp.pdf). For various k, we can compare our implementation, but we only do k = 30 here.

    # km.census <- h2o.kmeans(data = census.1990, centers = 30, init="furthest")  # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                # NOT RUN: Too long on VM

##### We can also compare with the kmeans package:

    # census.1990.r <- read.csv(file.path(homedir,census1990)) 
    # km.census.r <- kmeans(census.1990.r, centers = 24)         # NOT RUN: Quick-TRANSfer stage steps exceeded maximum (= 122914250) 
    # km.census.r$tot.withinss

###### Let's compare now on the big dataset BigCross [Big Cross](http://www.cs.uni-paderborn.de/en/fachgebiete/ag-bloemer/research/clustering/streamkmpp/), which has 11.6 million data points with 57 integer features.

    # bigcross   <- "BigCross.data.gz"
    # big.cross   <- h2o.importFile(h2oServer, path = paste0(homedir,bigcross), header = F, sep = ',', key = 'big.cross.hex')
    
    # dim(big.cross)                                                                # NOT RUN: Too long on VM
    # km.bigcross <- h2o.kmeans(data = big.cross, centers = 24, init="furthest")    # NOT RUN: Too long on VM
    # km.bigcross@model$tot.withinss                                                # NOT RUN: Too long on VM

###### We can compare the result with the published result from [Fast and Accurate KMeans on Large Datasets](http://papers.nips.cc/paper/4362-fast-and-accurate-k-means-for-large-datasets.pdf), where the cost for k = 24 and ~2GB of RAM was approximately 1.50E+14.

###### We can also compare with [StreamKM++: A Clustering Algorithm for Data Streams](http://www.cs.uni-paderborn.de/uploads/tx_sibibtex/2012_AckermannMRSLS_StreamKMpp.pdf). For various k, we can compare our implementation, but we only do k = 30 here.

    # km.bigcross <- h2o.kmeans(data = big.cross, centers = 30, init="furthest")    # NOT RUN: Too long on VM
    # km.bigcross@model$tot.withinss                                                # NOT RUN: Too long on VM

