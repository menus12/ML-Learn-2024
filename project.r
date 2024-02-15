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

# #################### Loading and clearing dev data

# Loading data files sheets 
dev_materials <- read.csv('Datafiles/dev_materials.csv')
dev_user_materials <- read.csv('Datafiles/dev_user_materials.csv')

# Renaming and reordering some columns
names(dev_materials)[6] <- "material_id"
colnames(dev_user_materials) <- c("passed", "id", 
                                  "material_id", "user_id", "assigned_at", 
                                  "score", "submitted_at")
dev_user_materials <- dev_user_materials[, c("id", "material_id", 
                                             "user_id", "completed", "score", 
                                             "assigned_at", "submitted_at")]

# Converting "completed" column from chr to boolean
dev_user_materials$completed <- as.logical(dev_user_materials$completed)

# Converting time columns from chr to datetime
dev_user_materials$assigned_at <- as.POSIXct(dev_user_materials$assigned_at,
                                             format="%Y-%m-%dT%H:%M:%S")
dev_user_materials$submitted_at <- as.POSIXct(dev_user_materials$submitted_at,
                                              format="%Y-%m-%dT%H:%M:%S")


# #################### Loading and clearing prod data

# Loading data files sheets 
prod_materials <- read.csv('Datafiles/prod_materials.csv')
prod_user_materials <- read.csv('Datafiles/prod_user_materials.csv')

# Renaming and reordering some columns
names(prod_materials)[6] <- "material_id"
colnames(prod_user_materials) <- c("passed", "id", 
                                   "material_id", "user_id", "assigned_at", 
                                   "submitted_at", "score")
prod_user_materials <- prod_user_materials[, c("id", "material_id", 
                                               "user_id", "completed", "score", 
                                               "assigned_at", "submitted_at")]

# Converting "completed" column from chr to boolean
prod_user_materials$completed <- as.logical(prod_user_materials$completed)

# Converting time columns from chr to datetime
prod_user_materials$assigned_at <- as.POSIXct(prod_user_materials$assigned_at,
                                              format="%Y-%m-%dT%H:%M:%S")
prod_user_materials$submitted_at <- as.POSIXct(prod_user_materials$submitted_at,
                                               format="%Y-%m-%dT%H:%M:%S")


################################ Combine dev and prod

combined_materials <- rbind(dev_materials, prod_materials)
combined_user_materials <- rbind(dev_user_materials, prod_user_materials)

# Filtering only completed materials
com_filtered <- combined_user_materials %>% 
  filter(!is.na(assigned_at) & !is.na(submitted_at))

# Creating new column with time difference in minutes
com_filtered$time_diff <- round(as.double(com_filtered$submitted_at - 
                                            com_filtered$assigned_at) / 60, 
                                digits = 2)

# Joining materials metadata
com_filtered <- left_join(com_filtered, combined_materials, by = "material_id") 

# Clearing rows with no match on material_id
com_filtered <- com_filtered %>% drop_na("words")


ggplot(com_filtered, aes(x = materialType, y = time_diff))+
  geom_boxplot()+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Dividing dataset by material type
lectures <- com_filtered %>% filter(materialType == "lecture")
labs <- com_filtered %>% filter(materialType == "lab")
tests <- com_filtered %>% filter(materialType == "test-exam" | 
                                   materialType == "test")


