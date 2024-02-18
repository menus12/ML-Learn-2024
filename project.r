# Setting working directory
setwd("path/to/working/directory")

# Install tidyverse package if not installed
# install.packages("tidyverse")
# install.packages("plotly")

# Loading required libraries
library(tidyverse)
library(readr)
library(skimr)
library(moderndive)
library(infer)
library(plotly)
options(scipen = 999)

#======================================================================
# Importing data
#======================================================================
#======================================================================
# Loading dev data
#======================================================================

# Loading csv files 
dev_materials <- read.csv('Datafiles/dev_materials.csv')
dev_user_materials <- read.csv('Datafiles/dev_user_materials.csv')

# Renaming and reordering some columns
names(dev_materials)[5] <- "material_id"
colnames(dev_user_materials) <- c("id", 
                                  "material_id", "user_id", "assigned_at", 
                                  "score", "submitted_at")
dev_user_materials <- dev_user_materials[, c("id", "material_id", 
                                             "user_id", "score", 
                                             "assigned_at", "submitted_at")]
# Adding environment marker for clarity
dev_user_materials$env <- "dev"

# Converting time columns from chr to datetime
dev_user_materials$assigned_at <- as.POSIXct(dev_user_materials$assigned_at,
                                             format="%Y-%m-%dT%H:%M:%S")
dev_user_materials$submitted_at <- as.POSIXct(dev_user_materials$submitted_at,
                                              format="%Y-%m-%dT%H:%M:%S")

#======================================================================
# Loading prod data
#======================================================================

# Loading csv files 
prod_materials <- read.csv('Datafiles/prod_materials.csv')
prod_user_materials <- read.csv('Datafiles/prod_user_materials.csv')

# Renaming and reordering some columns
names(prod_materials)[5] <- "material_id"
colnames(prod_user_materials) <- c("id", 
                                   "material_id", "user_id", "assigned_at", 
                                   "submitted_at", "score")
prod_user_materials <- prod_user_materials[, c("id", "material_id", 
                                               "user_id", "score", 
                                               "assigned_at", "submitted_at")]
# Adding environment marker for clarity
prod_user_materials$env <- "prod"

# Converting time columns from chr to datetime
prod_user_materials$assigned_at <- as.POSIXct(prod_user_materials$assigned_at,
                                              format="%Y-%m-%dT%H:%M:%S")
prod_user_materials$submitted_at <- as.POSIXct(prod_user_materials$submitted_at,
                                               format="%Y-%m-%dT%H:%M:%S")


#======================================================================
# Combining dev and prod 
#======================================================================
combined_materials <- rbind(dev_materials, prod_materials)
combined_user_materials <- rbind(dev_user_materials, prod_user_materials)

#======================================================================
# Cleaning dataset
#======================================================================
#======================================================================
# Cleaning user-materials associations
#======================================================================

# Filtering only completed materials
com_filtered <- combined_user_materials %>% 
  filter(!is.na(assigned_at) & !is.na(submitted_at))

# Creating new column with time difference in minutes (duration)
com_filtered$time_diff <- round(as.double(com_filtered$submitted_at - 
                              com_filtered$assigned_at) / 60, digits = 2)

# Joining materials metadata
com_filtered <- left_join(com_filtered, combined_materials, by = "material_id") 

# Exploring unique and missing data for combined dataframe
data.frame(unique=sapply(com_filtered, 
            function(x) sum(length(unique(x, na.rm = TRUE)))), 
            missing=sapply(com_filtered, function(x) sum(is.na(x))))

# Clearing rows with no text (words)
com_filtered <- com_filtered %>% drop_na("words")

# Plotting boxplot to check spread in completion time by material type
ggplot(com_filtered, aes(x = materialType, y = time_diff)) +
  geom_boxplot()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) + 
  labs(x = "Material type", 
       y = "Completion time (mins)",
       title = "Spread in completion time by material type")

# Dividing dataset by material type
lectures <- com_filtered %>% filter(materialType == "lecture")
labs <- com_filtered %>% filter(materialType == "lab")
tests <- com_filtered %>% filter(materialType == "test")

#======================================================================
# Cleaning lectures
#======================================================================

