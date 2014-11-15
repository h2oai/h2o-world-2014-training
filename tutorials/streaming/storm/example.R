#
# Example R code for generating an H2O Scoring POJO.
#

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

library(h2o)

cat("Starting H2O\n")
myIP <- "localhost"
myPort <- 54321
h <- h2o.init(ip = myIP, port = myPort, startH2O = TRUE)

cat("Building GBM model\n")
df <- h2o.importFile(h, "training_data.csv");
gbm.fit <- h2o.gbm(data = df, y = "", x = c(), ntrees = 10)

cat("Downloading Java prediction model code from H2O\n")
model_key <- iris.gbm.h2o@key
tmpdir_name <- "tmpmodel"
cmd <- sprintf("rm -fr %s", tmpdir_name)
safeSystem(cmd)
cmd <- sprintf("mkdir %s", tmpdir_name)
safeSystem(cmd)
cmd <- sprintf("curl -o %s/%s.java http://%s:%d/2/GBMModelView.java?_modelKey=%s", tmpdir_name, model_key, myIP, myPort, model_key)
safeSystem(cmd)

h2o.shutdown(h)
