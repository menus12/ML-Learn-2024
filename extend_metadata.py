#!/usr/bin/env python3

# To run script do the following steps:
# > pip3 install -f requirements.txt
# > chmod +x ./extend_metadata.py
# > ./extend_metadata.py -file raw_data/dev_materials.json --update True

import os
import json
import re
import argparse
import datetime
from pytube import YouTube

# Adding command line parameters
parser = argparse.ArgumentParser(description='Learn materials metadata extender')    
parser.add_argument('--file', type=str, help='Materials dump from database')
parser.add_argument('--update', type=bool, help='Update metadata (default is False)')
args = parser.parse_args()

if args.update == None:
    args.update = False

if args.file == None:
    print (parser.print_help())
    exit(1)


f = open(args.file)                 # Opening JSON file
source_file = json.loads(f.read())  # returns JSON object as  a dictionary
f.close()                           # Closing file

print ('File is ' + args.file)
print ('---')

start_time = datetime.datetime.now()

# iterating over materials collection
for material in source_file:
    c_text = ''
    if material['materialType'] == 'course' or material['materialType'] == 'learning-path':
        continue
    print ('oid: ' + material['_id']['$oid'])
    print (' |-- Material type is ' + material['materialType'])
    
    # extract text from test questions
    if material['materialType'] == 'test' or material['materialType'] == 'test-exam':
        t = ''
        print (' |-- Number of questions: ' + str(len(material['questions'])))
        for question in material['questions']:
            t += question['question'] + ' '
            if question['answerType'] == 'matching':             
                for option in question['options']:
                    t += option['option'] + ' '              
            for answer in question['answers']:
                t += answer['answer'] + ' '
        material['text'] = t
    
    c_text = re.sub('<\!--.*-->',"", material['text'])  # remove markdown comments
    c_text = re.sub('\\n'," ", c_text)                  # remove newliners

    # extract duration of youtube videos embeded in text    
    videos = re.findall('https:\/\/www\.youtube\.com\/watch\?v=[^\)]+', c_text)
    material['video_minutes'] = len(videos)
    if len(videos) != 0:
        for video in videos:
            yt = YouTube(video)
            video_length = yt.length
            material['video_minutes'] += round(video_length / 60)
            print (' |-- material has ' + str(material['video_minutes']) + ' video minutes.')
    
    c_text = re.sub('\!\[youtube\]\(https:\/\/www\.youtube\.com\/watch\?v=[^\)]+\)'," ", c_text) # remove video links from text
    
    c_text = re.sub('\[.*?\]\(http.*?\)'," ", c_text)  # remove external links from text
        
    c_text = re.sub('\[.*?\]\(.*?\.pka\)'," ", c_text) # remove pka assets from text

    # extract number of illustrations in text
    re_pics = '\[.*?\]\(.*?(\.svg|\.gif|\.png|\.jpg|\.jpeg)\)'
    pics = re.findall(re_pics, c_text)   # count pictures
    material['pics'] = len(pics)
    print (' |-- material has ' + str(material['pics']) + ' pics.')
    c_text = re.sub(re_pics," ", c_text) # remove external links from text

    c_text = re.sub('[^а-яА-Яa-zA-Z0-9 -]'," ", c_text)   # remove all non-alpha-numeric
    c_text = re.sub('\s{2,}'," ", c_text)                 # trim double whitespaces

    # counting remainig words in text
    material['words'] = len(c_text.split())
    print (' |-- material has ' + str(material['words']) + ' words.')

# updating JSON with extracted features
if args.update: 
    new_metadata = json.dumps(source_file, indent = 4, ensure_ascii=False)
    with open(args.file, 'w') as file:
        file.write(new_metadata)
    print ('Metadata has been updated')

print ('---')
end_time = datetime.datetime.now()
print ('Script has been running for ' + str((end_time - start_time).seconds // 60) + ' minutes ' + str((end_time - start_time).seconds % 60) + ' seconds')