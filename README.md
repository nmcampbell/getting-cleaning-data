---
title: "Getting & Cleaning Data Course Project"
author: nmcampbell
date: "2/27/2017"
output: html_document
---

This repo is the final project for the Getting & Cleaning Data Course (https://www.coursera.org/learn/data-cleaning).
This ReadMe provides an overview of the assignment and connected files.  This is a fairly lengthy ReadMe document so to ease in finding things, headings and subheadings are used.  You may wish to use those for finding information that you need.  This ReadMe includes the following sections:

* Overview of the assignment
  + Source of the Data
  + Understanding the data
* Getting Started
  + Dependencies
* Description of run_analysis.R
* Description of tidy_data.csv
* Description of Codebook.md
* Bibliography

## Overview of the Assignment

The purpose of this assignment is to get, understand, tidy and analyze some data.  Specifically, the goals are to: 1) merge various data files into one data set; 2) extract only the measurements on mean and standard deviation for each measurement; 3) use descriptive activity names for the activities in the data set; 4) appropriately label data with descriptive variable names; and 5) create a second, tidy data set with the average of each variable for each activity and each subject.

As part of this assignment, you will find:

* _ReadMe.md_: this ReadMe file which provides descriptive information about the work
* _run_analysis.R_: an R-script which merges, cleans up, analyzes and writes a second tidy dataset.
* _tidy.csv_: a tidied dataset which inlcudes an average mean and standard deviation for each activity and each subject.  (Information on opening tidy.csv in R are listed below)
* _CodeBook.md_: a codebook for the data used in tidy.csv, including information about the original data.

### Source of the Data

The data used for this assignment are collected from accelerometer readings from Samsung Galaxy S smartphones.  Full details about the project (and the source of the original data) can be found at:  http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones

The data used for this specific assignment are available at:
https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip

### Understanding the data

Since we're talking about the data, it is useful to take some time to understand it before delving into the scripts.  The data are organized into a series of text files and folders and, in particular, are split between "training" data and "test" data. Details about how the data were originally organized and collected can be found in the README.txt file included with the data.  The important thing to understand for this assignment is that data will be merged from several files contained in two different folders.  And, that those files include feature names, activity names, subject information and data collected for various features.  Thus, these files need to be merged carefully in order to match appropriate variable names with the measurements collected.  

The CodeBook.md includes information about the files and variables used so look there for specific information.  It should be noted that some data (specifically that related to Inertial Signals) are not used for this assignment.  This data does not include mean() and standard deviation measurements.

## Getting Started

To run the run_analysis.R script, be sure to download the data zip file (https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) and extract the files to your preferred directory.  Set this directory to be your working directory and place run_analysis.R in that directory.

Or you can run the following:

1.  Download the zip file and save to a folder called `data`:
```{r}
if(!file.exists("./data")){dir.create("./data")}
file_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
download.file(file_url, destfile = ".data/Dataset.zip", method = "curl")
```

2.  Unzip the file
``` {r}
unzip(zipfile = ".data/Dataset.zip", exdir = "./data")
```

3.  The unzipped files are in a folder called `UCI HAR Dataset`.  Set this folder to be your working folder (using `setwd()` and the appropriate file structure) and place run_analysis.R inside it.

### Dependencies

run_analysis.R requires the `reshape2` package for the final bit of tidy-ing and analysis.  There are numerous ways to clean up and aggregate the data, but this package seemed to work best for me.  Check out Sean Anderson's _Introduction to reshape2_ [^1] and _tidyr vs. reshape2_[^2] to learn more.  (See Bibliography)

run_analysis.R begins with a call to `library(reshape2)`.

## Description of run_analysis.R

run_analysis.R is made up of a series of steps that merges various data files into one, cleans up and adds appropriate labels, extracts a subset of data, aggregates the data and finally, outputs a tidy version of the subset data.  The specific details and additional information are as follows:

### Merge the data files into one data set.

The data files are arranged into two folders (`test` and `train`).  It is further divided into separate files for measurements, labels, and subject information.  The first step is to read these various files into dataframes:

#### Read the training data
```{r}
x_train <- read.table("train/X_train.txt")
y_train <- read.table("train/y_train.txt")
```

