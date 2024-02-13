#!/usr/bin/env python3

import os
import json
import subprocess
import textract
import re
import ru
import isodate
import datetime
import argparse
from pytube import YouTube
from bs4 import BeautifulSoup
from markdown import markdown

def get_length(filename):
    result = subprocess.run(["ffprobe", "-v", "error", "-show_entries",
                             "format=duration", "-of",
                             "default=noprint_wrappers=1:nokey=1", filename],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT)
    return float(result.stdout)

parser = argparse.ArgumentParser(description='Learn materials duration calculator')    
parser.add_argument('--file', type=str, help='Materials dump from database')
parser.add_argument('--save_as', type=str, help='New filename')
args = parser.parse_args()


if args.file == None:
    print (parser.print_help())
    exit(1)

# Opening JSON file
f = open(args.file)
 
# returns JSON object as  a dictionary
source_file = json.loads(f.read())

# Closing file
f.close()

print ('File is ' + args.file)
print ('---')

start_time = datetime.datetime.now()

for material in source_file:
    c_text = ''
    if material['materialType'] == 'course' or material['materialType'] == 'learning-path':
        continue
    print ('oid: ' + material['_id']['$oid'])
    print (' |-- Material type is ' + material['materialType'])
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
        #print ('Debug: ' + c_text)


    #if material['materialType'] == 'lecture':
    c_text = re.sub('<\!--.*-->',"", material['text'])                      # remove markdown comments
    c_text = re.sub('\\n'," ", c_text)                                      # remove newliners

    videos = re.findall('https:\/\/www\.youtube\.com\/watch\?v=[^\)]+', c_text)
    material['video_minutes'] = len(videos)
    if len(videos) != 0:
        for video in videos:
            yt = YouTube(video)
            video_length = yt.length
            #print (' |-- Video ' + video + ' is ' + str(int(video_length // 60)) + ' minutes ' + str(int(video_length % 60)) + ' seconds long')
            material['video_minutes'] += round(video_length / 60)
            print (' |-- material has ' + str(material['video_minutes']) + ' video minutes.')
    c_text = re.sub('\!\[youtube\]\(https:\/\/www\.youtube\.com\/watch\?v=[^\)]+\)'," ", c_text)
    
    ext_links = re.findall('\[.*?\]\(http.*?\)', c_text)                      # count external links
    material['ext_links'] = len(ext_links)
    print (' |-- material has ' + str(material['ext_links']) + ' links.')
    c_text = re.sub('\[.*?\]\(http.*?\)'," ", c_text)                         # remove external links from text
        
    c_text = re.sub('\(.*\.pka\)'," ", c_text)                              # remove pka assets from text

    pics = re.findall('\[.*\]\(.*(\.svg|\.gif|\.png|\.jpg|\.jpeg)\)', c_text)   # count pictures
    material['pics'] = len(pics)
    print (' |-- material has ' + str(material['pics']) + ' pics.')
    c_text = re.sub('\[.*\]\(.*(\.svg|\.gif|\.png|\.jpg|\.jpeg)\)'," ", c_text) # remove external links from text

    c_text = re.sub('[^а-яА-Яa-zA-Z0-9 -]'," ", c_text)                     # remove all non-alpha-numeric
    c_text = re.sub('\s{2,}'," ", c_text)                                   # trim double whitespaces

    # print(c_text)
    material['words'] = len(c_text.split())
    print (' |-- material has ' + str(material['words']) + ' words.')


print ('---')
end_time = datetime.datetime.now()
print ('Script has been running for ' + str((end_time - start_time).seconds // 60) + ' minutes ' + str((end_time - start_time).seconds % 60) + ' seconds')