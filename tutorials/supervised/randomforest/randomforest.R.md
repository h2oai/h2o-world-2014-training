# Introduction to Random Forests in H2O

###### This tutorial introduces H2O's Random Forest framework in R.

#### Random Forests

##### Intuition: Average an ensemble of weakly predicting (larger) trees where each tree is *de-correlated* from all other trees.

##### Important components:
###### 1. Number of trees
###### 2. Maximum depth of tree
###### 3. Number of variables randomly sampled as candidates for splits
###### 4. Sampling rate for constructing data set to use on each tree

### R Documentation

###### The `h2o.randomForest` function fits H2O's Random Forest from within R.

    library(h2o)
    args(h2o.randomForest)

###### The R documentation (man page) for H2O's Random Forest can be opened from within R using the `help` or `?` functions:

    help(h2o.randomForest)

###### We can run the example from the man page using the `example` function:

    example(h2o.randomForest)

###### And run a longer demonstration from the `h2o` package using the `demo` function:

    demo(h2o.randomForest)
