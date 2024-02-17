## Title
<!-- Optional, the preface is not about the subject -->
An analysis of predicted study time in an inclusive digital environment for advanced training in the field of modern information technology

By  Aleksandr Gorbachev & David Langeveld  


A Research Paper  
Submitted to the lecturer of the subject ‘Machine Learning’  
The Hague University of Applied Sciences PRO  
Master of Business Administration  
MBA Big Data Analytics  
February 2024

## Abstract
<!-- Contains the purpose of the research carried out, the research questions that are dealt with, the research method and the most important findings -->

## Table of contents

## Introduction
In the digital age, being up to speed regarding the latest technology trends is essential for the current workforce. Microsoft, Amazon and Google are all big players in the industry of cloud computing and have many cases where candidates can learn and receive certifications in these areas of the field.

Since 2017 the client has been creating conditions for preparing young people to participate in international professional ICT skills competitions according to WorldSkills standards. In 2018 WorldSkills has announced a set of new skills areas, including cloud computing to be held during the next international competition. 

The client decided to develop this training area and began to study the market for products that could allow participants to undertake practical programs and demonstrate their professional skills in this arena. This project involves a platform that provides an inclusive digital environment for advanced training in the field of modern information technology. The platform has suitable tools that could allow young people to undertake practical programs and demonstrate their professional skills especially in new directions that appear in this ICT field every year.

As the project develops, it would be interesting to view the relations between users and their attributes when making use of the platform. This is where our research begins.

## Operationalization of the research objectives
<!-- Describe the data that will be used and how the questions will be answered on the basis of this data. The data analysis itself is not yet described here. So do tell ‘Data file [X] comes from [Y] and can answer the posed questions because [Z]’, but do not yet describe the data itself -->

The NSALAB Learn platform stores all information in a NoSQL database (MongoDB) in the form of JSON collections. The raw data used for this research is a dump from MongoDB database instances for **production** and **development** environments. Two collections are used from each database, which are:

- **materials** - a collection of study actual materials, such as:
  - *lectures* - theoretical materials on a certain topic 
  - *labs* - practical assignments on certain topics where the user has mechanics to deploy a lab environment in the public cloud, including guidelines to accomplish lab assignments and an assessment engine to automatically grade the lab
  - *Tests* - short quizes on certain topics
  - *Courses* - collection of lectures, labs and tests grouped together 
  - *Test-exams* - exams on certain courses
  - *learning paths* - collection of courses grouped together
- **user_materials** - instances of an assignment of a given material to a given user (e.g. when user opens a lecture, a user material assignment is created in the database), with timestamps when material was assigned (opened) and submitted (finished) as well as the completion scores if any.

*Note: The material types considered are only lectures, labs and Tests as the estimated completion time of these other types is based on these calculations.*

Therefore, the observation unit we are interested in is a user-material instance extended by metadata associated with a given material.

The following steps will make sure to operationalize the data so that the formulated research objectives will be achieved:

- Pre-processing of JSON data to: 
  - extract additional metadata from materials
  - convert whitelisted features from JSON collections to tabular CSV format
- Cleaning of resulting dataset 
- Exploratory data visualization 
- Application of multiple regression methods

## JSON pre-processing

Data pre-processing aims to enhance the existing dump of the materials collection with additional metadata (features) extracted from the text and to convert relevant information into tabular CSV data.

For simplicity, the pre-processing is done using the following scripts written in Python and attached to the report:
- extend_metadata.py
- json_to_csv.py

### Extension of metadata

The typical study material of each type is essentially a text, which may be supported by videos or illustrations. So we want to extract the total duration of videos, the number of images and count the number of words for each material. As the source text is in Markdown format and all assets are embedded in the source text, we also need to remove all links to previously counted assets and non-alpha-numeric characters to make the word count more accurate.

### Convertion to tabular data

Since the raw JSON data contains a lot of data (e.g. material sources, deployment logs, etc.) which is not relevant for further analysis, the purpose of the conversion script is to whitelist only relevant features for both types of files and save these collections as CSV.


