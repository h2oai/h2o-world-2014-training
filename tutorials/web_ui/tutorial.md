# Data Science Flow from H<sub>2</sub>O`s Web Interface

You can follow along with our video tutorial:

<iframe width="420" height="315" src="//www.youtube.com/embed/DL00ZSSTjOM" frameborder="0" allowfullscreen></iframe>

## Step 1: Import Data

The airlines data set we are importing is a subset of the data made available by [RITA](http://www.transtats.bts.gov/OT_Delay/OT_DelayCause1.asp) with a mix of numeric and factor columns. In the following tutorial we will build multiple classification models predicting for flight delays, run model comparison and score on a specific chosen model.

  * Navigate to [*Data* > *Import File*](http://localhost:54321/2/ImportFiles2.html)
  * Input into path `/data/h2o-training/airlines/allyears2k.csv` and hit Submit
  * Hit on the nfs link [*`C:\data\h2o-training\airlines\allyears2k.csv`*](http://localhost:54321/2/Parse2.query?source_key=nfs:\C:\data\h2o-training\airlines\allyears2k.csv)
  * Scroll down the page to get a preview of your data before hitting Submit again.

## Step 2: Data Summary
  * On the [data inspect page](http://localhost:54321/2/Inspect2.html?src_key=allyears2k.hex) navigate to the [*Summary*](http://localhost:54321/2/SummaryPage2.query?source=allyears2k.hex) which you can also access by [*Data* > *Summary*](http://localhost:54321/2/SummaryPage2.html)
  * Hit Submit to get a summary of all the columns in the data:
	  * Numeric Columns: Min, Max, and Quantiles
	  * Factor Columns: Counts of each factor, Cardinality, NAs
 
## Step 3: Split Data into Test and Training Sets
  * Navigate back to data inspect page [*Data* > *View All* > *allyears2k.hex* > *Split Frame*](http://localhost:54321/2/FrameSplitPage.query?source=allyears2k.hex)
  * Select *shuffle* and hit Submit
  * Select [*allyears2k_suffled_part0.hex*](http://localhost:54321/2/Inspect2.html?src_key=allyears2k_shuffled_part0.hex) for the training frame

## Step 4: Build a GLM model
 

  * Go to [*Model* > *Generalized Linear Model*](http://localhost:54321/2/GLM2.html)
  * Input for *source*: `allyears2k_shuffled_part0.hex`
  * Select for *response*: `IsDepDelayed`
  * Select to ignore all columns (Ctrl+A) except for `Year`, `Month`, `DayofMonth`, `DayOfWeek`, `UniqueCarrier`, `Origin`, `Dest`,  and `Distance` (Ctrl)
  * Select for *family*: `binomial` 
  * Check *use all factor levels* and *variable importances*
  * Hit submit to start the job
  

## Step 5: Build a 50 Tree GBM model


  * Go to [*Model* > *Gradient Boosting Machine*](http://localhost:54321/2/GBM.html)
  * Input for *source*: `allyears2k_shuffled_part0.hex`
  * Select for *response*: `IsDepDelayed`
  * Select to ignore all columns (Ctrl+A) except for `Year`, `Month`, `DayofMonth`, `DayOfWeek`, `UniqueCarrier`, `Origin`, `Dest`,  and `Distance` (Ctrl)
  * Hit Submit to start the job 


## Step 6: Build a simplier 5 Tree GBM model


  * Go to [*Model* > *Gradient Boosting Machine*](http://localhost:54321/2/GBM.html)
  * Input for *source*: `allyears2k_shuffled_part0.hex`
  * Select for *response*: `IsDepDelayed`
  * Select to ignore all columns (Ctrl+A) except for `Year`, `Month`, `DayofMonth`, `DayOfWeek`, `UniqueCarrier`, `Origin`, `Dest`,  and `Distance` (Ctrl)
  * Input for *ntrees*: `5`
  * Hit Submit to start the job 
  
> On the model output page, hit the **JSON** tab.
> 
> On the model output page, hit the **JAVA** tab.


## Step 7: Deep Learning with Model Grid Search


  * Go to [*Model* > *Gradient Boosting Machine*](http://localhost:54321/2/DeepLearning.html)
  * Input for *source*: `allyears2k_shuffled_part0.hex`
  * Select for *response*: `IsDepDelayed`
  * Select to ignore all columns (Ctrl+A) except for `Year`, `Month`, `DayofMonth`, `DayOfWeek`, `UniqueCarrier`, `Origin`, `Dest`,  and `Distance` (Ctrl)
  * Input for *hidden*: `(10,10), (20,20,20)`
  * Hit Submit to start the job 

> The models are sorted by error rates. Scroll to all the way to the right to select the first model on the list.
  
## Step 8: Multimodel Scoring Engine

  * Navigate to [*Score* > *Multi model Scoring (beta)*](http://localhost:54321/steam/index.html)
  * Select data set `allyears2k.hex` and scroll to the compatible models and select `VIEW THESE MODELS...`
  * Select all the models on the left hand task bar.
  * Hit *SCORE...* and select `allyears2k_shuffled_part1.hex` and hit *OK*

> The tabular viewing of the models allows the user to have a side by side comparison of all the models.
  
### Creating Visualizations

  * Navigate to *ADVANCED* Tab to see overlaying ROC curves
  * Hit *ADD VISUALIZATION...*
  * *For the X-Axis Field* choose `Training Time (ms)`
  * *For the Y-Axis Field* choose `AUC`

> Examine the new graph you created. Weigh the value of extra gain in accuracy for time taken to train the models. Before selecting a model and copying the key of the model.


## Step 9: Create Frame with Predicted Values

  
  * Navigate back to [*Home Page* > *Score* > *Predict*](http://local:host:54321/2/Predict.html)
  * Input for *model*: paste the model key you got from Step 8
  * Input for *data*: `allyears2k_shuffled_part1.hex`
  * Input for *prediction*: `pred`


## Step 10: Export Predicted Values as CSV

  * Inspect the [prediction frame](http://localhost:54321/2/Inspect2.html?src_key=pred)
  * Select *Download as CSV*

or export any frame:

  * Navigate to [*Data* > *Export Files*](http://localhost:54321/2/ExportFiles.html)
  * Input for *src key*: `pred`
  * Input for *path*: `/data/h2o-training/airlines/pred.csv`

## Step 11: Save a model for use later

  * Navigate to [*Data* > *View All*](http://localhost:54321/StoreView.html)
  * Choose to filter by the model key
  * Hit [*Save Model*](http://localhost:54321/2/SaveModel)
  * Input for *path*: `/data/h2o-training/airlines/50TreesGBMmodel`
  * Hit Submit

## Errors?! Download and send us the log files!

  * Navigate to [*Admin* > *Inspect Log*](http://localhost:54321/LogView.html)
  * Hit *Download all logs*

## Step 12: Shutdown your H2O instance

  * Go to [*Admin* > *Shutdown*]

## Extra Bonus: Reload that saved model
  
  * In a active H<sub>2</sub>O session
  * Navigate to the [Load Model](http://localhost:54321/2/LoadModel.html)
  * Input for *path*: `/data/h2o-training/airlines/50TreesGBMmodel`
  * Hit Submit 