# Introduction to Gradient Boosting Machines in H2O

###### This tutorial introduces H2O's Gradient (Tree) Boosting Machines framework in R.

#### Gradient Boosting Machines (GBM)

##### Intuition: Average an ensemble of weakly predicting (small) trees where each tree "adjusts" to the "mistakes" of the preceding trees.

##### Important components:
###### 1. Number of trees
###### 2. Maximum depth of tree
###### 3. Learning rate ( *shrinkage* parameter)

###### where smaller learning rates tend to require larger number of tree and vice versa.

### R Documentation

###### The `h2o.gbm` function fits H2O's Gradient Boosting Machines from within R.

    library(h2o)
    args(h2o.gbm)

###### The R documentation (man page) for H2O's Gradient Boosting Machines can be opened from within R using the `help` or `?` functions:

    help(h2o.gbm)

###### We can run the example from the man page using the `example` function:

    example(h2o.gbm)

###### And run a longer demonstration from the `h2o` package using the `demo` function:

    demo(h2o.gbm)
