# Feature Engineering on the Adult dataset

######This tutorial shows feature engineering on the [Adult dataset](https://archive.ics.uci.edu/ml/datasets/Adult). This file is both valid R and markdown code.

### Start H2O and load the Adult data

######Initialize the H2O server and import the Adult dataset.

    library(h2o)
    h2oServer <- h2o.init()
    homedir <- paste0(path.expand("~"),"/h2o/") #modify if needed
    TRAIN = "smalldata/adult.gz"
    data_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TRAIN), header = F, sep = ' ', key = 'data_hex')
    colnames(data_hex) <- c("age","workclass","fnlwgt","education","education-num","marital-status","occupation","relationship","race","sex","capital-gain","capital-loss","hours-per-week","native-country","income")
    summary(data_hex)
 
###### Prepare train/validation/test splits: We split the dataset randomly into 3 pieces. Grid search for hyperparameter tuning and model selection will be done on the training and validation sets, and final model testing is done on the test set. We also assign the resulting frames to meaningful names in the H2O key-value store for later use, and clean up all temporaries at the end.

    splitData <- function(data_hex) {
        random <- h2o.runif(data_hex, seed = 123456789)
        train_hex <- h2o.assign(data_hex[random < .8,], "train_hex")
        valid_hex <- h2o.assign(data_hex[random >= .8 & random < .9,], "valid_hex")
        test_hex  <- h2o.assign(data_hex[random >= .9,], "test_hex")
     }
    
######Yada
 
    response = 15

### Build a model without feature engineering

####1. Vanilla GLM model
######Yada

    source("helper.R")

    freeMem <- function() {
        h2o.rm(h2oServer, grep(pattern = "Last.value", x = h2o.ls(h2oServer)$Key, value = TRUE))
    }
    append <- function(data_hex, col) {
      data_hex <- h2o.assign(cbind(data_hex, col), "data_hex")
      data_hex
    }
    
######Yada
    glmparams <- list(family="binomial", variable_importances=T, lambda=1e-5, higher_accuracy=T, use_all_factor_levels=T, alpha=0.5)
    gbmparams <- list(importance=TRUE)
    
    runModel <- function(data_hex) {
      splitData(data_hex)
      train_hex <- h2o.getFrame(h2oServer, "train_hex")
      valid_hex <- h2o.getFrame(h2oServer, "valid_hex")
      test_hex <- h2o.getFrame(h2oServer, "test_hex")
      predictors <- colnames(data_hex)[-response]
      
      best_model <- list()
      data = list(x=predictors, y=response, train=train_hex, valid=valid_hex, nfolds=5) #helper object
      models <- c(
        h2o.fit(h2o.glm, data, glmparams),
        h2o.fit(h2o.gbm, data, gbmparams)
      )
      best_model <- list(best_model, h2o.leaderBoard(models, test_hex, response))
      freeMem()
    }

    
    runModel(data_hex)
    
####2. Turn integer columns into categoricals
######Age
 
    data_hex <- append(data_hex, as.factor(data_hex$age))
    colnames(data_hex)
    summary(data_hex)
    runModel(data_hex)

######Same for capital-gain/loss and work hours per week
    data_hex <- append(data_hex, as.factor(data_hex$'hours-per-week'))
    data_hex <- append(data_hex, as.factor(data_hex$'capital-gain'))
    data_hex <- append(data_hex, as.factor(data_hex$'capital-loss'))
    colnames(data_hex)
    summary(data_hex)
    runModel(data_hex)
      


####3. Add pair-wise interactions between selected factors
######Yada
 
    factor_interactions <- h2o.interaction(data_hex, factors = c("education","workclass","occupation"), pairwise = TRUE, max_factors = 1000, min_occurrence = 1)
    data_hex <- append(data_hex, factor_interactions)
    colnames(data_hex)
    summary(data_hex)
    runModel(data_hex)
    
######Update model parameters to better use of all factor levels
    glmparams <- list(family="binomial", variable_importances=F, lambda=1e-6, higher_accuracy=T, use_all_factor_levels=T, alpha=1)
    gbmparams <- list(importance=T)
    runModel(data_hex)
