# Feature Engineering on the Adult dataset

######This tutorial shows feature engineering on the [Adult dataset](https://archive.ics.uci.edu/ml/datasets/Adult). This file is both valid R and markdown code.

### Start H2O and load the Adult data

######Initialize the H2O server and import the Adult dataset.

    library(h2o)
    h2oServer <- h2o.init(nthreads=-1)
    homedir <- "/data/h2o-training/adult/"
    TRAIN = "adult.gz"
    data_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TRAIN), header = F, sep = ' ', key = 'data_hex')

######We manually assign column names since they are missing in the original file.
    
    colnames(data_hex) <- c("age","workclass","fnlwgt","education","education-num","marital-status","occupation","relationship","race","sex","capital-gain","capital-loss","hours-per-week","native-country","income")
    summary(data_hex)

######We will try to predict whether `income` is `<=50K` or `>50K`.
    summary(data_hex$income)
    response = "income"

######First, we source a few [helper functions](../binaryClassificationHelper.R.html) that allow us to quickly compare a multitude of binomial classification models, in particular the h2o.fit() and h2o.leaderBoard() functions.  Note that these specific functions require variable importances and N-fold cross-validation to be enabled.

    source("~/h2o-training/tutorials/advanced/binaryClassificationHelper.R.md")

###### We then add this simple helper function to split a frame into train/valid/test pieces, train a GLM and a GBM model with 2-fold cross-validation and obtaining the best model after printing a leaderbaord. For more accurate

    N_FOLDS = 2

    h2o.trainModels <- function(frame) {
      # split the data into train/valid/test
      random <- h2o.runif(frame, seed = 123456789)
      train_hex <- h2o.assign(frame[random < .8,], "train_hex")
      valid_hex <- h2o.assign(frame[random >= .8 & random < .9,], "valid_hex")
      test_hex  <- h2o.assign(frame[random >= .9,], "test_hex")
     
      predictors <- colnames(frame)[-match(response,colnames(frame))]
      
      # multi-model comparison with N-fold cross-validation
      data = list(x=predictors, y=response, train=train_hex, valid=valid_hex, nfolds=N_FOLDS)
      models <- c(
        h2o.fit(h2o.glm, data, glmparams),
        h2o.fit(h2o.gbm, data, gbmparams)
      )
      best_model <- h2o.leaderBoard(models, test_hex, match(response,colnames(frame)))
  
      h2o.rm(h2oServer, grep(pattern = "Last.value", x = h2o.ls(h2oServer)$Key, value = TRUE))
      best_model
    }

### Baseline performance on original dataset
###### For simplicity, we use default parameters (no grid search parameter tuning) to establish baseline performance numbers for this dataset.

    glmparams <- list(family="binomial", variable_importances=T, use_all_factor_levels=T)
    gbmparams <- list(importance=TRUE)

    best_model <- h2o.trainModels(data_hex)

###### Both GLM and GBM do a great job at this dataset, we get validation AUC values of above 90%: `GLM: 0.9028564 GBM: 0.9009924`
###### According to GBM, the most important columns are `marital-status,relationship,capital-gain,education-num,age`

### Feature engineering
 
###### The following section shows ways to create new derived features. We'll need this simple append function, as we're going to add new columns the our dataset

    h2o.append <- function(frame, col) {
      appended_frame <- h2o.assign(cbind(frame, col), "appended_frame")
      appended_frame
    }

####1. Turn age into a factor
######The feature `age` is an integer value, but GLM for example will have a tough time predicing income from age with a linear relationship, while GBM should be able to carve out these non-linear dependencies by itself (but it might need more trees, deeper interaction depth than default values)
 
    data_hex <- h2o.append(data_hex, as.factor(data_hex$age))
    colnames(data_hex)
    summary(data_hex)
    best_model <- h2o.trainModels(data_hex)

###### GLM clearly benefited from this. We see that ages 18,19 and 20 are among the most important predictors for income and we get the following validation AUC values: `GLM: 0.9066634 GBM: 0.9009924`

###### For fun, let's look at the largest positively and negatively correlated coefficients:

    head(sort(best_model@model$normalized_coefficients,decreasing=T),5)
    head(sort(best_model@model$normalized_coefficients,decreasing=F),5)

####2. Same for capital-gain/loss and work hours per week
  
    data_hex <- h2o.append(data_hex, as.factor(data_hex$'hours-per-week'))
    data_hex <- h2o.append(data_hex, as.factor(data_hex$'capital-gain'))
    data_hex <- h2o.append(data_hex, as.factor(data_hex$'capital-loss'))
    colnames(data_hex)
    summary(data_hex)
    best_model <- h2o.trainModels(data_hex)

###### With all these new factor levels as predictors, GLM now got a nice boost: `GLM: 0.9285384 GBM: 0.9021225`

###### Let's give GBM a shot at beating GLM by using better parameters:

    gbmparams <- list(importance=TRUE, n.tree=50, interaction.depth=10)
    best_model <- h2o.trainModels(data_hex)

###### Ok, now both algorithms reach similar validation AUC values: `GLM: 0.9285384 GBM: 0.9286973`

### Replace money-related integer columns by their Log-Transform
    
    data_hex$'capital-gain'   <- log(1+data_hex$'capital-gain')
    data_hex$'capital-loss'   <- log(1+data_hex$'capital-loss')
    data_hex
    best_model <- h2o.trainModels(data_hex)
    
######We see that the training AUC for GLM improves slightly, from `0.9269056070` to `0.9269586507`. Intuition: Money is often distributed exponentially, and the log transform brings it back to a linear space. Note that the validation AUC drops, likely due to small data statistical noise. We clearly got close to the limit of this dataset. Note that GBM didn't benefit from this transform, it seems to be able to better split up the original integer space.

    frame <- data_hex
    random <- h2o.runif(frame, seed = 123456789)
    train_hex <- h2o.assign(frame[random < .8,], "train_hex")
    valid_hex <- h2o.assign(frame[random >= .8 & random < .9,], "valid_hex")
    test_hex  <- h2o.assign(frame[random >= .9,], "test_hex")
    
    predictors <- colnames(frame)[-match(response,colnames(frame))]
    
    # multi-model comparison with N-fold cross-validation
    data = list(x=predictors, y=response, train=train_hex, valid=valid_hex, nfolds=N_FOLDS)
    models <- c(
      h2o.fit(h2o.deeplearning, data, list())
    )
    best_model <- h2o.leaderBoard(models, test_hex, match(response,colnames(frame)))
  