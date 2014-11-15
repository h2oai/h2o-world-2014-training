# Real-time Predictions With H2O on Storm

This tutorial shows how to create a [Storm](https://storm.apache.org/) topology can be used to make real-time predictions with H2O.This file is both valid R and markdown code.

## Where to find the latest version of this tutorial

* <https://github.com/0xdata/h2o-training/tree/master/tutorials/streaming/storm/storm.md>

## 1.  Overview of this tutorial




## 1.  Install required software

### 1.1.  Clone the required repos from Github

`$ git clone https://github.com/apache/storm.git`  
`$ git clone https://github.com/0xdata/h2o-training.git`  


### 1.2.  Install R

Get the [latest version of R from CRAN](http://www.r-project.org/index.html) and install it on your computer.

### 1.3  Install the H2O package for R

(Start an R session)  
`R> install.packages("h2o")`  


## 2.  Build the H2O model [POJO](http://en.wikipedia.org/wiki/Plain_Old_Java_Object)

