# Load Libraries

library(ggplot2)
library(dplyr)
library(lubridate)
library(caret)
library(corrplot)
library(readr)
library(reshape2)

# Load Dataset
df <- read.csv("C:/Users/ishit/Downloads/supermarket datatset unified/Supermart Grocery Sales - Retail Analytics Dataset.csv", stringsAsFactors = TRUE)

# Data Preprocessing
df <- na.omit(df)
df <- df[!duplicated(df), ]

# Convert Order Date
df$Order.Date <- as.Date(df$Order.Date, format='%Y-%m-%d')
df$Order.Day <- day(df$Order.Date)
df$Order.Month <- month(df$Order.Date)
df$Order.Year <- year(df$Order.Date)

# Encode categorical variables
df$Category <- as.numeric(factor(df$Category))
df$Sub.Category <- as.numeric(factor(df$Sub.Category))
df$City <- as.numeric(factor(df$City))
df$Region <- as.numeric(factor(df$Region))
df$State <- as.numeric(factor(df$State))
df$Sales <- as.numeric(df$Sales)

# Exploratory Data Analysis
# Boxplot
ggplot(df, aes(x=factor(Category), y=Sales)) + 
  geom_boxplot(fill='lightblue') +
  ggtitle('Sales Distribution by Category') +
  xlab('Category') +
  ylab('Sales')

# Ensure Order.Date is in Date format
df$Order.Date <- as.Date(df$Order.Date)

# Filter out NA values and summarize profit
profit_over_time <- df %>%
  filter(!is.na(Profit)) %>%  # Remove NA values
  group_by(Order.Date) %>%
  summarise(Total.Profit = sum(Profit, na.rm = TRUE))

# Plot the profit data as a bar plot
ggplot(profit_over_time, aes(x = Order.Date, y = Total.Profit)) + 
  geom_bar(stat = 'identity', fill = 'green') +  # Use bar plot with filled color
  ggtitle('Total Profit Over Time') +
  ylab('Total Profit') + 
  xlab('Order Date') +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))  # Rotate x-axis labels for better visibility


# Correlation Matrix
cor_matrix <- cor(df %>% select_if(is.numeric))
corrplot(cor_matrix, method='color', type='upper', tl.cex=0.8)

# Sales by City
ggplot(df, aes(x=factor(City), y=Sales)) + 
  geom_bar(stat='summary', fun=mean, fill='skyblue') + 
  ggtitle('Average Sales by City') + 
  xlab('City') + 
  ylab('Average Sales')

# Sales by Sub-Category
ggplot(df, aes(x=factor(Sub.Category), y=Sales)) + 
  geom_boxplot(fill='lightgreen') + 
  ggtitle('Sales Distribution by Sub-Category') + 
  xlab('Sub-Category') + 
  ylab('Sales')

# Pie Chart: Region-wise Sales
region_sales <- df %>% group_by(Region) %>% summarise(Total = sum(Sales))
region_sales$Region <- as.factor(region_sales$Region)
pie(region_sales$Total, labels=region_sales$Region, main="Sales Distribution by Region")

# Feature Selection and Model Building
features <- df %>% select(-c(Order.ID, Customer.Name, Order.Date, Sales))
target <- df$Sales
target

#split the dataset
set.seed(42)
train_index <- createDataPartition(target, p=0.8, list=FALSE)
X_train <- features[train_index, ]
X_test <- features[-train_index, ]
y_train <- target[train_index]
y_test <- target[-train_index]

# Normalize Data
preprocess_params <- preProcess(X_train, method=c("center", "scale"))
X_train <- predict(preprocess_params, X_train)
X_test <- predict(preprocess_params, X_test)

# Train Linear Regression Model
model <- train(X_train, y_train, method='lm')
y_pred <- predict(model, X_test)

# Check for NA values in predictions and actuals
if (any(is.na(y_test)) || any(is.na(y_pred))) {
  stop("NA values found in predictions or actuals.")
}

# Evaluate the Model
mse <- mean((y_test - y_pred)^2, na.rm = TRUE)  # Ensure NA removal
r2 <- cor(y_test, y_pred, use = "complete.obs")^2  # Use complete cases for correlation

# Print results
print(paste('Mean Squared Error:', mse))
print(paste('R-squared:', r2))


# Actual vs Predicted Plot
ggplot(data.frame(Actual=y_test, Predicted=y_pred), aes(x=Actual, y=Predicted)) +
  geom_point(color='blue') +
  geom_abline(slope=1, intercept=0, color='red') +
  ggtitle('Actual vs Predicted Sales') +
  xlab('Actual Sales') +
  ylab('Predicted Sales')