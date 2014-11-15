# Regression using Generalized Linear Models, Gradient Boosting Machines, and Random Forests in H2O

### Load the h2o R package and start an local H2O cluster

    library(h2o)
    h2oServer <- h2o.init(nthreads = -1)

    rmLastValues <- function(pattern = "Last.value.")
    {
      keys <- h2o.ls(h2oServer, pattern = pattern)$Key
      if (!is.null(keys))
        h2o.rm(h2oServer, keys)
      invisible(keys)
    }


### Load the training and testing data into the H2O key-value store

    datadir <- "/data"
    pumsdir <- file.path(datadir, "h2o-training", "pums2013")
    trainfile <- "adult_2013_train.csv.gz"
    testfile  <- "adult_2013_test.csv.gz"
    adult_2013_train <- h2o.importFile(h2oServer,
                                       path = file.path(pumsdir, trainfile),
                                       key = "adult_2013_train", sep = ",")
    adult_2013_test <- h2o.importFile(h2oServer,
                                      path = file.path(pumsdir, testfile),
                                      key = "adult_2013_test", sep = ",")
    dim(adult_2013_train)
    dim(adult_2013_test)

### Coerce integer columns to factor columns

    facset <- c("COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX", "POBP")
    for (j in facset) {
      adult_2013_train[[j]] <- as.factor(adult_2013_train[[j]])
      adult_2013_test[[j]]  <- as.factor(adult_2013_test[[j]])
    }
    rmLastValues()

### Add a column of random categories to the training data set

    rand <- h2o.runif(adult_2013_train, seed = 123)
    randgrp <- h2o.cut(rand, seq(0, 1, by = 0.01))
    adult_2013_train <- cbind(adult_2013_train, RAND_GRP = randgrp)
    adult_2013_train <- h2o.assign(adult_2013_train, key = "adult_2013_train")
    rmLastValues()

### Fit a basic linear model

    log_wagp_glm_0 <- h2o.glm(x = "RAND_GRP", y = "LOG_WAGP",
                              data = adult_2013_train,
                              key  = "log_wagp_glm_0",
                              family = "gaussian",
                              lambda = 0)
    log_wagp_glm_0
    class(log_wagp_glm_0)
    getClassDef("H2OGLMModel")
    names(log_wagp_glm_0@model)
    coef(log_wagp_glm_0@model)

