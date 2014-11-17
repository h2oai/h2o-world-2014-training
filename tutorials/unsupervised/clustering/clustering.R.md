# Unsupervised Learning and Clustering With H2O KMeans

###### This tutorial shows how a [KMeans](http://en.wikipedia.org/wiki/K-means_clustering) model is trained. This file is both valid R and markdown code. We will use a variety of well-known datasets that are used in published papers, which evaluate various KMeans implementations.

### Start H2O and build a KMeans model on iris

###### Initialize the H2O server and import the datasets we need for this session.

    library(h2o)
    h2oServer  <- h2o.init(nthreads=-1)
    homedir    <- "/data/h2o-training/clustering/"
    census1990 <- "Census1990.csv.gz"
    bigcross   <- "BigCross.data.gz"

    # only if there is time for these:
    # census.1990 <- h2o.importFile(h2oServer, path = paste0(homedir,census.1990), header = F, sep = ',', key = 'census.1990.hex')
    # big.cross   <- h2o.importFile(h2oServer, path = paste0(homedir,big.cross), header = F, sep = ',', key = 'big.cross.hex')
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
    
### Comparing against streaming kmeans implementations.
###### Let's compare first against the [Census 1990](https://archive.ics.uci.edu/ml/datasets/US+Census+Data+(1990), which has 2.5 million data points with 68 integer features.

    # dim(census.1990)                                                            # NOT RUN: Too long on VM
    # km.census <- h2o.kmeans(data = census.1990, centers = 24, init="furthest")  # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                # NOT RUN: Too long on VM

###### We can compare the result with the published result from [Fast and Accurate KMeans on Large Datasets](http://papers.nips.cc/paper/4362-fast-and-accurate-k-means-for-large-datasets.pdf). The cost for k = 24 and ~2GB of RAM came out at approximately 3.50E+18. This paper implements a streaming KMeans, so of course accuracy in the streaming case will not be as good as a batch job, but results are comparable within a few orders of magnitude. H2O gives the ability to work on datasets that don't fit in a single box's RAM without having to stream the data from cold storage: simply use distributed H2O.
                                                                                                                                                                                                                                                                         


###### We can also compare with [StreamKM++: A Clustering Algorithm for Data Streams](http://www.cs.uni-paderborn.de/uploads/tx_sibibtex/2012_AckermannMRSLS_StreamKMpp.pdf). For various k, we can compare our implementation, but we only do k = 30 here.

    # km.census <- h2o.kmeans(data = census.1990, centers = 30, init="furthest")  # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                # NOT RUN: Too long on VM

###### Let's compare now on the big dataset BigCross [Big Cross](http://www.cs.uni-paderborn.de/en/fachgebiete/ag-bloemer/research/clustering/streamkmpp/), which has 11.6 million data points with 57 integer features.

    # dim(big.cross)                                                              # NOT RUN: Too long on VM
    # km.census <- h2o.kmeans(data = big.cross, centers = 24, init="furthest")    # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                # NOT RUN: Too long on VM

###### We can compare the result with the published result from [Fast and Accurate KMeans on Large Datasets](http://papers.nips.cc/paper/4362-fast-and-accurate-k-means-for-large-datasets.pdf). The cost for k = 24 and ~2GB of RAM came out at approximately 1.50E+14.

###### We can also compare with [StreamKM++: A Clustering Algorithm for Data Streams](http://www.cs.uni-paderborn.de/uploads/tx_sibibtex/2012_AckermannMRSLS_StreamKMpp.pdf). For various k, we can compare our implementation, but we only do k = 30 here.

    # km.census <- h2o.kmeans(data = census.1990, centers = 30, init="furthest")  # NOT RUN: Too long on VM
    # km.census@model$tot.withinss                                                # NOT RUN: Too long on VM