#### Read the test data
```{r}
x_test <- read.table("test/X_test.txt")
y_test <- read.table("test/y_test.txt")
```

#### Read the subject data
```{r}
subject_train <- read.table("train/subject_train.txt")
subject_test <- read.table("test/subject_test.txt")
```

#### Read the labels for features and activities
```{r}
features <- read.table("features.txt")
activity_labels <- read.table("activity_labels.txt")
```

#### Name columns with appropriate descriptive names
This could happen later in the script, but I found it easier to add the names now so that I could better identify the data.

```{r}
names(subject_train) <- "subject_id"
names(subject_test) <- "subject_id"
names(y_train) <- "activity"
names(y_test) <- "activity"
names(x_train) <- features$V2
names(x_test) <- features$V2
```

#### Merge tables into one
This step merges the various data frames into one by first binding training files together, then test files together and finally putting training and test data into one file.

```{r}
train_data <- cbind(subject_train, y_train, x_train)
test_data <- cbind(subject_test, y_test, x_test)
all_combined <- rbind(train_data, test_data)
```

### Add descriptive activity labels to the appropriate column
This step adds descriptive labels to the activity column of the combined data frame.

```{r}
all_combined$activity <- as.character(all_combined$activity)
for (i in 1:6) {
      all_combined$activity[all_combined$activity == i] <- as.character(activity_labels[i,2])
}
```

### Select columns with means and standard deviation measurements
There are numerous columns with means and standard deviation measurements.  It uses grep to search for column names with "Mean" or "Std" somewhere and creates a vector of column numbers.  It then creates a subset of data with the "needed columns" as well as the subject and activity columns.  

```{r}
needed_columns <- grep("*.*Mean.*|.*Std.*", names(all_combined),
                          ignore.case = TRUE)

needed_columns2 <- c(1, 2, needed_columns)
data_subset <- all_combined[, needed_columns2]
```

### Analyze data to get  (using reshaper2)

The aim here was to end up with a data set that included the average of each variable for each activity and each subject.  As I noted previously, there are so many ways to shape and aggregate the data.  I toyed around with tidyr, diplyr, and reshaper2.  And, also with whether the data should be narrow or wide.  In the end, the following two step process got the data where it makes sense to me.  I also found the two readings listed below in footnotes helpful in exploring some options for shaping this data.  (Your mileage may vary).

#### Sets up variable/value pairs with subject_id and activity as id variables

```{r}
melted <- melt(data_subset, id=c("subject_id", "activity"))
```

#### Recast as wide format with values aggregated by subject_id and activity

```{r}
tidy <- dcast(melted, subject_id + activity ~ variable, mean)
```

This ended up with a nice data frame that has the average for each variable (in columns) aggregated for each activity for each subject (rows).  For example, one row  includes various average (mean and standard deviation) measurements for Subject 1, Sitting (activity).

### Write data to csv file
Finally, run_analysis.R ends by writing this tidy, reshaped data into a new .csv file.   

```{r}
write.csv(tidy, "tidy_data.csv", row.names = FALSE)
```

## Description of tidy_data.csv
tidy_data.csv is a cleaned up subset of the various data files used for this assignment.  It includes various mean and standard deviation measurements for each Subject and activity.  

If you would like to view tidy.csv easily in R, first download the file, place it in your R working directory and then do the following:

```{r}
tidy_data <- read.csv("tidy_data.csv")
View(tidy_data)
```
This tidy_data.csv file represents tidy (or at least tidy-er) data because it does the following:

* each variable forms a column
* each observation is its own row
* each type of observation (train data and test data) are its own table [^3]

Additionally, variable names are clearly labelled, making it easier to understand the data.

## Description of Codebook.md

Codebook.md describes the data used for the project.  Specifically, it details the variables and structure of the data, including transformations I did to clean things up, and includes information from the original codebook.

## Bibliography

[^1]: Introduction to reshape2: http://seananderson.ca/2013/10/19/reshape.html

[^2]: tidyr vs. reshape2:  http://www.milanor.net/blog/reshape-data-r-tidyr-vs-reshape2/

[^3]:  Hadley Wickham, _Tidy Data_.  http://vita.had.co.nz/papers/tidy-data.pdf