# Removing extreme outliers for lectures
Q <- quantile(lectures$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(lectures$time_diff)
lectures <- subset(lectures, lectures$time_diff > (Q[1] - 1.5*iqr) & 
                     lectures$time_diff < (Q[2]+1.5*iqr))

# Removing observations where completion time < 1 min
lectures <- lectures %>% filter(time_diff > 1)

# Removing observations of skipped lectures with videos
lectures <- lectures %>% filter(video_minutes < time_diff)

# Check spread in completion time after removing outliers
boxplot(lectures$time_diff,
        xlab = "Lectures",
        ylab = "Completion time (mins)")

# Skimming completion time
lectures$time_diff %>% skim()

#======================================================================
# Cleaning labs
#======================================================================

# Removing extreme outliers for labs
Q <- quantile(labs$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(labs$time_diff)
labs <- subset(labs, labs$time_diff > (Q[1] - 1.5*iqr) & 
                 labs$time_diff < (Q[2]+1.5*iqr))

# Removing observations where completion time < 5 min
labs <- labs %>% filter(time_diff > 5)

# Removing incomplete labs
labs <- labs %>% filter(!is.na(score) & score != 0)

# Check spread in completion time after removing outliers
boxplot(labs$time_diff,
        xlab = "Labs",
        ylab = "Completion time (mins)")

# Skimming completion time
labs$time_diff %>% skim()

#======================================================================
# Cleaning tests
#======================================================================

# Removing extreme outliers for tests
Q <- quantile(tests$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(tests$time_diff)
tests <- subset(tests, tests$time_diff > (Q[1] - 1.5*iqr) & 
                  tests$time_diff < (Q[2]+1.5*iqr))

# Removing incomplete tests
tests <- tests %>% filter(!is.na(score))

# Check spread in completion time after removing outliers
boxplot(tests$time_diff,
        xlab = "Tests",
        ylab = "Completion time (mins)")

# Skimming completion time
tests$time_diff %>% skim()


#======================================================================
# Results of the data analysis
#======================================================================
#======================================================================
# Correlation in completion time for lectures
#======================================================================

# Visualizing linear model (time vs words)
ggplot(lectures, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)", 
       title = "Completion time as a function of word count") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs pics)
ggplot(lectures, aes(x = pics, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of illustrations", y = "Completion time (mins)", 
       title = "Completion time as a function of illustrations count") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs videos)
ggplot(lectures, aes(x = video_minutes, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Duration of videos", y = "Completion time (mins)", 
       title = "Completion time as a function of video duration") +
  geom_smooth(method = "lm", se = FALSE)

# Making a linear model, regression table and correlation matrix
lectures_model <- lm(time_diff ~ words + pics + video_minutes, data = lectures)
get_regression_table(lectures_model)
get_regression_points(lectures_model)
lectures %>% select(time_diff, words, pics, video_minutes) %>% cor()

# Visualizing 3D model based on all 3 variables colored with completion time
plot_ly(lectures, x = ~words, y = ~pics, z = ~video_minutes, 
        type="scatter3d", mode="markers",  marker = list(size=6, opacity=.7,  
        color=~time_diff, colorscale = list(c(0,1), c("blue", "yellow")), 
        colorbar=list(title='Completion time'))) %>%
  add_markers() %>%
  layout(showlegend = FALSE,
         scene = list(
                 xaxis = list(title = 'Number of words'),
                 yaxis = list(title = 'Number of pictures'),
                 zaxis = list(title = 'Video Length')))

#======================================================================
# Analyzing completion time for labs
#======================================================================

# Visualizing linear model (time vs words)
ggplot(labs, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)", 
       title = "Completion time as a function of word count") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs pics)
ggplot(labs, aes(x = pics, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of illustrations", y = "Completion time (mins)", 
       title = "Completion time as a function of illustrations count") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs score)
