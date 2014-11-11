# Higgs Particle Discovery with H2O Deep Learning

######This tutorial shows how H2O can be used to classify particle detector events into Higgs bosons vs background noise.
#####![](images/higgs.png)
### HIGGS dataset and Deep Learning
######We use the [UCI HIGGS](https://archive.ics.uci.edu/ml/datasets/HIGGS/) dataset with 11 million events and 28 features (21 low-level features and 7 humanly created non-linear derived features). In this tutorial, we show that (only) Deep Learning can automatically generate these high-level features on its own and reach highest accuracies from just the low-level features alone, outperforming traditional classifiers. Deep Learning also won the [Higgs Kaggle challenge](https://www.kaggle.com/c/higgs-boson/forums/t/10425/code-release).



### Start H2O, import the HIGGS data, and prepare train/validation/test splits

######Initialize the H2O server (enable all cores)

    library(h2o)
    h2oServer <- h2o.init(nthreads=-1)
 

###### Import the data: For simplicity, we use a reduced dataset containing the first 100k rows.

    homedir <- paste0(path.expand("~"),"/Higgs/") #modify if needed
    TRAIN = "higgs.100k.csv.gz"
    data_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TRAIN), header = F, sep = ',', key = 'data_hex')

###### Prepare train/validation/test splits: We split the dataset randomly into 3 pieces. Grid search for hyperparameter tuning and model selection will be done on the training and validation sets, and final model testing is done on the test set. We also assign the resulting frames to meaningful names in the H2O key-value store for later use, and clean up all temporaries at the end.

    random <- h2o.runif(data_hex, seed = 123456789)
    train_hex <- h2o.assign(data_hex[random < .8,], "train_hex")
    valid_hex <- h2o.assign(data_hex[random >= .8 & random < .9,], "valid_hex")
    test_hex  <- h2o.assign(data_hex[random >= .9,], "test_hex")
    h2o.rm(h2oServer, grep(pattern = "Last.value", x = h2o.ls(h2oServer)$Key, value = TRUE))
 
######The first column is the response label (background:0 or higgs:1). Of the 28 numerical features, the first 21 are low-level detector features and the last 7 are high-level humanly derived features (physics formulae).
  
    response = 1
    low_level_predictors = c(2:22)
    low_and_high_level_predictors = c(2:29)

### Establishing the baseline performance reference
######To get a feel for the performance of different classifiers on this dataset, we train a variety of different H2O models (Generalized Linear Model, Random Forest, Gradient Boosted Machines and DeepLearning). We use grid-search for hyper-parameter tuning with N-fold cross-validation. We do this twice: once using just the low-level features, and once using both low- and high-level features. A few helper functions allow us to write simple code here and get a lot done quickly. The code below trains 30 models and presents a leaderboard of the best cross-validated models.

    source("helper.R") #provides h2o.fit and h2o.leaderBoard functions

    best_model <- list()
    for (preds in list(low_level_predictors, low_and_high_level_predictors)) {
      data = list(x=preds, y=response, train=train_hex, valid=valid_hex, nfolds=2) #helper object
      
      models <- c(
        h2o.fit(h2o.glm, data, 
                list(family="binomial", variable_importances=T, lambda=c(1e-5,1e-4), use_all_factor_levels=T)),
        h2o.fit(h2o.randomForest, data, 
                list(type="fast", importance=TRUE, ntree=c(20), depth=c(10,15))),
        h2o.fit(h2o.randomForest, data, 
                list(type="BigData", importance=TRUE, ntree=c(20), depth=c(10,15))),
        h2o.fit(h2o.gbm, data, 
                list(importance=TRUE, n.tree=c(50), interaction.depth=c(5,10))),
        h2o.fit(h2o.deeplearning, data, 
                list(variable_importances=T, l1=c(1e-5), epochs=10, hidden=list(c(20,20,20), c(100,100))))
      )
      best_model <- list(best_model, h2o.leaderBoard(models, test_hex, response))
      h2o.rm(h2oServer, grep(pattern = "Last.value", x = h2o.ls(h2oServer)$Key, value = TRUE))
    }
    
