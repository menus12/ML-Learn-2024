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


## Operationalization of the research questions
<!-- Describe the data that will be used and how the questions will be answered on the basis of this data. The data analysis itself is not yet described here. So do tell ‘Data file [X] comes from [Y] and can answer the posed questions because [Z]’, but do not yet describe the data itself -->

The dataset delivered by the client is composed of the following elements and will be viewed in R. The original file is in JSON format, which is a standard text-based format for representing structured data based on JavaScript object syntax. It is commonly used for transmitting data in web applications.
Converting the raw JSONs to CSV is done via Python scripts. 

The following 4 tables will be used:

Development environment:
- dev_materials
- dev_user_materials

Production environment:
- prod_materials
- prod_user_materials

**Table: dev_materials & prod_materials:**
Name of Column     | Description
-------------   | -------------
materialType    | Type of content, such as: lecture, lab, test
video_minutes	  | Duration of the material, for example 20.0
ext_links       | Code that relates to
pics	          | Boolean code (1.0 or 0.0) that mentions if pictures are in the content
words           | Number of words
_id.$oid        | ID of the content

**Table: dev_user_materials & prod_user_materials:**
Name of Column     |   Description
-------------   |   -------------
completed       |   Boolean code (True or False) that mentions if the content has been completed by the user
_id.$oid	      |   ID of the content
material_id.$oid|   Code that relates to Material ID
user_id.$oid    |   Code that relates to User ID
assignedAt.$date|   Datetime format when user has been assigned (started?)
score           |   Score of content by user when completed
submitedAt.$date|   Datetime format when user has submitted the material


### Dataset analysis
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
