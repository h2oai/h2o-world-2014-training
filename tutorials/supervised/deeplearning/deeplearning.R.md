# Classification and Regression with H2O Deep Learning

######This tutorial shows how a [Deep Learning](http://en.wikipedia.org/wiki/DeepLearning) model can be used to do supervised classification and regression. This file is both valid R and markdown code. We use the well-known [MNIST](http://yann.lecun.com/exdb/mnist/) dataset of hand-written digits, where each row contains the 28^2=784 raw gray-scale pixel values from 0 to 255 of the digitized digits (0 to 9). 

### Start H2O and load the MNIST data

######Initialize the H2O server and import the MNIST training/testing datasets.

    library(h2o)
    h2oServer <- h2o.init(nthreads=-1)
    homedir <- paste0(path.expand("~"),"/h2o/") #modify if needed
    TRAIN = "smalldata/mnist/train.csv.gz"
    TEST = "smalldata/mnist/test.csv.gz"
    train_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TRAIN), header = F, sep = ',', key = 'train.hex')
    test_hex <- h2o.importFile(h2oServer, path = paste0(homedir,TEST), header = F, sep = ',', key = 'test.hex')
 
###Our first Deep Learning classification model

######It's easy to run Deep Learning, it's just like the other classifiers of H2O. Automatic data standardization and handling of categorical variables or missing values makes it easy to get results quickly.

    dlmodel <- h2o.deeplearning(x = c(1:784), y=785, data=train_hex, validation=test_hex, epochs=1)

######Let's look at the model summary, and the confusion matrix and classification error (on the validation set) in particular:

    dlmodel
    dlmodel@model$confusion
    dlmodel@model$valid_class_error

######To see the model parameters that were used, access the model@model$params field:
    
    dlmodel@model$params
    
######As you can see, there are a lot of parameters!  Luckily, you only need to know a few to get the most out of Deep Learning.  You can get the R documentation help here:

    ?h2o.deeplearning
    
###Hyper-parameter tuning with grid search
######Most parameters in Deep Learning are "grid-able":

    grid_search <- h2o.deeplearning(x = c(1:784), y=785, data=train_hex, validation=test_hex, epochs=0.1,
                                    activation=c("Tanh", "Rectifier"), l1=c(0,1e-5))
                                
######Let's see which parameters "won":

    grid_search
    
    best_model <- grid_search@model[[1]]
    best_params <- best_model@model$params
    best_params$activation
    best_params$l1
    
###Checkpointing
######Let's continue training the best model, for 2 more epochs. Note that since many parameters such as `epochs, l1, l2, max_w2, score_interval, train_samples_per_iteration, target_ratio_comm_to_comp, score_duty_cycle, classification_stop, regression_stop, variable_importances, force_load_balance` can be modified between checkpoint restarts, it is best to specify as many parameters as possible explicitly.

    dlmodel_restart <- h2o.deeplearning(x=c(1:784), y=785, data=train_hex, validation=test_hex,
                                checkpoint = best_model, l1=best_params$l1, epochs=0.5)

    dlmodel_restart@model$valid_class_error

######Once we are satisfied with the results, we can save the model to disk:

    h2o.saveModel(dlmodel_restart, dir="/tmp", name="mybest_mnist_model", force=T)

######It can be loaded later with
    
    dlmodel_loaded <- h2o.loadModel(h2oServer, "/tmp/mybest_mnist_model")
    
######Of course, you can continue training this model as well (with the same `x`, `y`, `data`, `validation`)

    dlmodel_restart_again <- h2o.deeplearning(x=c(1:784), y=785, data=train_hex, validation=test_hex,
                                checkpoint = dlmodel_loaded, l1=best_params$l1, epochs=0.5)

###World-class results on MNIST
######To get test set errors of less than 1% on MNIST, run the following command on your cluster (takes a few hours):

    model <- h2o.deeplearning(x = c(1:784), y = 785, data = train_hex, validation = test_hex,
                              activation = "RectifierWithDropout", hidden = c(1024,1024,2048),
                              epochs = 1000, l1 = 1e-5, input_dropout_ratio = 0.2,
                              train_samples_per_iteration = -1, classification_stop = -1)

######Note: results are not 100% reproducible and depend on the number of nodes, cores, etc. Sometimes, it helps to run the initial convergence with more train_samples_per_iteration (automatic values of -2 or -1 are good choices), and then continue from a checkpoint with a smaller number (automatic value of 0 or a number less than the total number of training rows are good choices here).

###Regression
######If the response column is numeric and non-integer, regression is enabled by default.  For integer response columns, as in this case, you have to specify `classification=FALSE` to force regression.  In that case, there will be only 1 output neuron, and the loss function and error metric will automatically switch to the MSE (mean square error).

    regression_model <- h2o.deeplearning(x = c(1:784), y=785, data=train_hex, validation=test_hex, epochs=1, 
                                         classification=FALSE)

######Let's look at the model summary, and the training and validation set MSE values:

    regression_model
    regression_model@model$train_sqr_error
    regression_model@model$valid_sqr_error
    
######Otherwise, regression Deep Learning models are just like classification models.

###Important Tips & Tricks

#### Override with best model
######By default, `override_with_best_model` is set to TRUE and the model returned at the end of model building (after specified number of epochs or after reaching the specified limits of convergence) is the model that has the best training set error, or, if a validation set is provided, the lowest validation set error.

#### train_samples_per_iteration

#### score_validation_samples

#### Lift

####Categorical Data

######For categorical data, the factor levels are automatically one-hot encoded (horizontalized), so the input neuron layer 
can grow substantially for datasets with high factor counts


####Missing Values
######H2O Deep Learning automatically does mean imputation for missing values.


######*Note:* Every run of DeepLearning results in different results since we use [Hogwild!](http://www.eecs.berkeley.edu/~brecht/papers/hogwildTR.pdf) parallelization with intentional race conditions between threads.  To get reproducible results at the expense of speed for small datasets, set reproducible=T and specify a seed.

### More information can be found in the [H2O Deep Learning booklet](https://t.co/kWzyFMGJ2S) and in our [slides](http://www.slideshare.net/0xdata/presentations).
