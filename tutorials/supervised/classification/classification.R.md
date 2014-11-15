# Classification using Generalized Linear Models, Gradient Boosting Machines, and Random Forests in H2O

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

### Fit a basic logistic regression model

    top2_wagp_glm_relp <- h2o.glm(x = "relp", y = "TOP2_WAGP",
                                  data = adult_2013_train,
                                  key  = "top2_wagp_glm_relp",
                                  family = "binomial",
                                  lambda = 0)
    top2_wagp_glm_relp

    actual_top2_wagp <- h2o.assign(adult_2013_test[, "TOP2_WAGP"],
                                   key = "actual_top2_wagp")

    pred_top2_wagp_glm_relp <- h2o.predict(top2_wagp_glm_relp, adult_2013_test)
    pred_top2_wagp_glm_relp

    prob_top2_wagp_glm_relp <- pred_top2_wagp_glm_relp[, 3L]

    f1_top2_wagp_glm_relp <- h2o.performance(prob_top2_wagp_glm_relp,
                                             actual_top2_wagp,
                                             measure = "F1")
    f1_top2_wagp_glm_relp
    class(f1_top2_wagp_glm_relp)
    plot(f1_top2_wagp_glm_relp, type = "cutoffs", col = "blue")
    plot(f1_top2_wagp_glm_relp, type = "roc", col = "blue", typ = "b")

    slotNames(f1_top2_wagp_glm_relp)
    class(f1_top2_wagp_glm_relp@model)
    names(f1_top2_wagp_glm_relp@model)

    class_top2_wagp_glm_relp <-
      pred_top2_wagp_glm_relp[, 3L] > f1_top2_wagp_glm_relp@model$best_cutoff
    h2o.confusionMatrix(class_top2_wagp_glm_relp, actual_top2_wagp)
    h2o.gains(actual_top2_wagp, class_top2_wagp_glm_relp)

    rm(pred_top2_wagp_glm_relp,
       prob_top2_wagp_glm_relp,
       class_top2_wagp_glm_relp)
    rmLastValues()

### Fit an elastic net regression model across a grid of parameter settings

    addpredset <- c("COW", "MAR", "INDP", "RAC1P", "SEX", "POBP", "AGEP",
                    "WKHP", "LOG_CAPGAIN", "LOG_CAPLOSS")

    top2_wagp_glm_grid <- h2o.glm(x = c("RELP_SCHL", addpredset),
                                  y = "TOP2_WAGP",
                                  data = adult_2013_train,
                                  key  = "top2_wagp_glm_grid",
                                  family = "binomial",
                                  lambda_search = TRUE,
                                  nlambda = 10,
                                  return_all_lambda = TRUE,
                                  alpha = c(0, 0.25, 0.5, 0.75, 1))
    class(top2_wagp_glm_grid)
    slotNames(top2_wagp_glm_grid)

    class(top2_wagp_glm_grid@model[[1L]])
    slotNames(top2_wagp_glm_grid@model[[1L]])

    length(top2_wagp_glm_grid@model[[1L]]@models)
    class(top2_wagp_glm_grid@model[[1L]]@models[[1L]])

    top2_wagp_glm_grid@model[[1L]]@models[[1L]]@model$params$alpha # ridge
    top2_wagp_glm_grid@model[[2L]]@models[[1L]]@model$params$alpha
    top2_wagp_glm_grid@model[[3L]]@models[[1L]]@model$params$alpha
    top2_wagp_glm_grid@model[[4L]]@models[[1L]]@model$params$alpha
    top2_wagp_glm_grid@model[[5L]]@models[[1L]]@model$params$alpha  # lasso

    top2_wagp_glm_grid_f1 <-
      sapply(top2_wagp_glm_grid@model,
             function(x)
               sapply(x@models, function(y)
                 h2o.performance(h2o.predict(y, adult_2013_test)[, 3L],
                                 actual_top2_wagp,
                                 measure = "F1")@model$error
               ))
    top2_wagp_glm_grid_f1
    top2_wagp_glm_grid_f1 == min(top2_wagp_glm_grid_f1)

    top2_wagp_glm_best <- top2_wagp_glm_grid@model[[4L]]@models[[7L]]

    prob_top2_wagp_glm_best <- h2o.predict(top2_wagp_glm_best, adult_2013_test)[, 3L]
    f1_top2_wagp_glm_best <- h2o.performance(prob_top2_wagp_glm_best,
                                             actual_top2_wagp,
                                             measure = "F1")
    plot(f1_top2_wagp_glm_best, type = "cutoffs", col = "blue")
    plot(f1_top2_wagp_glm_best, type = "roc", col = "blue")

    table(coef(top2_wagp_glm_best@model) != 0)
    nzcoefs <- coef(top2_wagp_glm_best@model)
    nzcoefs <- names(nzcoefs)[nzcoefs != 0]
    nzcoefs <- unique(sub("\\..*$", "", nzcoefs))
    setdiff(c("RELP_SCHL", addpredset), nzcoefs) # all preds had non-zero coefs

### Fit a gradient boosting machine regression model

    top2_wagp_gbm_grid <- h2o.gbm(x = c("RELP", "SCHL", addpredset),
                                  y = "TOP2_WAGP",
                                  data = adult_2013_train,
                                  key  = "top2_wagp_gbm_grid",
                                  distribution = "multinomial",
                                  n.trees = c(10, 20, 40),
                                  shrinkage = c(0.05, 0.1, 0.2),
                                  validation = adult_2013_test,
                                  importance = TRUE)

    class(top2_wagp_gbm_grid)
    slotNames(top2_wagp_gbm_grid)
    class(top2_wagp_gbm_grid@model)
    length(top2_wagp_gbm_grid@model)
    class(top2_wagp_gbm_grid@model[[1L]])
    top2_wagp_gbm_best <- top2_wagp_gbm_grid@model[[1L]]
    h2o.performance(h2o.predict(top2_wagp_glm_best, adult_2013_test)[, 3L],
                    actual_top2_wagp, measure = "F1")@model$error
    h2o.performance(h2o.predict(top2_wagp_gbm_best, adult_2013_test)[, 3L],
                    actual_top2_wagp, measure = "F1")@model$error
    rmLastValues()

### Fit a random forest regression model

    top2_wagp_forest <- h2o.randomForest(x = c("RELP", "SCHL", addpredset),
                                         y = "TOP2_WAGP",
                                         data = adult_2013_train,
                                         key  = "top2_wagp_forest",
                                         classification = TRUE,
                                         depth = 10,
                                         ntree = 200,
                                         validation = adult_2013_test,
                                         seed = 8675309,
                                         type = "BigData")
    h2o.performance(h2o.predict(top2_wagp_glm_best, adult_2013_test)[, 3L],
                    actual_top2_wagp, measure = "F1")@model$error
    h2o.performance(h2o.predict(top2_wagp_gbm_best, adult_2013_test)[, 3L],
                    actual_top2_wagp, measure = "F1")@model$error
    h2o.performance(h2o.predict(top2_wagp_forest,   adult_2013_test)[, 3L],
                    actual_top2_wagp, measure = "F1")@model$error
    rmLastValues()
