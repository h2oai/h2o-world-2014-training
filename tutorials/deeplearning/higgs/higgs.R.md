# Higgs Particle Discovery with H2O Deep Learning

######This tutorial shows how a Deep Learning model can be used to classify Higgs bosons. We use the [UCI HIGGS](https://archive.ics.uci.edu/ml/datasets/HIGGS/) dataset 11 million events with 28 numerical features (21 low-level detector features and 7 high-level derived features).

### START H2O and load the HIGGS data

######Initialize the H2O server and import the HIGGS dataset. For simplicity, we use a reduced dataset with the first 100k rows. The first column is the response label (0 or 1). Of course, H2O is well suited to run on the whole dataset.

    library(h2o)
    h2oServer <- h2o.init(nthreads=-1)
    
    homedir <- paste0(path.expand("~"),"/Higgs/") #modify if needed
    TRAIN = "HIGGS.100k.csv.gz"
    data_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TRAIN), header = F, sep = ',', key = 'data_hex')

######We split the dataset into 3 equal random pieces. Grid search for hyperparameter tuning and model selection will be done on the training and validation sets, and final model testing is done on the test set.

    random <- h2o.runif(data_hex, seed = 123456789)
    train_hex <- data_hex[random < .3333,]
    valid_hex <- data_hex[random >= .3333 & random < .6666,]
    test_hex  <- data_hex[random >= .6666,]
    test_hex <- h2o.assign(test_hex, "test_hex")
 
    response = 1
    low_level_predictors = c(2:22)
    low_and_high_level_predictors = c(2:29)

### Establishing the baseline performance
######We train a bunch of different H2O models with grid-search and cross-validation (GLM, RandomForest, RandomForest and DeepLearning) once using just the low-level features, and once using both low-level and high-level features. A few helper functions allow us to write simple code here and get a lot done quickly.  

    source("helper.R")

    for (preds in list(low_level_predictors, low_and_high_level_predictors)) {
      data = list(x=preds, y=response, train=train_hex, valid=valid_hex, nfolds=2)
      
      models <- c(
        h2o.fit(h2o.glm, data, 
                list(family="binomial", lambda=c(1e-5,1e-4), variable_importances=T, use_all_factor_levels=T)),
        h2o.fit(h2o.randomForest, data, 
                list(type="fast", importance=TRUE, ntree=c(5,10), depth=c(10,20))),
        h2o.fit(h2o.randomForest, data, 
                list(type="BigData", importance=TRUE, ntree=c(5,10), depth=c(10,20))),
        h2o.fit(h2o.gbm, data, 
                list(importance=TRUE, n.tree=c(20,40), interaction.depth=c(5,10))),
        h2o.fit(h2o.deeplearning, data, 
                list(variable_importances=T, l1=c(0,1e-5), hidden=list(c(50,50,50,50,50), c(30,30,30,30,30,30))))
      )
      h2o.leaderBoard(models, test_hex, response)
    }
    
    
### Fine-Tuning Deep Learning models on the low-level features alone
    data = list(x=low_level_predictors, y=response, train=train_hex, valid=valid_hex, nfolds=2)
    
    dlmodels <- c(      
      h2o.fit(h2o.deeplearning, data, list(variable_importances=T, epochs=20, hidden=c(100,100,100,100,100))),
      h2o.fit(h2o.deeplearning, data, list(variable_importances=T, epochs=20, hidden=c(200,200,200))),
    )
    h2o.leaderBoard(dlmodels, test_hex, response)