###### The output contains a leaderboard for the models using low-level features only:
    
                           model_type       train_auc validation_auc         important_feat tuning_time_s
    DeepLearning_b66c683b5 h2o.deeplearning 0.6893312      0.7129937        C7,C8,C2,C3,C11     23.248843
    GBM_8dc7e2d1e9af4134ce h2o.gbm          0.6809625      0.6967311        C2,C7,C11,C5,C3     21.851729
    DRF_bdf39041d97bd27952 h2o.randomForest 0.6628614      0.6747544       C7,C10,C2,C11,C5     27.094487
    SpeeDRF_9f8d7b12e71cdc h2o.randomForest 0.6560579      0.6669454       C7,C10,C11,C2,C5     25.451095
    GLMModel__9e1f194a999f h2o.glm          0.5878547      0.6018250 Intercept,C5,C7,C2,C14      1.421268

###### The leaderboard and AUC values change when using both low- and high-level features:
    
                           model_type       train_auc validation_auc      important_feat tuning_time_s
    GBM_843035f744a4c7176b h2o.gbm          0.7934576      0.8025840  C27,C29,C28,C26,C7     30.110100
    DeepLearning_8c0278d12 h2o.deeplearning 0.7785513      0.8008010 C27,C28,C24,C29,C26     26.387754
    DRF_858682a5760320ccac h2o.randomForest 0.7765047      0.7826946  C27,C29,C28,C24,C7     36.408610
    SpeeDRF_83e1d6903bdeef h2o.randomForest 0.7700895      0.7760240  C27,C29,C28,C24,C7     40.042133
    GLMModel__9888b66c3f9d h2o.glm          0.6817290      0.6949037  C29,C28,C27,C24,C7      1.401122

###### Clearly, the high-level features add a lot of predictive power. On this sample dataset and with simple models across the board, Deep Learning seems to have an edge over tree-based methods when using low-level features only, indicating that it is able to create useful high-level features on its own in a short amount of time.

###### *Note:* Every run of DeepLearning results in different results since we use [Hogwild!](http://www.eecs.berkeley.edu/~brecht/papers/hogwildTR.pdf) parallelization with intentional race conditions between threads.  To get reproducible results at the expense of speed for small datasets, set reproducible=T and specify a seed.

### Build an improved Deep Learning model on the low-level features alone
###### This time, we build a "reasonable" Deep Learning model on the train/validation splits directly (without parameter tuning, grid search or N-fold cross-validation):
    h2o.deeplearning(x=low_level_predictors, y=response, activation="RectifierWithDropout", data=train_hex, validation=valid_hex,
                     input_dropout_ratio=0, hidden_dropout_ratios=c(0.2,0.1,0), l1=1e-5, l2=1e-5, epochs=20, hidden=c(200,200,200))

###### With a better Deep Learning model, we achieve train/validation AUCs of 0.76/0.72, a nice boost over the simple models above.
AUC =  0.7683884 (on train) 

AUC =  0.7254769 (on validation)     
    
######Please note that this tutorial was on a small subsample (<1%) of the original dataset, and results are not comparable. Previous results by H2O Deep Learning on the full dataset (training on 10M rows, validation on 500k rows, testing on 500k rows) agree with a recently published Nature paper on using [Deep Learning for Higgs particle detection](http://www.slideshare.net/0xdata/how-to-win-data-science-competitions-with-deep-learning/33), where 5-layer H2O Deep Learning models have achieved test set AUC values of 0.869. We would love to hear about your best models!
#### More information can be found in the [H2O Deep Learning booklet](https://t.co/kWzyFMGJ2S) and in our [slides](http://www.slideshare.net/0xdata/presentations).