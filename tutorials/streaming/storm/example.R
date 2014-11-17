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
df <- h2o.importFile(h, normalizePath("./training_data.csv"));
y <- "Label"
x <- c("Has4Legs","CoatColor","HairLength","TailLength","EnjoysPlay","StairsOutWindow","HoursSpentNapping","RespondsToCommands","EasilyFrightened","Age", "Noise1", "Noise2", "Noise3", "Noise4", "Noise5")
gbm.h2o.fit <- h2o.gbm(data = df, y = y, x = x, n.trees = 10)

cat("Downloading Java prediction model code from H2O\n")
model_key <- gbm.h2o.fit@key
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

cat("Note: H2O will shut down automatically if it was started by this R script and the script exits\n")
