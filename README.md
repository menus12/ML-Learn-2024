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

The NSALAB Learn platform stores all information in a NoSQL database (MongoDB) in the form of JSON collections. The raw data used for this research is essentially a dump from MongoDB database instances for **production** and **development** environments. Two collections are used from each database, which are:

- **materials** - a collection of study actual materials, such as:
  - *lectures* - theoretical materials on certain topic 
  - *labs* - practical assignments on certain topic where user have mechanics to deploy a lab environment in public cloud, guidelines to accomplish lab assignment and assessment engine to automatically grade the lab
  - *tests* - short quizes on certain topics
  - *courses* - collection of lectures, labs and tests grouped together 
  - *test-exams* - exams on certain course
  - *learning paths* - collection of courses grouped together
- **user_materials** - instances of assignment of a given material to a given user (e.g. when user opens a lecture a user material assignment created in database), with timestamps when material was assigned (opened) and submitted (finished) as well as completion scores if any.

*Note: The material types considered are only lectures, labs and tests as the estimated completion time of these other types is based on these calculations.*

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

A typical study material of each type is essentially a text, which may be supported by videos or illustrations. So we want to extract the total duration of videos, the number of images and count the number of words for each material. As the source text is in Markdown format and all assets are embedded in the source text, we also need to remove all links to previously counted assets and non-alpha-numeric characters to make the word count more accurate.

### Convertion to tabular data

Since raw JSON data contains many data (e.g. material sources, deployment logs, etc.) which is not relevant for further analysis the purpose of the convertion script is to whitelist only relevant features for both types of files and save these collections as CSV files

- Source files for development and production environments:
  - dev_materials.json
  - dev_user_materials.json
  - prod_materials.json
  - prod_user_materials.json

- Result files used for analysis:
  - dev_materials.csv
  - dev_user_materials.csv
  - prod_materials.csv
  - prod_user_materials.csv

Below the description of pre-processed data sets:

**Table 1: Structure of dev_materialscsv & prod_materials.csv**
Name of Column  | Description
-------------   | -------------
_id.$oid        | Material ID
materialType    | Type of content, such as: lecture, lab, test
video_minutes	| Duration of the embedded videos (if any)
pics	        | Number of illustrations
words           | Number of words


**Table 2: Structure of dev_user_materials & prod_user_materials**
Name of Column     |   Description
-------------   |   -------------
_id.$oid	    |   User-material association ID
user_id.$oid    |   User ID
material_id.$oid|   Material ID
assignedAt.$date|   Timestamp when material was assigned to a user
submitedAt.$date|   Timestamp when material was submitted by a user
score           |   User score of lab or text (if any)

## Dataset analysis
<!-- Dataset is fully cleansed, visualized and analysed-->

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
