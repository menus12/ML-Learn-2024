# Setting working directory
setwd("path/to/working/directory")

# Install tidyverse package if not installed
# install.packages("tidyverse")

# Loading required libraries
library(tidyverse)
library(readr)
library(skimr)
library(moderndive)
library(infer)
options(scipen = 999)

# #################### Loading and clearing data

# Loading data files sheets 
dev_materials <- read.csv('Datafiles/dev_materials.csv')
dev_user_materials <- read.csv('Datafiles/dev_user_materials.csv')

# Renaming and reordering some columns
names(dev_materials)[6] <- "material_id"
colnames(dev_user_materials) <- c("completed", "id", 
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
  filter(completed == TRUE & !is.na(assigned_at) & !is.na(submitted_at))

# Creating new column with time difference in minutes
dum_filtered$time_diff <- round(as.double(dum_filtered$submitted_at - 
                                            dum_filtered$assigned_at) / 60, 
                                            digits = 2)

# Joining materials metadata
dum_filtered <- left_join(dum_filtered, dev_materials, by = "material_id") 

# Clearing rows with no match on material_id
dum_filtered <- dum_filtered %>% drop_na("words")


# #################### 


