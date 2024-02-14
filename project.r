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

# Filtering only completed materials
dum_filtered <- dev_user_materials %>% 
  filter(!is.na(assigned_at) & !is.na(submitted_at))

# Creating new column with time difference in minutes
dum_filtered$time_diff <- round(as.double(dum_filtered$submitted_at - 
                                            dum_filtered$assigned_at) / 60, 
                                            digits = 2)

# Joining materials metadata
dum_filtered <- left_join(dum_filtered, dev_materials, by = "material_id") 

# Clearing rows with no match on material_id
dum_filtered <- dum_filtered %>% drop_na("words")

# Removing potentially skipped materials
dum_filtered <- dum_filtered %>% filter(time_diff >= 1)


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

# Filtering only completed materials
pum_filtered <- prod_user_materials %>% 
  filter(!is.na(assigned_at) & !is.na(submitted_at))

# Creating new column with time difference in minutes
pum_filtered$time_diff <- round(as.double(pum_filtered$submitted_at - 
                                            pum_filtered$assigned_at) / 60, 
                                digits = 2)

# Joining materials metadata
pum_filtered <- left_join(pum_filtered, prod_materials, by = "material_id") 

# Clearing rows with no match on material_id
pum_filtered <- pum_filtered %>% drop_na("words")

# Removing potentially skipped materials
pum_filtered <- pum_filtered %>% filter(time_diff >= 1 & time_diff <= 90)

################################ LM dev

# Skimming the numerical data
dum_filtered %>% select(time_diff, words, pics, ext_links, video_minutes, materialType) %>% skim()

# Removing extreme outliers
Q <- quantile(dum_filtered$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(dum_filtered$time_diff)
dum_filtered<- subset(dum_filtered, dum_filtered$time_diff > (Q[1] - 1.5*iqr) & dum_filtered$time_diff < (Q[2]+1.5*iqr))

# Visualizing linear model (time vs word)
ggplot(dum_filtered, aes(x = words, y = time_diff , color = materialType)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Material type") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs pics)
ggplot(dum_filtered, aes(x = pics, y = time_diff , color = materialType)) +
  geom_point() +
  labs(x = "Number of pictures", y = "Completion time (mins)", color = "Material type") +
  geom_smooth(method = "lm", se = FALSE)

time_model_interaction <- lm(time_diff ~ words * materialType, data = dum_filtered)
get_regression_table(time_model_interaction)

ggplot(dum_filtered, aes(x = words, y = time_diff, color = materialType)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Material type") +
  geom_parallel_slopes(se = FALSE)

time_model <- lm(time_diff ~ words + pics + materialType, data = dum_filtered)
get_regression_table(time_model)
get_regression_points(time_model)


plot_ly(dum_filtered, x = ~words, y = ~materialType, z = ~time_diff, type="scatter3d", mode="markers", color = ~time_diff)

################################ LM prod

# Skimming the numerical data
pum_filtered %>% select(time_diff, words, pics, ext_links, video_minutes, materialType) %>% skim()

# Removing extreme outliers
Q <- quantile(pum_filtered$time_diff, probs=c(.25, .75), na.rm = FALSE)
iqr <- IQR(pum_filtered$time_diff)
pum_filtered<- subset(pum_filtered, pum_filtered$time_diff > (Q[1] - 1.5*iqr) & pum_filtered$time_diff < (Q[2]+1.5*iqr))

# Visualizing linear model (time vs word)
ggplot(pum_filtered, aes(x = words, y = time_diff , color = materialType)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Material type") +
  geom_smooth(method = "lm", se = FALSE)

# Visualizing linear model (time vs pics)
ggplot(pum_filtered, aes(x = pics, y = time_diff , color = materialType)) +
  geom_point() +
  labs(x = "Number of pictures", y = "Completion time (mins)", color = "Material type") +
  geom_smooth(method = "lm", se = FALSE)

time_model_interaction <- lm(time_diff ~ words * materialType, data = pum_filtered)
get_regression_table(time_model_interaction)

ggplot(pum_filtered, aes(x = words, y = time_diff, color = materialType)) +
  geom_point() +
  labs(x = "Number of words", y = "Completion time (mins)", color = "Material type") +
  geom_parallel_slopes(se = FALSE)

time_model <- lm(time_diff ~ words + pics, data = pum_filtered)
get_regression_table(time_model)
get_regression_points(time_model)

plot_ly(pum_filtered, x = ~words, y = ~pics, z = ~time_diff, type="scatter3d", mode="markers", color = ~time_diff)

