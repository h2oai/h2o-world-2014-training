# Introduction to Generalized Linear Models in H2O

###### This tutorial introduces H2O's Generalized Linear Models (GLM) framework in R.

### Generalized Linear Models (GLM)

#### Intuition: A linear combination of predictors is sufficient for determining an outcome.

##### Important components:
###### 1. Exponential family for error distribution (Gaussian/Normal, Binomial, Poisson, Gamma, Tweedie, etc.)
###### 2. Link function, whose inverse is used to generate predictions
###### 3. (Elastic Net) Mixing parameter between the L1 and L2 penalties on the coefficient estimates.
###### 4. (Elastic Net) Shrinkage parameter for the mixed penalty in 3.

### R Documentation

###### The `h2o.glm` function fits H2O's Generalized Linear Models from within R.

    library(h2o)
    args(h2o.glm)

###### The R documentation (man page) for H2O's Generalized Linear Models can be opened from within R using the `help` or `?` functions:

    help(h2o.glm)

###### We can run the example from the man page using the `example` function:

    example(h2o.glm)

###### And run a longer demonstration from the `h2o` package using the `demo` function:

    demo(h2o.glm)
