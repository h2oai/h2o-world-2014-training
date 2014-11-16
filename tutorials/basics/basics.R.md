# Basic H2O Operations in R

###### This tutorial demonstrates basic data import, manipulations, and summarizations of data within an H2O cluster from within R. It requires an installation of the h2o R package and its dependencies.

### Load the h2o R package and start an local H2O cluster

###### Connection to an H2O cloud is established through the `h2o.init` function from the `h2o` package. For the purposes of this training exercise, we will use a local H2O cluster running on the default port of `54321`. We will also use the default cluster memory size and set `nthreads = -1` to make all the CPUs available to the H2O cluster.

    library(h2o)
    h2oServer <- h2o.init(nthreads = -1)

### Load data into the key-value store in the H2O cluster

###### This tutorial uses a 10% sample of the Person-Level 1% 2013 Public Use Microdata Sample (PUMS) from United States Census Bureau, making it a Person-Level 0.1% 2013 PUMS. We will use the `h2o.importFile` function to read the data into the H2O key-value store.

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

###### The resulting `adult_2013_full` object is of class `H2OParsedData`, which implements methods commonly associated with native R `data.frame` objects.

    class(adult_2013_full)
    dim(adult_2013_full)
    head(colnames(adult_2013_full), 50)

### Create an up-to-date UCI Adult Data Set

###### In the interest of familiarity, we will create a data set similar to the [UCI Adult Data Set](https://archive.ics.uci.edu/ml/datasets/Adult) from the University of California Irvine (UCI) Machine Learning Repository. In particular, we want to extract the age of person (`AGEP`), class of worker (`COW`), educational attainment (`SCHL`), marital status (`MAR`), industry employed (`INDP`), relationship (`RELP`), race (`RAC1P`), sex (`SEX`), interest/dividends/net rental income over the past 12 months (`INTP`), usual hours worked per week over the past 12 months (`WKHP`), place of birth (`POBP`), and wages/salary income over the past 12 months.

    nms <- c("AGEP", "COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX",
             "INTP", "WKHP", "POBP", "WAGP")
    adult_2013 <- adult_2013_full[!is.na(adult_2013_full$WAGP) &
                                  adult_2013_full$WAGP > 0, nms]
    h2o.ls(h2oServer)

###### Although we created an object in R called `adult_2013`, there is no value with that key in the H2O key-value store. To make it easier to track our data set, we will copy it's value to the `adult_2013` key using the `h2o.assign` function and delete all the machine generated keys with the prefix `Last.value` that served as intermediary objects using the `h2o.rm` function.

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

###### As mentioned above, an R proxy object to an H2O data set implements several methods commonly associated with R `data.frame` objects including the `summary` function to obtain column-level summaries and the `dim` function to get the row and column count

    summary(adult_2013)
    dim(adult_2013)

###### As with R `data.frame` objects, individual columns within an H2O data set can be summarized using methods commonly associated with R `vector` objects. For example, the `quantile` function in R is used to find sample quantiles at probability values specified in the `prob` argument.

    centiles <- quantile(adult_2013$WAGP, probs = seq(0, 1, by = 0.01))
    centiles

###### The use of the `$` operator to extract the column `WAGP` from the `adult_2013` data set generated new `Last.value` keys that we will clean up in the interest of maintaining a tidy key-value store.

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Derive columns: capital gain and capital loss columns

###### The original UCI Adult Data Set contains columns for capital gain and capital loss, which can be extracted from the `INTP` column within the Person-Level PUMS data set. We will derive these two columns using the `ifelse` function where the test condition is whether the `INTP` column is positive or negative, and if that condition is met, the value is either `INT` (capital gain) / `- INT` (capital loss) or `0`. If we were just interested in measure the magnitude of either a loss or a gain, we could have used the `abs` function.

    capgain <- ifelse(adult_2013$INTP > 0, adult_2013$INTP, 0)
    caploss <- ifelse(adult_2013$INTP < 0, - adult_2013$INTP, 0)
    adult_2013$CAPGAIN <- capgain
    adult_2013$CAPLOSS <- caploss
    adult_2013 <- adult_2013[,- match("INTP", colnames(adult_2013))]

###### Now that we have the capital gain and loss columns, we can assign our new data set to the `adult_2013` key and remove all the temporary keys from the H2O key-value store.

    adult_2013 <- h2o.assign(adult_2013, key = "adult_2013")

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Derive columns: log transformations for income variables

