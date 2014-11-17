### Interaction Features on Synthetic Data
###### Use `h2o.createFrame` to create some random data in H2O. This method can also be used to quickly create very large datasets for scaling tests. Note that there is no intrinsic structure in the data, so results from supervised learning algorithms will not be very meaningful.
    
    myframe = h2o.createFrame(localH2O, 'framekey', rows = 20, cols = 5,
                              seed = -12301283, randomize = TRUE, value = 0,
                              categorical_fraction = 0.8, factors = 10, real_range = 1,
                              integer_fraction = 0.2, integer_range = 10, missing_fraction = 0.2,
                              response_factors = 1)
    
###### We created a small random frame in H2O that contains missing values, categorical and numerical columns.

    head(myframe,20)
  
    #         response    C1    C2 C3    C4    C5
    #    1  -0.4227451 4a41c a1290  3 326a0 82dce
    #    2   0.4594655 0a79a a1290 -6 05f22 f4772
    #    3   0.2784008 70d75 4c3a7  7 320a8 6b17b
    #    4  -0.5674698       07067  6 320a8 a78d9
    #    5  -0.7041911 24800 4c3a7  8       82dce
    #    6   0.5853957 8e64f a1290 NA ea644      
    #    7   0.8540204              4 05f22 a6b1e
    #    8  -0.1466706 4a41c        1 cef5a 89717
    #    9          NA 0a79a c402d  3 070d5 a78d9
    #    10 -0.7357408 4a41c a1290  9 e055d 64439
    #    11 -0.2798403       4c3a7  3       f4772
    #    12  0.3454386 24800       NA            
    #    13         NA 0a79a ca1de  9 070d5 a78d9
    #    14 -0.6732674 8e64f 50b47  9 320a8 6b17b
    #    15         NA cc3d5 ca1de  4 e055d f4772
    #    16         NA cc3d5 07067  1 070d5 89717
    #    17  0.8564855 4f8b9 a1290 -1 326a0 6b17b
    #    18 -0.5555804 0a79a 50b47 NA       82dce
    #    19  0.5639324              3 e055d      
    #    20  0.2511743              7 30c85 cae4c

###### We remove the response column and convert the integer column to a factor.

    myframe <- myframe[,-1]
    myframe[,3] <- as.factor(myframe$C3)
    summary(myframe)
    head(myframe, 20)

###### Create pairwise interactions
    
    pairwise <- h2o.interaction(myframe, key = 'pairwise', factors = list(c(1,2),c(2,3,4)),
                                pairwise=TRUE, max_factors = 10, min_occurrence = 1)
    head(pairwise, 20)
    levels(pairwise[,2])

###### Create 5-th order interaction
    
    higherorder <- h2o.interaction(myframe, key = 'higherorder', factors = c(1,2,3,4,5),
                                   pairwise=FALSE, max_factors = 10000, min_occurrence = 1)
    head(higherorder, 20)

######Create a categorical variable out of integer column via self-interaction, and keep at most 3 factors, and only if they occur at least twice
    
    summary(myframe$C3)
    head(myframe$C3, 20)
    trim_integer_levels <- h2o.interaction(myframe, key = 'trim_integers', factors = 3,
                                           pairwise = FALSE, max_factors = 3, min_occurrence = 2)
    head(trim_integer_levels, 20)