**Table 1: Dataset files**
Source file             | Result file
-------------           | -------------
dev_materials.json      | dev_materials.csv
dev_user_materials.json | dev_user_materials.csv
prod_materials.json     | prod_materials.csv
prod_user_materials.json| prod_user_materials.csv

**Table 2: Structure of materials dataset**
Column name     | Description
-------------   | -------------
_id.$oid        | Material ID
materialType    | Type of content, such as: lecture, lab, test
video_minutes	| Duration of the embedded videos (if any)
pics	        | Number of illustrations
words           | Number of words

**Table 3: Structure of user-materials dataset**
Column name     |   Description
-------------   |   -------------
_id.$oid	    |   User-material association ID
user_id.$oid    |   User ID
material_id.$oid|   Material ID
assignedAt.$date|   Timestamp when material was assigned to a user
submitedAt.$date|   Timestamp when material was submitted by a user
score           |   User score of lab or test (if any)

## Preliminary analysis, cleaning and tunning

Detailed steps for cleaning and analysing the resulting dataset can be found in the R script attached to the report (project.r).

It should be noted that the raw data, due to the nature of the application of the platform, has a lot of noisy observations.

The development environment was mainly used by platform and material developers. This means that the number of different materials is much larger (as well as the user-material associations), but the completion time of materials is often underestimated due to the specificity of testing. Nevertheless, the data from this environment also contains metrics from real users.

Also, a large number of associations in both environments are incomplete, which means that the user has opened a material and has not completed it. The other extreme is when a user opens a short material, gets distracted and finalises it after a few days.

The initial number of observations for combined materials is 1173 observations and for user-material associations is 3399 observations.

Since the main outcome variable is the actual completion time (duration in minutes) of the material, we need to remove observations from user materials that either do not have a submission (completion) time or (for whatever reason) do not have a start time.

After extending (left-joining) the combined materials dataframe to user materials, we also remove observations that do not contain text (meta-materials).

Now we can observe that for the remaining relevant associations there is a huge spread in completion time (Appendix 1. Figure 1), so that there are observations where the completion time is over 200,000 minutes.

However, before removing these extreme outliers, as we will treat each material type separately below, we first divide them into separate dataframes and then remove extreme outliers for each dataframe.

Additional assumptions are made for clearing:
 - Lectures with completion time <1 minute are considered skipped and removed.
 - Lectures with accompanying videos where the total duration of the videos is greater than the completion time of the lecture are considered skipped and removed.
 - Labs with completion time <5 minutes or with no score are considered skipped and removed.
 - Tests with no score are considered skipped and removed.

**Table 4: Resulting dataframes after cleaning**
Dataframe | Observations  |  Mean completion time (mins)
----------| ------------- | ------------- 
lectures  | 120           | 5.77
tests     | 288           | 4.08
labs      | 33            | 71.5

The visuals of the dataframes is in the Appendix 1. Figure 2 through 4.

## Machine learning models
<!-- More than three models applied and finetuned. If you choose for Regression, Association of Clustering, only one model is available. But you need that one apply a model with some set of parameters-->

The datasets can be used to perform statistical analyses that will help provide evidence and insights into the impact of various factors on completion times and whether these effects are statistically significant. The model that has been applied is Regression and will be applied with different parameters for each material type (labs, lectures, tests).

To create a linear regression model, it is necessary to identify an outcome (dependent) variable and predictor (independent) variable(s). In statistical terms this will form an equation, $\hat{y}$ = $b_{0}$ + $b_{1}$ * $x_{1}$. $\hat{y}$ is the outcome variable,  $x_{1}$ will be the predictor, $b_{0}$ represents the intercept and $b_{1}$ * $x_{1}$ represents the slope associated with the predictor variable.

After cleaning the dataframes, the use of linear models has been applied to the dataframes of lectures, labs and tests. Following predictor variables will be considered for each type of material:

- **lectures**: number of words, number of illustrations, duration of videos
- **tests**: number of words, score
- **labs**: number of words, number of illustrations, score

