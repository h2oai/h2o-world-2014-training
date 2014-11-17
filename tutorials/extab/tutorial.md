# Excel and Tableau - Beauty and Big Data

## Tableau

Download [Tableau](http://www.tableausoftware.com/) in order to use notebooks available on our [github](https://github.com/0xdata/h2o/tree/master/tableau).

### How does Tableau play with H2O?

Tableau is the frontend visual organizer that utilizes all the available statistic tools from open source R and H2O. Tableau will connect to R via a socket server using a library package already built for R. The H2O client package available for installation allows R to connect and communicate to H2O via a REST API. So by connecting Tableau to R, Tableau essentially can launch or initiate H2O and run any of the features already available for R.


### R Component

First, make sure to [install H<sub>2</sub>O](http://docs.0xdata.com/Ruser/Rinstall.html#r-installation) in R:

```
> install.packages("h2o")
```

Then install the Rserve package in R that will allow the user to start up a R session on a local server that Tableau will communicate with:

```
> install.packages("Rserve")
> library("Rserve")
> run.Rserve(port = 6311)
```

### Tableau Front End

  * **Step 1: Connection Setup**
	  
	Open Demo_Template_8.1.twb which should have all the calculated fields containing R script already in the sidebar.

	Navigate to “Help > Settings and Performance > Manage R Connection” to establish a connection to the R serve.
	
  * **Step 2: Data Connection**
  	
	Set the workbook’s connection to the airlines_meta.csv data by navigating to the data section on the left sidebar, right clicking on the airlines_meta and choosing to “Edit Connection.”

  * **Step 3: H2O Initialization**

	Configure the IP Address and Port that H2O will launch at as well as the path to the full airlines data file.
 
  * **Step 4: Data Import**
	
	Execute “00 Load H2O and Tableau functions” to run:

	```
	> library(h2o)
	> tableauFunctions <- functions(x){
	> ...
	> }
	> print('Finish loading necessary functions')
	```

	Execute “01 Init H2O & Parse Data” to:

	```
	> library(h2o)
	> localH2O = h2o.init(ip = "localhost", port = 54321, nthreads = -1)
	> data = h2o.importFile(localH2O, "/data/h2o-training/airlines/allyears2k.csv")
	```

	Execute “02 Compute Aggregation with H2O’s ddply” to groupby columns and do roll ups. First calculate the number of flights coming and going per month:
	```
	numFlights = ddply(data.hex, 'Month', nrow)
	numFlights.R = as.data.frame(numFlights)
	```
	
	Then compute the number of cancelled flights per month:

	```
	fun2 = function(df) {sum(df$Cancelled)}
	h2o.addFunction(h2oLocal, fun2)
	canFlights = ddply(data.hex, 'Month', fun2)
	canFlights.R = as.data.frame(canFlights)
	```
	
	Execute “03 Run GLM” to build a GLM model in H2O and grab back coefficient values that will be plotted in multiple worksheets:

	```
	data.glm = h2o.glm(x = c('Origin', 'Dest', 'Distance', 'Unique Carrier') , y = 'Cancelled', data = data.hex, family = 'binomial', nfolds = 0, standardize=TRUE)
	```

  * After the calculated fields finishes running, scroll through the different dashboards to see data differently.


## Using Excel with H<sub>2</sub>O

When working with excel the HTTP call to H2O will elicit a response in XML format that Microsoft excel can parse in both 32-bit and 64-bit version. For excel users that are already familiar with excel features and functions, this tutorial will work you through some basic H2O capabilities written in VBA. So the the demonstration excel file has to be macro enabled to access all the point and click features.

•	If no instance of H2O is launched yet:
1.	Input IP address and port you wish to launch at.
2.	Choose the number of instances and the size of each instance.
3.	Choose the version of h2o you’ll like to use, by default excel chooses master build in your GIT target repository.
4.	Hit “Launch Instance.” A command prompt will load for each instance you indicate you want, wait for message “Cloud of size <instance number> formed” before closing pop up window “Launching H2O – Wait for all nodes to launch before closing.”
•	If H2O has already been launched, either previously via command prompt, on R, or on a Hadoop cluster:
1.	Input IP address and port you wish to connect to, instance number and heap size can be bypassed.
2.	Hit “Launch Instance,” to connect.



Import Data and Load Summary  
1.	Either find your file using “Data File” prompt or input the path to the data file in entry “File Path.”
2.	Hit “Import and Parse,” and you can check the status of the parse down by the lower left hand corner:
 
    
3.	The entry “H2O Data Hex Key” should automatically fill in with the destination key of the hex file now sitting in H2O.
 

 
 

4.	After which “Generate Summary” will list out all the columns in the dataset and some general statistics. All columns except “NA%” are taken directly from H2O’s inspect page, only “NA%” is calculated using the “NA Count” column and dividing it by the number of rows in the data set which can be calculated using function =/h2onumrow(h2oHexKey) :
 
Note: The red highlighted values indicate large number of NA values in the column and suggest ignoring such columns.


 
Build GLM Model
 

1.	Response Variable should auto-populate, choose the response from the drop down. Then hit “Populate Predictor Variables,” which will eliminate the response variable from the Predictor Variables as well as highlight the variables with high NA counts to ignore. 
2.	Select any other variables you’ll like to ignore before hitting “Ignore Predictor Variables.”
3.	Fill in other information such as the family of distribution, lambda, alpha, and the number of cross validation you want to run. Once satisfied submit your parameters and wait for the GLM to finish running:
 

4.	The Model Key and Parameters should auto populate with the destination key of the model and the parameters that went into building the model respectively.
 
5.	Choose to “Show Output” to show the coefficients from a GLM model, from here the values are all numeric and strings that user can manipulate to create different visuals, the default is a simple bar graph:
 