ggplot(labs, aes(x = score, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Score", y = "Completion time (mins)", 
       title = "Completion time as a function of score") +
  geom_smooth(method = "lm", se = FALSE)

labs_model <- lm(time_diff ~ words + pics + score, data = labs)
get_regression_table(labs_model)
get_regression_points(labs_model)
labs %>% select(time_diff, words, pics, score) %>% cor()

# Visualizing 3D model based on all 3 variables colored with completion time
plot_ly(labs, x = ~words, y = ~pics, z = ~score, 
        type="scatter3d", mode="markers",  marker = list(size=6, opacity=.7,  
        color=~time_diff, colorscale = list(c(0,1), c("blue", "yellow")), 
        colorbar=list(title='Completion time'))) %>%
  add_markers() %>%
  layout(showlegend = FALSE,
         scene = list(xaxis = list(title = 'Number of words'),
                      yaxis = list(title = 'Number of pictures'),
                      zaxis = list(title = 'Score')))

#======================================================================
# Analyzing completion time for tests
#======================================================================

# Visualizing linear model (time vs words)
ggplot(tests, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)", 
       title = "Completion time as a function of word count") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs score)
ggplot(tests, aes(x = score, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Score", y = "Completion time (mins)", 
       title = "Completion time as a function of score") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs word and score)
ggplot(tests, aes(x = words, y = time_diff , color = score)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Score", 
       title = "Completion time as a function of word colored by score") +
  scale_color_gradient(low="blue", high="yellow") +
  geom_smooth(method = "lm", se = FALSE)

tests_model <- lm(time_diff ~ words + score, data = tests)
get_regression_table(tests_model)
get_regression_points(tests_model)
tests %>% select(time_diff, words, score) %>% cor()

# Visualizing 3D model based on 2 variables colored + completion time
plot_ly(tests, x = ~words, y = ~score, z = ~time_diff, 
        type="scatter3d", mode="markers", marker = list(size=5, opacity=.9,  
        color=~time_diff, colorscale = list(c(0,1), c("blue", "yellow")), 
        colorbar=list(title='Completion time'))) %>%
  add_markers() %>%
  layout(showlegend = FALSE,
         scene = list(xaxis = list(title = 'Number of words'),
                      yaxis = list(title = 'Score'),
                      zaxis = list(title = 'Completion time')))

#======================================================================
# Model application and evaluation
#======================================================================
#======================================================================
# Filtering materials which were not part of the model training set
#======================================================================
# Filtering lectures from combined materials
test_lectures <- combined_materials %>% 
 filter(materialType == "lecture" &!(material_id %in% com_filtered$material_id))

# Filtering labs from combined materials
test_labs <- combined_materials %>% 
  filter(materialType == "lab" & !(material_id %in% com_filtered$material_id))
# Adding constant highest score 
test_labs$score <- 100

# Filtering tests from combined materials
test_tests <- combined_materials %>% 
  filter(materialType == "test" & !(material_id %in% com_filtered$material_id))
# Adding constant highest score 
test_tests$score <- 100

#======================================================================
# Adding predicted duration using previously trained models
#======================================================================
# Predicting completion time for lectures
test_lectures$pred_duration <- predict(lectures_model, test_lectures)

# Predicting completion time for lectures
test_labs$pred_duration <- predict(labs_model, test_labs)

# Predicting completion time for lectures
test_tests$pred_duration <- predict(tests_model, test_tests)

#======================================================================
# Evaluating results
#======================================================================

# Checking random sample for lectures
sample_n(test_lectures, 10)

# Visualizing 3D model based on all 3 variables colored with predicted duration
marker <- list(color = ~pred_duration, colorscale = c('#FFE1A1', '#683531'), 
               showscale = TRUE)
plot_ly(test_lectures, x = ~words, y = ~pics, z = ~video_minutes, 
        type="scatter3d", mode="markers",  marker = marker) %>%
  add_markers() %>%
  layout(
    scene = list(xaxis = list(title = 'Number of words'),
                 yaxis = list(title = 'Number of pictures'),
                 zaxis = list(title = 'Video Length')))

# Check spread in predicted completion time 
boxplot(test_lectures$pred_duration,
        xlab = "Lectures",
        ylab = "Predicted completion time (mins)")

# Checking random sample for labs
sample_n(test_labs, 10)

# Check spread in predicted completion time 
boxplot(test_labs$pred_duration,
        xlab = "Labs",
        ylab = "Predicted completion time (mins)")

# Checking random sample for tests
sample_n(test_tests, 10)

# Check spread in predicted completion time 
boxplot(test_tests$pred_duration,
        xlab = "Tests",
        ylab = "Predicted completion time (mins)")