## Results of the data analysis
<!-- Results of the data analysis: The actual answer of the research questions based on data analysis, the use of specific graphs to gain insight into the answers to the questions and the results of the hypothesis testing -->

### Correlation in completion time for lectures

The visuals of these models is in the Appendix 2. The results of the regression model where the 3 variables have been included for the Lectures, is below:

#### Regression table

| term          | estimate | std_error | statistic | p_value | lower_ci | upper_ci |
|---------------|----------|-----------|-----------|---------|----------|----------|
| intercept     | 4.60     | 0.811     | 5.67      | 0       | 2.99     | 6.20     |
| words         | 0        | 0.001     | 0.566     | 0.572   | -0.001   | 0.002    |
| pics          | 0.146    | 0.116     | 1.26      | 0.209   | -0.083   | 0.375    |
| video_minutes | 0.473    | 0.256     | 1.84      | 0.068   | -0.035   | 0.981    |

The estimate for the intercept is 4.60 with a standard error of 0.811. The intercept represents the expected value of completion time when all other variables are zero. This means that the model predicts a baseline completion time of 4.60 minutes when there are no words, illustrations, or video minutes included.

For the **Words**, **Pics**, **Video_minutes** variables, these indicate the change in the dependent variable for a one-unit change in each independent variable, and where other variables will be constant. For 'video_minutes', the estimate is 0.473 which means that for each additional unit increase in 'video_minutes', the Time Difference variable increases on average by 0.473 units. Note that coefficient for words is not 0 but 0.0004105351.

#### Regression points

| ID  | time_diff | words | pics | video_minutes | time_diff_hat | residual |
|-----|-----------|-------|------|---------------|---------------|----------|
| 1   | 4.17      | 885   | 0    | 0             | 4.96          | -0.792   |
| 2   | 13.8      | 1954  | 0    | 0             | 5.40          | 8.42     |
| 3   | 1.82      | 835   | 2    | 0             | 5.23          | -3.41    |
| 4   | 3.3       | 286   | 0    | 0             | 4.72          | -1.42    |
| 5   | 2.92      | 1209  | 0    | 0             | 5.10          | -2.17    |
| ... | ...       | ...   | ...  | ...           | ...           | ...      |

The output of the regression analysis is appied to the individual data points. Each row is an observation aka datapoint. As mentioned before, the time_diff is the dependant variable, whereas the words, pics, and video_minutes columns are the independent variables. The time_diff_hat contains the predicted values based on the regression model and the residual column shows the difference between the actual values and the predicted values. For example, as seen in the first row, the actual 'time_diff' is 4.17, and the predicted 'time_diff_hat' is 4.96. The difference between these two values, which is the residual, is -0.792. This means that the model, for this observation/row, shows the (underpredicted) time difference by 0.792 units.

#### Correlation matrix

|              | time_diff | words    | pics     | video_minutes |
|--------------|-----------|----------|----------|---------------|
| time_diff    | 1.0000000 | 0.1284185| 0.2142630| 0.22353759    |
| words        | 0.1284185 | 1.0000000| 0.4302708| 0.08805087    |
| pics         | 0.2142630 | 0.4302708| 1.0000000| 0.33110331    |
| video_minutes| 0.2235376 | 0.0880509| 0.3311033| 1.00000000    |

In the output above, this correlation matrix mixes the variables and each cell represents the correlection coefficient between two variables. For example, the correlation coefficient between 'words' and 'pics' is 0.4302708. This relationship can be categorized as a medium positive correlation between the number of words and pictures. So if the words are increased, the more pictures are included as well.

#### Prediction equestion

Putting these results together, the equation of the regression plane that gives us fitted values of completion time is:

 $\hat{y}$ = $b_{0}$ + $b_{words}$ * $words$ + $b_{pics}$ * $pics$ + $b_{video}$ * $video$

$\hat{y}$ = $4.60$ + $0.0004105351$ * $words$ + $0.146$ * $pics$ + $0.473$ * $video$.

### Correlation in completion time for labs

The visuals of these models is in the Appendix 3. The results of the regression model where the 3 variables have been included for the Labs, is below:

#### Regression table

