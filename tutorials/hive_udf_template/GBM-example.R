rmLastValues <- function(pattern = "Last.value.")
{
  keys <- h2o.ls(h2oServer, pattern = pattern)$Key
  if (!is.null(keys))
    h2o.rm(h2oServer, keys)
  invisible(keys)
}

# "Safe" system.  Error checks process exit status code.  stop() if it failed.
safeSystem <- function(x) {
   print(sprintf("+ CMD: %s", x))
   res <- system(x)
   print(res)
   if (res != 0) {
       msg <- sprintf("SYSTEM COMMAND FAILED (exit status %d)", res)
       stop(msg)
   }
}

myIP <- "localhost"
myPort <- 54321

library(h2o)
h2oServer <- h2o.init(ip = myIP, port = myPort, startH2O = TRUE)


pumsdir <- file.path("/Users/myhomedir/data/pums2013")
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

actual_log_wagp <- h2o.assign(adult_2013_test[, "LOG_WAGP"],
                              key = "actual_log_wagp")
rmLastValues()

for (j in c("COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX", "POBP")) {
  adult_2013_train[[j]] <- as.factor(adult_2013_train[[j]])
  adult_2013_test[[j]]  <- as.factor(adult_2013_test[[j]])
}
rmLastValues()

predset <- c("RELP", "SCHL", "COW", "MAR", "INDP", "RAC1P", "SEX", "POBP", "AGEP",
                "WKHP", "LOG_CAPGAIN", "LOG_CAPLOSS")

log_wagp_gbm_grid <- h2o.gbm(x = predset,
                             y = "LOG_WAGP",
                             data = adult_2013_train,
                             key  = "log_wagp_gbm_grid",
                             distribution = "gaussian",
                             interaction.depth = c(5, 7),
                             n.trees = 110,
                             shrinkage = c(0.25, 0.275),
                             validation = adult_2013_test,
                             importance = TRUE)
log_wagp_gbm_grid


log_wagp_gbm_best <- log_wagp_gbm_grid@model[[1L]]
log_wagp_gbm_best

model_key <- log_wagp_gbm_best@key
tmpdir_name <- "generated_model"
cmd <- sprintf("rm -fr %s", tmpdir_name)
safeSystem(cmd)
cmd <- sprintf("mkdir %s", tmpdir_name)
safeSystem(cmd)
cmd <- sprintf("curl -o %s/GBMPojo.java http://%s:%d/2/GBMModelView.java?_modelKey=%s", tmpdir_name, myIP, myPort, model_key)
safeSystem(cmd)
cmd <- sprintf("curl -o %s/h2o-model.jar http://127.0.0.1:54321/h2o-model.jar", tmpdir_name)
safeSystem(cmd)
cmd <- sprintf("sed -i '' 's/class %s/class GBMPojo/' %s/GBMPojo.java", model_key, tmpdir_name)
safeSystem(cmd)

h2o.predict(log_wagp_gbm_best, adult_2013_test)

h2o.mse(h2o.predict(log_wagp_gbm_best, adult_2013_test),
        actual_log_wagp)