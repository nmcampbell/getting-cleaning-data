# run_analysis.R - Getting & Cleaning Data Course Project
## The purpose of this script is to collect and tidy data collected from
## accelerometers on Samsung smartphones.  Various steps in the process are
## noted in comments.

## Dependencies:  the reshape2 package is required in the final step
library(reshape2)

## Merge the training and test data into one data set

## Read data files into dataframes

x_train <- read.table("train/X_train.txt")
y_train <- read.table("train/y_train.txt")
x_test <- read.table("test/X_test.txt")
y_test <- read.table("test/y_test.txt")
subject_train <- read.table("train/subject_train.txt")
subject_test <- read.table("test/subject_test.txt")
features <- read.table("features.txt")
activity_labels <- read.table("activity_labels.txt")

## Name columns with appropriate colnames
names(subject_train) <- "subject_id"
names(subject_test) <- "subject_id"
names(y_train) <- "activity"
names(y_test) <- "activity"
names(x_train) <- features$V2
names(x_test) <- features$V2

## Merge tables into one

train_data <- cbind(subject_train, y_train, x_train)
test_data <- cbind(subject_test, y_test, x_test)
all_combined <- rbind(train_data, test_data)

## Add descriptive activity labels to the appropriate column

all_combined$activity <- as.character(all_combined$activity)
for (i in 1:6) {
      all_combined$activity[all_combined$activity == i] <- as.character(activity_labels[i,2])
}

## Select columns with means and standard deviation measurements

needed_columns <- grep("*.*Mean.*|.*Std.*", names(all_combined), 
                          ignore.case = TRUE)

needed_columns2 <- c(1, 2, needed_columns)
data_subset <- all_combined[, needed_columns2]

## Analyze data to get  (using reshaper2)

### Sets up variable/value pairs with subject_id and activity as id variables
melted <- melt(data_subset, id=c("subject_id", "activity"))

### Recast as wide format with values aggregated by subject_id and activity
tidy <- dcast(melted, subject_id + activity ~ variable, mean)


## Write data to csv file
write.csv(tidy, "tidy_data.csv", row.names = FALSE)