###### Put all together and clean up temporaries
    
    myframe <- cbind(myframe, pairwise, higherorder, trim_integer_levels)
    myframe <- h2o.assign(myframe, 'final.key')
    h2o.rm(localH2O, grep(pattern = "Last.value", x = h2o.ls(localH2O)$Key, value = TRUE))
    myframe
    head(myframe,20)
    summary(myframe)

    #    > head(myframe,20)
    #          C1    C2 C3    C4    C5       C1_C2    C2_C3       C2_C4    C3_C4             C1_C2_C3_C4_C5 C3_C3
    #    1  49ed9 d9ff0  3 c9523 00599 49ed9_d9ff0  d9ff0_3 d9ff0_c9523    other  49ed9_d9ff0_3_c9523_00599     3
    #    2  e2271 d9ff0 -6 fe2d9 cb67d e2271_d9ff0 d9ff0_-6 d9ff0_fe2d9 -6_fe2d9 e2271_d9ff0_-6_fe2d9_cb67d other
    #    3  408d2 6c5ce  7 28b4d 3e4cb 408d2_6c5ce    other       other    other  408d2_6c5ce_7_28b4d_3e4cb other
    #    4        ae93f  6 28b4d da0c6       other    other       other    other     NA_ae93f_6_28b4d_da0c6 other
    #    5  722ea 6c5ce  8       00599 722ea_6c5ce    other    6c5ce_NA     8_NA     722ea_6c5ce_8_NA_00599 other
    #    6  5e310 d9ff0 NA 9dbca       5e310_d9ff0 d9ff0_NA       other    other    5e310_d9ff0_NA_9dbca_NA      
    #    7               4 fe2d9 8d2b5       NA_NA    other    NA_fe2d9  4_fe2d9        NA_NA_4_fe2d9_8d2b5 other
    #    8  49ed9        1 87bef 92d9c    49ed9_NA     NA_1       other  1_87bef     49ed9_NA_1_87bef_92d9c     1
    #    9  e2271 14aa5  3 d77b0 da0c6       other  14aa5_3 14aa5_d77b0  3_d77b0  e2271_14aa5_3_d77b0_da0c6     3
    #    10 49ed9 d9ff0  9 79727 b7a40 49ed9_d9ff0    other       other    other  49ed9_d9ff0_9_79727_b7a40     9
    #    11       6c5ce  3       cb67d    NA_6c5ce  6c5ce_3    6c5ce_NA     3_NA        NA_6c5ce_3_NA_cb67d     3
    #    12 722ea       NA                722ea_NA    NA_NA       NA_NA    NA_NA          722ea_NA_NA_NA_NA      
    #    13 e2271 0036a  9 d77b0 da0c6       other    other 0036a_d77b0  9_d77b0  e2271_0036a_9_d77b0_da0c6     9
    #    14 5e310 0a9ed  9 28b4d 3e4cb       other    other       other    other  5e310_0a9ed_9_28b4d_3e4cb     9
    #    15 f76de 0036a  4 79727 cb67d       other    other       other    other  f76de_0036a_4_79727_cb67d other
    #    16 f76de ae93f  1 d77b0 92d9c       other  ae93f_1 ae93f_d77b0  1_d77b0  f76de_ae93f_1_d77b0_92d9c     1
    #    17 853d4 d9ff0 -1 c9523 3e4cb 853d4_d9ff0 d9ff0_-1 d9ff0_c9523    other 853d4_d9ff0_-1_c9523_3e4cb other
    #    18 e2271 0a9ed NA       00599       other 0a9ed_NA    0a9ed_NA    NA_NA    e2271_0a9ed_NA_NA_00599      
    #    19              3 79727             NA_NA    other       other    other           NA_NA_3_79727_NA     3
    #    20              7 8007d 1280c       NA_NA    other    NA_8007d  7_8007d        NA_NA_7_8007d_1280c other

### Imputation of Missing Values
###### First, we randomly replace 50 rows in each column of the iris dataset with missing values

    ds <- iris
    ds[sample(nrow(ds), 50),1] <- NA
    ds[sample(nrow(ds), 50),2] <- NA
    ds[sample(nrow(ds), 50),3] <- NA
    ds[sample(nrow(ds), 50),4] <- NA
    ds[sample(nrow(ds), 50),5] <- NA
    summary(ds)

###### upload the NA'ed dataset to H2O
    
    hex <- as.h2o(localH2O, ds)
    head(hex,20)

###### Impute the NAs in the first column in place with "median"
    
    h2o.impute(hex, "Sepal.Length", method = "median")
    head(hex,20)

###### Impute the NAs in the second column with the mean based on the groupBy columns Sepal.Length and Petal.Width and Species
    
    h2o.impute(hex, "Sepal.Width", method = "mean", groupBy = c("Sepal.Length", "Petal.Width", "Species"))
    head(hex,20)

###### Impute the Species column with the "mode" based on the columns 1 and 4
    
    h2o.impute(hex, 5, method = "mode", groupBy = c(1,4))
    head(hex,20)
    
    
### Splitting H2O Frames into Consecutive Subsets
###### First, we create a large frame

    myframe = h2o.createFrame(localH2O, 'large', rows = 1000000, cols = 10,
                              seed = -12301283, randomize = TRUE, value = 0,
                              categorical_fraction = 0.8, factors = 10, real_range = 1,
                              integer_fraction = 0.2, integer_range = 10, missing_fraction = 0.2,
                              response_factors = 1)
    dim(myframe)
    
###### Now, we split that dataset into 4 consecutive pieces, so we need to specify the sizes of the first 3 splits

    splits <- h2o.splitFrame(myframe, c(0.4,0.2,0.1))
    dim(splits[[1]])
    dim(splits[[2]])
    dim(splits[[3]])
    dim(splits[[4]])

### Splitting H2O Frames into Random Subsets
###### We create a 1D vector with uniform values sampled from the interval 0...1 and use that to assign rows to the splits.

    random <- h2o.runif(myframe, seed = 123456789)
    train <- myframe[random < .8,]
    valid <- myframe[random >= .8 & random < 0.9,]
    test  <- myframe[random >= .9,]
    dim(train)
    dim(valid)
    dim(test)