| term      | estimate | std_error | statistic | p_value | lower_ci | upper_ci |
|-----------|----------|-----------|-----------|---------|----------|----------|
| intercept | 168.     | 25.1      | 6.70      | 0       | 117.     | 219.     |
| words     | -0.322   | 0.121     | -2.65     | 0.013   | -0.57    | -0.074   |
| pics      | 17.4     | 9.97      | 1.74      | 0.092   | -3.04    | 37.7     |
| score     | -0.241   | 0.222     | -1.09     | 0.286   | -0.696   | 0.213    |

As seen in the table above, the intercept is 168, indicating the (expected) value of the dependent variable (completion time) when all independant variables are zero. For the Words, Pics, Score variables, these indicate the change in the dependent variable for a one-unit change in each independent variable, and where other variables will be constant. For 'score', the estimate is -0.241 which means that for each additional unit increase in 'score', the completion time variable decreases on average by 0.241 units.

#### Regression points

| ID  | time_diff | words | pics | score | time_diff_hat | residual |
|-----|-----------|-------|------|-------|---------------|----------|
| 1   | 28.1      | 738   | 7    | 100   | 27.8          | 0.246    |
| 2   | 82.2      | 742   | 7    | 50    | 38.6          | 43.6     |
| 3   | 17.3      | 472   | 4    | 100   | 61.4          | -44.1    |
| 4   | 58.9      | 472   | 4    | 100   | 61.4          | -2.44    |
| 5   | 36.7      | 420   | 1    | 100   | 26.0          | 10.7     |
| ... | ...       | ...   | ...  | ...   | ...           | ...      |

The output of the regression analysis is appied to the individual data points. Each row is an observation aka datapoint. The time_diff is the dependant variable, whereas the words, pics, and score columns are the independent variables. The time_diff_hat contains the predicted values based on the regression model and the residual column shows the difference between the actual values and the predicted values. As seen in the first row, the actual 'time_diff' is 28.1, and the predicted 'time_diff_hat' is 27.8. The difference between these two values, which is the residual, is 0.246. This means that the model, for this observation/row, shows the (overpredicted) time difference by 0.246 units.

#### Correlation matrix

|         | time_diff | words      | pics       | score      |
|---------|-----------|------------|------------|------------|
| time_diff | 1.0000000 | -0.5502159 | -0.4375514 | -0.3592358 |
| words    | -0.5502159 | 1.0000000  | 0.9529337  | 0.2866705  |
| pics     | -0.4375514 | 0.9529337  | 1.0000000  | 0.2139325  |
| score    | -0.3592358 | 0.2866705  | 0.2139325  | 1.0000000  |

In the output above, this correlation matrix mixes the variables and each cell represents the correlection coefficient between two variables. For example, the correlation coefficient between 'score' and 'pics' is 0.2139325. This relationship can be categorized as a (low) positive linear relationship between the score and pictures. 

It's worth noting that the time it takes to complete labs includes not only reading time, but also the time it takes to set up the infrastructure in a public cloud and the time it takes to actually implement the lab objectives. Thus, such a negative correlation between completion time and number of accompanying illustrations can be explained by the fact that the more descriptive the lab guidelines are (more text and more illustrations), the less time it takes to actually complete the lab. The negative correlation with the score could also mean that if the lab is completed in a shorter time frame (with more concentration on the objectives), the score will be higher.

### Analyzing completion time for tests

The visuals of these models is in the Appendix 4. The results of the regression model where the 3 variables have been included for the Tests, is below:

tests_model <- lm(time_diff ~ words + score, data = tests)

get_regression_table(tests_model)

### Model applications
<!-- R code is correct and well documented-->

R script separate

### Model evaluation & improvements
<!-- Evaluation and improvement extensively done and elaborated-->

Not sure if we need this one?

### Model comparison
<!-- Comparison (Ensemble) properly done and elaborated -->

Not sure if we need this one?

## Conclusions and recommendations
<!-- including recommendations for further research -->



## Appendix

Appendix 1: Grouped

Appendix 2: Lectures

Appendix 3: Labs

Appendix 4: Tests
