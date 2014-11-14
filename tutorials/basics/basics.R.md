# Basic H2O Operations in R

###### This tutorial demonstrates basic data import, manipulations, and summarizations of data within an H2O cluster from within R. It requires an installation of the h2o R package and its dependencies.

### Load the h2o R package and start an local H2O cluster

###### Connection to an H2O cloud is established through the `h2o.init` function from the `h2o` package. For the purposes of this training exercise, we will use a local H2O cluster running on the default port of `54321`. We will use the default cluster memory size of 1 GB and set `nthreads = -1` to make all the CPUs available to the H2O cluster.

    library(h2o)
    h2oServer <- h2o.init(nthreads = -1)

### Load data into the key-value store in the H2O cluster

###### This example uses a 10% sample of the Person-Level 1% 2013 Public Use Microdata Sample (PUMS) from United States Census Bureau, making it a 0.1% 2013 PUMS. We will use the `h2o.importFile` function to read the data into the key-value store in the H2O cluster.

    datadir <- "/data"
    pumsdir <- file.path(datadir, "h2o-training", "pums2013")
    csvfile <- "adult_2013_full.csv.gz"
    adult_2013_full <- h2o.importFile(h2oServer,
                                      path = file.path(pumsdir, csvfile),
                                      key = "adult_2013_full", sep = ",")

###### The `key` argument to the `h2o.importFile` function sets the name of the data set in the H2O key-value store. If the `key` argument is not supplied, the data will reside in the H2O key-value store under a machine generated name.

###### The results of the `h2o.ls` function shows the size of the object held by the `adult_2013_full` key in the H2O key-value store.

    kvstore <- h2o.ls(h2oServer)
    kvstore
    kvstore$Bytesize[kvstore$Key == "adult_2013_full"] / 1024^2

### Examine the proxy object for the H2O resident data

###### The resulting `adult_2013_full` object is of class `H2OParsedData`, which implements common methods associated with native R `data.frame` objects.

    class(adult_2013_full)
    dim(adult_2013_full)
    head(colnames(adult_2013_full), 50)

### Create an up-to-date [UCI Adult Data Set](https://archive.ics.uci.edu/ml/datasets/Adult)

###### In the interest of familiarity, let's create a data set similar to the UCI Adult Data Set that is commonly used to explore machine learning techniques. In particular, we want to extract the person's age (`AGEP`), class of worker (`COW`), educational attainment (`SCHL`), marital status (`MAR`), industry employed (`INDP`), relationship (`RELP`), race (`RAC1P`), sex (`SEX`), interest, dividends, and net rental income over the past 12 months (`INTP`), usual hours worked per week over the past 12 months (`WKHP`), place of birth (`POBP`), and wages or salary income over the past 12 months.

    nms <- c("AGEP", "COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX",
             "INTP", "WKHP", "POBP", "WAGP")
    adult_2013 <- adult_2013_full[!is.na(adult_2013_full$WAGP) &
                                  adult_2013_full$WAGP > 0, nms]
    h2o.ls(h2oServer)

###### Notice that although we created an object in R called `adult_2013`, there is no key with that value in the H2O key value store. To make it easier to track our data set, let's copy it's value to the `adult_2013` key using the `h2o.assign` function and delete all the machine generated keys with the prefix `Last.value` that served as intermediary objects using the `h2o.rm` function.

    adult_2013 <- h2o.assign(adult_2013, key = "adult_2013")
    h2o.ls(h2oServer)

    rmLastValues <- function(pattern = "Last.value.")
    {
      keys <- h2o.ls(h2oServer, pattern = pattern)$Key
      if (!is.null(keys))
        h2o.rm(h2oServer, keys)
      invisible(keys)
    }
    rmLastValues()

    kvstore <- h2o.ls(h2oServer)
    kvstore
    kvstore$Bytesize[kvstore$Key == "adult_2013"] / 1024^2

### Summarize the 2013 update of the UCI Adult Data Set

    summary(adult_2013)
    dim(adult_2013)

    centiles <- quantile(adult_2013$WAGP, probs = seq(0, 1, by = 0.01))
    centiles

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Create capital gain and capital loss columns

    capgain <- ifelse(adult_2013$INTP > 0, adult_2013$INTP, 0)
    caploss <- ifelse(adult_2013$INTP < 0, abs(adult_2013$INTP), 0)
    adult_2013$CAPGAIN <- capgain
    adult_2013$CAPLOSS <- caploss
    adult_2013 <- adult_2013[,- match("INTP", colnames(adult_2013))]
    adult_2013 <- h2o.assign(adult_2013, key = "adult_2013")

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Create log transformations for income variables

    adult_2013$LOG_CAPGAIN <- log(adult_2013$CAPGAIN + 1L)
    adult_2013$LOG_CAPLOSS <- log(adult_2013$CAPLOSS + 1L)
    adult_2013$LOG_WAGP    <- log(adult_2013$WAGP    + 1L)

### Create categorical transformations for income variables

    cutpoints <- centiles
    cutpoints[1L] <- 0
    adult_2013$CENT_WAGP <- h2o.cut(adult_2013$WAGP, cutpoints)
    adult_2013$TOP2_WAGP <- adult_2013$WAGP > centiles[99L]

    centcounts <- h2o.table(adult_2013["CENT_WAGP"], return.in.R = TRUE)
    round(100 * centcounts/sum(centcounts), 2)

    top2counts <- h2o.table(adult_2013["TOP2_WAGP"], return.in.R = TRUE)
    round(100 * top2counts/sum(top2counts), 2)

    relpxtabs <- h2o.table(adult_2013[c("RELP", "TOP2_WAGP")], return.in.R = TRUE)
    relpxtabs
    round(100 * relpxtabs/rowSums(relpxtabs), 2)

    schlxtabs <- h2o.table(adult_2013[c("SCHL", "TOP2_WAGP")], return.in.R = TRUE)
    schlxtabs
    round(100 * schlxtabs/rowSums(schlxtabs), 2)

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Coerce integer columns to factor columns

    facset <- c("COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX", "POBP")
    for (j in facset)
      adult_2013[[j]] <- as.factor(adult_2013[[j]])

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Create pairwise interaction terms for linear modeling

    inter2013 <- h2o.interaction(adult_2013, factors = c("RELP", "SCHL"),
                                 pairwise = TRUE, max_factors = 10000,
                                 min_occurrence = 10)
    adult_2013 <- cbind(adult_2013, inter2013)
    adult_2013 <- h2o.assign(adult_2013, key = "adult_2013")

    h2o.ls(h2oServer)
    rmLastValues()

    kvstore <- h2o.ls(h2oServer)
    kvstore
    kvstore$Bytesize[kvstore$Key == "adult_2013"] / 1024^2

### Create training and test data sets to use during modeling

    rand <- h2o.runif(adult_2013, seed = 1185)
    adult_2013_train <- adult_2013[rand <= 0.75, ]
    adult_2013_train <- h2o.assign(adult_2013_train, key = "adult_2013_train")
    adult_2013_test <- adult_2013[rand  > 0.75, ]
    adult_2013_test <- h2o.assign(adult_2013_test, key = "adult_2013_test")

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

    nrow(adult_2013)
    nrow(adult_2013_train)
    nrow(adult_2013_test)