# Removing extreme outliers for lectures
Q <- quantile(lectures$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(lectures$time_diff)
lectures <- subset(lectures, lectures$time_diff > (Q[1] - 1.5*iqr) & 
                     lectures$time_diff < (Q[2]+1.5*iqr))

boxplot(lectures$time_diff)

Q <- quantile(labs$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(labs$time_diff)
labs <- subset(labs, labs$time_diff > (Q[1] - 1.5*iqr) & 
                 labs$time_diff < (Q[2]+1.5*iqr))

boxplot(labs$time_diff)

Q <- quantile(tests$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(tests$time_diff)
tests <- subset(tests, tests$time_diff > (Q[1] - 1.5*iqr) & 
                  tests$time_diff < (Q[2]+1.5*iqr))

boxplot(tests$time_diff)

################################ Analyzing completion time for lectures

# Removing observations where completion time < 1 min
lectures <- lectures %>% filter(time_diff > 1)

# Removing observations of skipped lectures with videos
lectures <- lectures %>% filter(video_minutes < time_diff)

# Visualizing linear model (time vs words)
ggplot(lectures, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)


# Visualizing linear model (time vs pics)
ggplot(lectures, aes(x = pics, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of illustrations", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs videos)
ggplot(lectures, aes(x = video_minutes, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Duration of videos", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

lectures_model <- lm(time_diff ~ words + pics + video_minutes, data = lectures)
get_regression_table(lectures_model)
get_regression_points(lectures_model)
lectures %>% select(time_diff, words, pics, video_minutes) %>% cor()

plot(lectures_model)

marker <- list(color = ~time_diff, colorscale = c('#FFE1A1', '#683531'), 
               showscale = TRUE)
plot_ly(lectures, x = ~words, y = ~pics, z = ~video_minutes, 
        type="scatter3d", mode="markers",  marker = marker) %>%
  add_markers() %>%
  layout(
    scene = list(xaxis = list(title = 'Number of words'),
                 yaxis = list(title = 'Number of pictures'),
                 zaxis = list(title = 'Video Length'))
  )


################################ Analyzing completion time for labs

# Removing observations where completion time < 5 min
labs <- labs %>% filter(time_diff > 5)

# Removing incomplete labs
labs <- labs %>% filter(!is.na(score) & score != 0)

# Visualizing linear model (time vs words)
ggplot(labs, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)


# Visualizing linear model (time vs pics)
ggplot(labs, aes(x = pics, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of illustrations", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs score)
ggplot(labs, aes(x = score, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Score", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

labs_model <- lm(time_diff ~ words + pics + score, data = labs)
get_regression_table(labs_model)
get_regression_points(labs_model)
labs %>% select(time_diff, words, pics, score) %>% cor()

plot(labs_model)




plot_ly(labs, x = ~words, y = ~pics, z = ~score, 
        type="scatter3d", mode="markers",  marker = marker) %>%
  add_markers() %>%
  layout(
    scene = list(xaxis = list(title = 'Number of words'),
                 yaxis = list(title = 'Number of pictures'),
                 zaxis = list(title = 'Score'))
  )


################################ Analyzing completion time for tests

# Removing incomplete tests
tests <- tests %>% filter(!is.na(score))


# Visualizing linear model (time vs words)
ggplot(tests, aes(x = words, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Number of words", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

# Removing outliers for word count
tests <- tests %>% filter(words < 1000)

# Visualizing linear model (time vs pics)
ggplot(tests, aes(x = pics, y = time_diff)) +
  geom_point() +
  labs(x = "Number of illustrations", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs score)
ggplot(tests, aes(x = score, y = time_diff)) +
  geom_jitter(alpha = 0.5) +
  labs(x = "Score", y = "Completion time (mins)") +
  geom_smooth(method = "lm", se = FALSE)

tests_model <- lm(time_diff ~ words + score, data = tests)
get_regression_table(tests_model)
get_regression_points(tests_model)
tests %>% select(time_diff, words, score) %>% cor()

plot(tests_model)

plot_ly(tests %>% filter(words <= 550), x = ~words, y = ~score, z = ~time_diff, 
        type="scatter3d", mode="markers", marker = list(size=5, opacity=.9,  
        color=~time_diff, colorscale = list(c(0,1), c("blue", "yellow")), colorbar=list(title='Completion time'))) %>%
  add_markers() %>%
  layout(
    scene = list(xaxis = list(title = 'Number of words'),
                 yaxis = list(title = 'Score'),
                 zaxis = list(title = 'Completion time'))
  )

# Visualizing linear model (time vs word and score)
ggplot(tests %>% filter(words <= 550), aes(x = words, y = time_diff , color = score)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Score") +
  scale_color_gradient(low="blue", high="yellow") +
  geom_smooth(method = "lm", se = FALSE)