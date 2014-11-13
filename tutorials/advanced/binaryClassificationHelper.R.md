    TOP_FEATURES = 5
    
    h2o.get_auc <- function(model, data, response) {
      pred <- h2o.predict(model, data)[,3]
      perf <- h2o.performance(pred, data[,response])
      perf@model$auc
    }
    
    h2o.varimp <- function(algo, model) {
      if (identical(algo, h2o.glm)) {
        varimp <- paste(names(sort(abs(model@model$normalized_coefficients), TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
      } else if (identical(algo, h2o.randomForest) || identical(algo, h2o.deeplearning)) {
        varimp <- paste(names(sort(model@model$varimp[1,], TRUE))[1:TOP_FEATURES], collapse = ",", sep = ",")
      } else if (identical(algo, h2o.gbm)) {
        varimp <- paste(rownames(model@model$varimp)[1:TOP_FEATURES], collapse = ",", sep = ",")
      }
      varimp
    }
    
    h2o.validate <- function(t0, model, modeltype, validation, response, varimp) {
      elapsed_seconds <- as.numeric(Sys.time()) - as.numeric(t0)
      modelkey <- model@key
      type <- modeltype
      auc <- h2o.get_auc(model, validation, response)
      result <- list(list(model, modeltype, response, elapsed_seconds, auc, varimp))
      names(result) <- model@key
      return(result)
    }
    
    h2o.fit <- function(algo, data, args) {
      t0 <- Sys.time()
      predictors <- data$x
      response <- data$y
      train <- data$train
      valid <- data$valid
      nfolds <- data$nfolds
      if (nfolds >= 0) {
        model <- do.call(algo, modifyList(list(x=predictors, y=response, data=train, nfolds=nfolds), args))
      } else {
        model <- do.call(algo, modifyList(list(x=predictors, y=response, data=train), args))
      }
      if (.hasSlot(model,"sumtable")) {
        model <- model@model[[1]]
      }
      return(h2o.validate(t0, model, as.character(substitute(algo)), valid, response, h2o.varimp(algo, model)))
    }
    
    h2o.selectModel <- function(x) {
      c(model_key = x[[1]]@key,
        model_type = x[[2]],
        train_auc = as.numeric(x[[1]]@model$auc),
        validation_auc = as.numeric(x[[5]]),
        important_feat = x[[6]],
        tuning_time_s = as.numeric(as.character(x[[4]])))
    }
    
    h2o.leaderBoard <- function(models, test_hex, response) {
      model.list <- as.data.frame(t(as.data.frame(lapply(models, h2o.selectModel))))
      model.list$train_auc <- as.numeric(as.character(model.list$train_auc))
      model.list$validation_auc <- as.numeric(as.character(model.list$validation_auc))
      
      #### sort the models by AUC from worst to best
      models.sort.by.auc <- model.list[with(model.list, order(validation_auc)),-1]
      models.sort.by.auc <- models.sort.by.auc[rev(rownames(models.sort.by.auc)),]
    
      #### convert the `auc` and `tuning_time` columns into numerics
      models.sort.by.auc$train_auc       <- as.numeric(as.character(models.sort.by.auc$train_auc))
      models.sort.by.auc$validation_auc  <- as.numeric(as.character(models.sort.by.auc$validation_auc))
      models.sort.by.auc$tuning_time_s   <- as.numeric(as.character(models.sort.by.auc$tuning_time_s))
      
      #### display the frame
      print(models.sort.by.auc)
      
      #### score the best model on the test data
      best_model <- h2o.getModel(h2oServer, rownames(models.sort.by.auc)[1])
      preds <- h2o.predict(best_model, test_hex)
      test_auc <- h2o.get_auc(best_model, test_hex, response)
      
      cat(paste(" -------------------------------\n",
                "Best Model Performance On Final Testing Data:", "\n",
                "AUC = ", round(test_auc,6), "\n",
                "--------------------------------\n"))
      
      cat(paste(" =---------Summary------------=\n",
                "Best model type: ", models.sort.by.auc[1,]$model_type, "\n",
                "Best model AUC on test: ", round(test_auc,6), "\n",
                "Top", TOP_FEATURES, "important features: ", models.sort.by.auc[1,]$important_feat, "\n",
                "Model training time (incl. tuning, grid search): ", round(models.sort.by.auc[1,]$tuning_time_s,6), "seconds \n",
                "Training data rows: ", nrow(train_hex), "\n",
                "Training data cols: ", ncol(train_hex), "\n",
                "Validation data rows: ", nrow(valid_hex), "\n",
                "=----------------------------=\n"))
      best_model
    }