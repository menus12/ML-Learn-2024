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

## Dataset analysis
<!-- Dataset is fully cleansed, visualized and analysed-->



### Data cleaning and tunning

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
labs      | 33            | 71.5
tests     | 288           | 4.08

### Machine learning models
<!-- More than three models applied and finetuned. If you choose for Regression, Association of Clustering, only one model is available. But you need that one apply a model with some set of parameters-->

## Results of the data analysis
<!-- Results of the data analysis: The actual answer of the research questions based on data analysis, the use of specific graphs to gain insight into the answers to the questions and the results of the hypothesis testing -->

### Model applications
<!-- R code is correct and well documented-->

### Model evaluation & improvements
<!-- Evaluation and improvement extensively done and elaborated-->

### Model comparison
<!-- Comparison (Ensemble) properly done and elaborated -->

## Conclusions and recommendations
<!-- including recommendations for further research -->