###### The UCI Adult Data Set was originally created to predict whether a person's income in the early 1990s exceeds $50,000 per year. Given that incomes are right-skewed, transforming these measures to a log scale tends to make them more conducive to use in predictive modeling.

    adult_2013$LOG_CAPGAIN <- log(adult_2013$CAPGAIN + 1L)
    adult_2013$LOG_CAPLOSS <- log(adult_2013$CAPLOSS + 1L)
    adult_2013$LOG_WAGP    <- log(adult_2013$WAGP    + 1L)

###### Now that we have the log transformed columns, we can assign our new data set to the `adult_2013` key and remove all the temporary keys from the H2O key-value store.

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Create cross-tabulations of original and derived categorical variables

###### We will begin an analysis of wages by exploring the pairwise relationships between wage groups subdivided into percentiles and the variables we will use as predictors in our statistical models. In the code below the `h2o.cut` function create the wage groups and the `h2o.table` function to performs the cross-tabulations.

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

###### Perform a key-value store clean up.

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Coerce integer columns to factor (categorical) columns

###### As with standard R integer vectors, integer columns in H2O can be converted to a categorical type using an `as.factor` method. For our data set we have 8 columns that use integer codes to represent categorical levels.

    for (j in c("COW", "SCHL", "MAR", "INDP", "RELP", "RAC1P", "SEX", "POBP"))
      adult_2013[[j]] <- as.factor(adult_2013[[j]])

###### Perform a key-value store clean up.

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)

### Create pairwise interaction terms for linear modeling

###### While some modeling approaches, such as gradient boosting machines (GBM), random forests, and deep learning, are able to derive interactions between terms during the modeling training stage, other modeling approaches, such as generalized linear models (GLM), require interactions to be user defined inputs. We will use the `h2o.interaction` function to generate a new column in our data set that pairs relationship (`RELP`) with education attainment (`SCHL`) to form a new column labeled `RELP_SCHL` that we will "column bind" to our data set using a `cbind` method.

    inter_2013 <- h2o.interaction(adult_2013, factors = c("RELP", "SCHL"),
                                  pairwise = TRUE, max_factors = 10000,
                                  min_occurrence = 10)
    adult_2013 <- cbind(adult_2013, inter_2013)
    adult_2013 <- h2o.assign(adult_2013, key = "adult_2013")

###### Now that we have derived a few sets of variables, we can examine the H2O key-value store to ensure we have the expected objects.

    h2o.ls(h2oServer)
    rmLastValues()

    kvstore <- h2o.ls(h2oServer)
    kvstore
    kvstore$Bytesize[kvstore$Key == "adult_2013"] / 1024^2

### Generate group by aggregates

###### In addition to cross-tabulations, we can create more detailed group by aggregates using the `h2o.ddply` function that was inspired by the `ddply` function from Hadley Wickham's [plyr](http://cran.r-project.org/web/packages/plyr/index.html) package, which is hosted on the Comprehensive R Archive Network (CRAN).

    wagpSummary <- function(frame) {
      cbind(N      = length(frame$WAGP),
            Min    = min(frame$WAGP),
            Median = median(frame$WAGP),
            Max    = max(frame$WAGP),
            Mean   = mean(frame$WAGP),
            StdDev = sd(frame$WAGP))
    }
    h2o.addFunction(h2oServer, wagpSummary)
    statsByGroup <- as.data.frame(h2o.ddply(adult_2013, "RELP", wagpSummary))
    colnames(statsByGroup)[-1L] <- c("N", "Min", "Median", "Mean", "Max", "StdDev")
    statsByGroup <- statsByGroup[order(statsByGroup$median, decreasing = TRUE), ]
    rownames(statsByGroup) <- NULL
    statsByGroup

### Create training and test data sets to use during modeling

###### As a final step in an exploration of H2O basics in R, we will create a 75% / 25% split, where the larger data set will be used for training a model and the smaller data set will be used for testing the usefulness of the model. We will achieve this by using the `h2o.runif` function to generate random uniforms over `[0, 1]` for each row and using those random values to determine the split designation for that row.

    rand <- h2o.runif(adult_2013, seed = 1185)
    adult_2013_train <- adult_2013[rand <= 0.75, ]
    adult_2013_train <- h2o.assign(adult_2013_train, key = "adult_2013_train")
    adult_2013_test <- adult_2013[rand  > 0.75, ]
    adult_2013_test <- h2o.assign(adult_2013_test, key = "adult_2013_test")

###### Now check to make sure the size of the resulting data sets meet expectations.

    nrow(adult_2013)
    nrow(adult_2013_train)
    nrow(adult_2013_test)

###### Perform a key-value store clean up.

    h2o.ls(h2oServer)
    rmLastValues()
    h2o.ls(h2oServer)
