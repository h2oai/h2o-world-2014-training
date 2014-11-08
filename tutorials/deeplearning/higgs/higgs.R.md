# Higgs Particle Discovery with H<sub>2</sub>O Deep Learning

######This tutorial shows how a Deep Learning model can be used to classify Higgs bosons. We use the [UCI HIGGS](https://archive.ics.uci.edu/ml/datasets/HIGGS/) dataset 11 million events with 28 numerical features (21 low-level detector features and 7 high-level derived features).

### START H<sub>2</sub>O and load the HIGGS data

######Initialize the H<sub>2</sub>O server and import the HIGGS dataset. For simplicity, we use a reduced dataset with 100k rows, the first column is the response label (0 or 1). Of course, H2O is well suited to run on the whole dataset.

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
 
    low_level_predictors = c(2:22)
    high_level_predictors = c(23:28)
    response = 1

### Establishing the baseline performance
######We train one model each for GLM, GBM, RandomForest and DeepLearning, once using just the low-level features, and once using both low-level and high-level features.
    
    TOP_FEATURES=5
    N_FOLDS=2

  	get_auc <- function(model, data, response) {
  	   pred <- h2o.predict(model, data)[,3]
  	   perf <- h2o.performance(pred, data[,response])
  	   perf@model$auc
  	}

  	validate <- function(t0, model, modeltype, validation, response, varimp) {
  	  elapsed_seconds <- as.numeric(Sys.time()) - as.numeric(t0)
  	  modelkey <- model@key
  	  type <- modeltype
  	  auc <- get_auc(model, validation, response)
  	  result <- list(list(model, modeltype, response, elapsed_seconds, auc, varimp))
  	  names(result) <- model@key
  	  return(result)
  	}
  
  
  	lr.fit <- function(x, y, train, valid) {
  	  print(paste0("Logistic Regression with ", N_FOLDS, "-fold Cross Validation\n"))
  	  t0 <- Sys.time()
  	  model <- h2o.glm(x=x, y=y, data=train, family="binomial", nfolds=N_FOLDS, lambda_search=FALSE, higher_accuracy=TRUE, variable_importances=TRUE, use_all_factor_levels=TRUE)
  	  varimp <- paste(names(sort(abs(model@model$coefficients), TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
  	  validate(t0, model, "glm", valid, response=y, varimp)
  	}
  
  	srf.fit <- function(x, y, train, valid) {
  	  print(paste0("Fast Random Forest Grid Search with ", N_FOLDS, "-fold Cross Validation\n"))
  	  t0 <- Sys.time()
  	  model <-h2o.randomForest(type="fast", x, y, data=train, nfolds=N_FOLDS, importance=TRUE, ntree=c(10,20), depth=c(10,20))@model[[1]]
  	  varimp <- paste(names(sort(model@model$varimp[1,], TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
  	  validate(t0, model, "fast rf", valid, response=y, varimp)
  	}
  
  	drf.fit <- function(x, y, train, valid) {
  	  print(paste0("BigData Random Forest Grid Search with ", N_FOLDS, "-fold Cross Validation\n"))
  	  t0 <- Sys.time()
  	  model <-h2o.randomForest(type="BigData", x, y, data=train, nfolds=N_FOLDS, importance=TRUE, ntree=c(10,20), depth=c(10,20))@model[[1]]
  	  varimp <- paste(names(sort(model@model$varimp[1,], TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
  	  validate(t0, model, "bigdata rf", valid, response=y, varimp)
  	}
  
  	gbm.fit <- function(x, y, train, valid) {
  	  print(paste0("GBM Grid Search with ", N_FOLDS, "-fold Cross Validation\n"))
  	  t0 <- Sys.time()
  	  model <-h2o.gbm(x, y, data=train, nfolds=N_FOLDS, importance=TRUE, n.tree=c(20,40), interaction.depth=c(5,10))@model[[1]]
  	  varimp <- paste(rownames(model@model$varimp)[1:TOP_FEATURES], collapse = ",", sep = ",")
  	  validate(t0, model, "gbm", valid, response=y, varimp)
  	}
  
  	dl.fit <- function(x, y, train, valid) {
  	  print(paste0("Deep Learning Grid Search with ", N_FOLDS, "-fold Cross Validation\n"))
  	  t0 <- Sys.time()
  	  model <-h2o.deeplearning(x, y, data=train, nfolds=N_FOLDS, variable_importances=TRUE,
  	                           l1=c(0,1e-5), activation="Rectifier", epochs=10, hidden=list(c(50,50,50,50), c(30,30,30,30,30,30)))@model[[1]]
  	  varimp <- paste(names(sort(model@model$varimp[1,], TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
  	  validate(t0, model, "deeplearning", valid, response=y, varimp)
  	}
  
  
  
  	all.fit <- function(fitMethod, predictors, response, train, valid) { fitMethod(predictors, response, train, valid) }
  	model.fit.fcns <- c(lr.fit, srf.fit, drf.fit, gbm.fit, dl.fit)
  	models <- unlist(recursive = F, lapply(model.fit.fcns, all.fit, low_level_predictors, response, train_hex, valid_hex))
  
  
  	selectModel <- function(x) {
  	  c(model_key = x[[1]]@key,
  	  model_type = x[[2]],
  	  train_auc = as.numeric(x[[1]]@model$auc),
  	  validation_auc = as.numeric(x[[5]]),
  	  important_feat = x[[6]],
  	  response = x[[3]],
  	  train_time_s = as.numeric(as.character(x[[4]])))
  	}
  
  	model.list <- as.data.frame(t(as.data.frame(lapply(models, selectModel))))
  	model.list$train_auc <- as.numeric(as.character(model.list$train_auc))
  	model.list$validation_auc <- as.numeric(as.character(model.list$validation_auc))
  
#### sort the models by AUC from worst to best
  	models.sort.by.auc <- model.list[with(model.list, order(response, validation_auc)),-1]
  	models.sort.by.auc <- models.sort.by.auc[rev(rownames(models.sort.by.auc)),]
  
#### convert the `auc` and `train_time` columns into numerics
  	models.sort.by.auc$train_auc       <- as.numeric(as.character(models.sort.by.auc$train_auc))
  	models.sort.by.auc$validation_auc  <- as.numeric(as.character(models.sort.by.auc$validation_auc))
  	models.sort.by.auc$train_time      <- as.numeric(as.character(models.sort.by.auc$train_time))
  
#### display the frame
  	print(models.sort.by.auc)
  
#### score the best model on the test data
  	best_model <- h2o.getModel(h2oServer, rownames(models.sort.by.auc)[1])
  	preds <- h2o.predict(best_model, test_hex)
  	test_auc <- get_auc(best_model, test_hex, response)
  
  	cat(paste(" -------------------------------\n",
  	          "Best Model Performance On Final Testing Data:", "\n",
  	          "AUC = ", test_auc, "\n",
  	          "--------------------------------\n"))
  
  	cat(paste(" =---------Summary------------=\n",
  	            "Best model type: ", models.sort.by.auc[1,]$model_type, "\n",
  	            "Best model auc on test: ", test_auc, "\n",
  	            "Top", TOP_FEATURES, "important features: ", models.sort.by.auc[1,]$important_feat, "\n",
  	            "Model training time: ", models.sort.by.auc[1,]$train_time_s, "\n",
  	            "Training data rows: ", nrow(train_hex), "\n",
  	            "Training data cols: ", ncol(train_hex), "\n",
  	            "Validation data rows: ", nrow(valid_hex), "\n",
  	           "=----------------------------=\n"))
  	  
  	  