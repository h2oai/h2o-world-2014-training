# Marketing Usecases - KDDCup98
####Use KDDCup98 dataset to design an intelligent direct mail campaign to maximize the overall profit (R tryout vs H2O solution)

## - Use the dataset with selected features to try to run random forests on R

        rm(list=ls())
        setwd("/data/h2o-training/")
        Kdd98 <- read.csv("cup98LRN_z.csv")
        

        featureSet <- c("ODATEDW", "OSOURCE", "STATE", "ZIP", "PVASTATE", "DOB", "RECINHSE", "MDMAUD", "DOMAIN", "CLUSTER", "AGE", 
        "HOMEOWNR", "CHILD03", "CHILD07",  "CHILD12", "CHILD18", "NUMCHLD", "INCOME", "GENDER", "WEALTH1", "HIT", "COLLECT1", 
        "VETERANS", "BIBLE", "CATLG", "HOMEE", "PETS", "CDPLAY", "STEREO", "PCOWNERS", "PHOTO", "CRAFTS", "FISHER", "GARDENIN", 
        "BOATS",  "WALKER", "KIDSTUFF", "CARDS", "PLATES", "PEPSTRFL", "CARDPROM", "MAXADATE", "NUMPROM", "CARDPM12", "NUMPRM12", 
        "RAMNTALL", "NGIFTALL", "CARDGIFT", "MINRAMNT", "MAXRAMNT", "LASTGIFT", "LASTDATE", "FISTDATE", "TIMELAG", "AVGGIFT", 
        "HPHONE_D", "RFA_2F", "RFA_2A", "MDMAUD_R", "MDMAUD_F", "MDMAUD_A", "CLUSTER2", "GEOCODE2", "TARGET_D")




        kdd98 <- Kdd98[, setdiff(featureSet, c("CONTROLN", "TARGET_B"))]
        ls()
        library(randomForest)
        rf <- randomForest(TARGET_D ~ ., data=kdd98)

######You'll quickly see an error message - "Error in na.fail.default(list(TARGET_D = c(0, 0, 0, 0, 0, 0, 0, 0, 0,  :   missing values in object"

		library(party)
		cf <- cforest(TARGET_D ~ ., data= kdd98, control = cforest_unbiased(mtry=2, ntree=50))
		
		
######After a while, a window will pop up showing "Unable to establish connection with R session". In order to continue to use Rstudio, you may go to the task manager to kill rsession. This demonstrates cforest runs out of memory for this trimmed dataset and cannot return any results.

## - Use the complete dataset to run big data random forest with H2O

#####Let's use H2O to build a big data random forest model and predict who to mail and how much profit the fund-raising campaign may generate. 
#####To run H2O on your VM, double click the H2O icon on your VM desktop. 
#####Then open a browser, type localhost:54321 to access H2O web UI. 
#####Let's start uploading the datasets, build the model, and do prediction.
#####Name the prediction key "drf_prediction" and download to csv after predicting. 

##-- Evaluate the total profit from the prediction 
#####After getting the prediction, then run this with the H2O prediction.
        kdd98v <- read.csv("cup98VAL_z.csv")		# read test data
        kdd_pred = read.csv("drf_prediction.csv")		# read prediction value
        kdd_pred_val <- apply(kdd_pred,1,function(row) if (row[1] > 0.68) 1 else 0 )
        kdd98_withpred <- cbind(kdd98v, kdd_pred_val)
        dim(kdd98v)
        dim(kdd98_withpred)
        kdd98_withpred$yield <- apply(kdd98_withpred,1,function(row) (as.numeric(row['TARGET_D']) - 0.68) * as.numeric(row[483]))



        sum(kdd98_withpred$yield)			# profit
        max(kdd98_withpred$yield)			# max donation
        sum(kdd_pred_val)				# mails sent