### Inspect the GLM object

    class(log_wagp_glm_0)
    getClassDef("H2OGLMModel")
    names(log_wagp_glm_0@model)
    coef(log_wagp_glm_0@model)
    log_wagp_glm_0
    log_wagp_glm_0@model$aic
    1 - log_wagp_glm_0@model$deviance / log_wagp_glm_0@model$null.deviance
    h2o.mse(h2o.predict(log_wagp_glm_0, adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    rmLastValues()

### Perform 10-fold cross-validation to measure variation in coefficient estimates

    log_wagp_glm_0_cv <- h2o.glm(x = "RAND_GRP", y = "LOG_WAGP",
                                 data = adult_2013_train,
                                 key  = "log_wagp_glm_0_cv",
                                 family = "gaussian",
                                 lambda = 0,
                                 nfolds = 10L)

    length(log_wagp_glm_0_cv@xval)
    class(log_wagp_glm_0_cv@xval[[1L]])

    boxplot(t(sapply(log_wagp_glm_0_cv@xval, function(x) coef(x@model)))[,-100L],
            names = NULL)
    points(1:99, coef(log_wagp_glm_0_cv@model)[-100L], pch = "X", col = "red")
    abline(h = 0, col = "blue")

### Explore categorical predictors

    log_wagp_glm_relp <- h2o.glm(x = "RELP", y = "LOG_WAGP",
                                 data = adult_2013_train,
                                 key  = "log_wagp_glm_relp",
                                 family = "gaussian",
                                 lambda = 0)

    log_wagp_glm_schl <- h2o.glm(x = "SCHL", y = "LOG_WAGP",
                                 data = adult_2013_train,
                                 key  = "log_wagp_glm_schl",
                                 family = "gaussian",
                                 lambda = 0)

    log_wagp_glm_relp_schl <- h2o.glm(x = "RELP_SCHL", y = "LOG_WAGP",
                                      data = adult_2013_train,
                                      key  = "log_wagp_glm_relp_schl",
                                      family = "gaussian",
                                      lambda = 0)

    log_wagp_glm_relp@model$aic
    log_wagp_glm_schl@model$aic
    log_wagp_glm_relp_schl@model$aic
    1 - log_wagp_glm_relp@model$deviance / log_wagp_glm_relp@model$null.deviance
    1 - log_wagp_glm_schl@model$deviance / log_wagp_glm_schl@model$null.deviance
    1 - log_wagp_glm_relp_schl@model$deviance / log_wagp_glm_relp_schl@model$null.deviance

### Fit an elastic net regression model across a grid of parameter settings

    addpredset <- c("COW", "MAR", "INDP", "RAC1P", "SEX", "POBP", "AGEP",
                    "WKHP", "LOG_CAPGAIN", "LOG_CAPLOSS")

    log_wagp_glm_grid <- h2o.glm(x = c("RELP_SCHL", addpredset), y = "LOG_WAGP",
                                 data = adult_2013_train,
                                 key  = "log_wagp_glm_grid",
                                 family = "gaussian",
                                 lambda_search = TRUE,
                                 nlambda = 10,
                                 return_all_lambda = TRUE,
                                 alpha = c(0, 0.25, 0.5, 0.75, 1))
    class(log_wagp_glm_grid)
    slotNames(log_wagp_glm_grid)

    class(log_wagp_glm_grid@model[[1L]])
    slotNames(log_wagp_glm_grid@model[[1L]])

    length(log_wagp_glm_grid@model[[1L]]@models)
    class(log_wagp_glm_grid@model[[1L]]@models[[1L]])

    log_wagp_glm_grid@model[[1L]]@models[[1L]]@model$params$alpha # ridge
    log_wagp_glm_grid@model[[2L]]@models[[1L]]@model$params$alpha
    log_wagp_glm_grid@model[[3L]]@models[[1L]]@model$params$alpha
    log_wagp_glm_grid@model[[4L]]@models[[1L]]@model$params$alpha
    log_wagp_glm_grid@model[[5L]]@models[[1L]]@model$params$alpha  # lasso

    log_wagp_glm_grid_mse <-
      sapply(log_wagp_glm_grid@model,
             function(x)
               sapply(x@models, function(y)
                      h2o.mse(h2o.predict(y, adult_2013_test),
                              adult_2013_test[, "LOG_WAGP"])))
    log_wagp_glm_grid_mse
    log_wagp_glm_grid_mse == min(log_wagp_glm_grid_mse)

    log_wagp_glm_best <- log_wagp_glm_grid@model[[5L]]@models[[10L]]

### Fit a gaussian regression with a log link function

    wagp_glm_grid <- h2o.glm(x = c("RELP_SCHL", addpredset), y = "WAGP",
                             data = adult_2013_train,
                             key  = "log_wagp_glm_grid",
                             family = "gaussian",
                             link   = "log",
                             lambda_search = TRUE,
                             nlambda = 10,
                             return_all_lambda = TRUE,
                             alpha = c(0, 0.25, 0.5, 0.75, 1))
    wagp_glm_grid

### Fit a gradient boosting machine regression model

    log_wagp_gbm_grid <- h2o.gbm(x = c("RELP", "SCHL", addpredset),
                                 y = "LOG_WAGP",
                                 data = adult_2013_train,
                                 key  = "log_wagp_gbm_grid",
                                 distribution = "gaussian",
                                 n.trees = c(10, 20, 40),
                                 shrinkage = c(0.05, 0.1, 0.2),
                                 validation = adult_2013_test,
                                 importance = TRUE)

    class(log_wagp_gbm_grid)
    slotNames(log_wagp_gbm_grid)
    class(log_wagp_gbm_grid@model)
    length(log_wagp_gbm_grid@model)
    class(log_wagp_gbm_grid@model[[1L]])
    log_wagp_gbm_best <- log_wagp_gbm_grid@model[[1L]]
    h2o.mse(h2o.predict(log_wagp_glm_best, adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    h2o.mse(h2o.predict(log_wagp_gbm_best, adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    rmLastValues()

### Fit a random forest regression model

    log_wagp_forest <- h2o.randomForest(x = c("RELP", "SCHL", addpredset),
                                        y = "LOG_WAGP",
                                        data = adult_2013_train,
                                        key  = "log_wagp_forest",
                                        classification = FALSE,
                                        depth = 10,
                                        ntree = 200,
                                        validation = adult_2013_test,
                                        seed = 8675309,
                                        type = "BigData")
    h2o.mse(h2o.predict(log_wagp_glm_best, adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    h2o.mse(h2o.predict(log_wagp_gbm_best, adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    h2o.mse(h2o.predict(log_wagp_forest,   adult_2013_test),
            adult_2013_test[, "LOG_WAGP"])
    rmLastValues()
