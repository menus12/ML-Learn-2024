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
# parser.add_argument('--material', type=str, help='Material file to read (default is README.md)')
# parser.add_argument('--read_speed', type=int, help='Avarage words per minute (default is 120)')
# parser.add_argument('--lab_speed', type=int, help='Avarage lab completion time (default is 2 times PDF reading)')
# parser.add_argument('--update', type=bool, help='Update metadata (default is False)')
# parser.add_argument('--clean', type=bool, help='Clean assets which has no references (default is False)')
args = parser.parse_args()


if args.file == None:
    print (parser.print_help())
    exit(1)

source_file = json.loads(args.file)

# avarage reading speed, words per minute
awpm = int(args.read_speed)

# avarage lab deploy time (minutes)
deploy_time = 5

# avarage lab completion speed, times PDF reading
alcs = int(args.lab_speed)

# update actual metadata with calculated values
update = bool(args.update)
clean = bool(args.clean)

# test solving timing parameters
single_choice = 1
multiple_choice = single_choice * 2
matching_choice = multiple_choice * 2

contents = os.listdir(args.dir)
contents.sort()

summary = 0
lectures_summary = 0
labs_summary = 0
video_summary = 0
tests_summary = 0
no_ref = 0
assets_removed = 0

print ('File is ' + args.file)
print ('---')

start_time = datetime.datetime.now()


for entity in contents:
    entity_minutes = 0
    lecture_metadata = ''
    md = ''
    if os.path.isdir(args.dir + '/' + entity):        
        if 'learn-metadata.json' in os.listdir(args.dir + '/' + entity):
            print ('Folder is ' + entity)
            with open(args.dir + '/' + entity + '/learn-metadata.json', 'r') as file:
                lecture_metadata = json.loads(file.read())
                print (' |-- Material type is ' + lecture_metadata['materialType'])
                if "duration" in lecture_metadata.keys():
                    duration = isodate.parse_duration(lecture_metadata['duration']).seconds
                    print (' |-- Metadata duration is ' + str(int(duration / 60)) + ' minutes')
                else: print (' |-- No manual duration is set')
            if lecture_metadata['materialType'] == 'course' or lecture_metadata['materialType'] == 'learning-path':
                continue
            if lecture_metadata['materialType'] == 'test' or lecture_metadata['materialType'] == 'test-exam':
                print (' |-- Number of questions: ' + str(len(lecture_metadata['questions'])))
                for question in lecture_metadata['questions']:
                    md += question['question'] + ' '
                    if question['answerType'] == 'matching':
                        entity_minutes += matching_choice                    
                        for option in question['options']:
                            md += option['option'] + ' '
                    if question['answerType'] == 'singleChoice':
                        entity_minutes += single_choice                    
                    if question['answerType'] == 'multiChoice':
                        entity_minutes += multiple_choice                    
                    for answer in question['answers']:
                        md += answer['answer'] + ' '
                #print ('Debug: ' + md)
                number_of_words = len(md.split())
                number_of_minutes = round(number_of_words / awpm) 
                print (' |-- Material has ' + str(number_of_words) + ' words. Reading time is ' + str(number_of_minutes) + ' minutes')
                entity_minutes += number_of_minutes
                tests_summary += entity_minutes

            if (lecture_metadata['materialType'] == 'lecture' or lecture_metadata['materialType'] == 'lab') and args.material in os.listdir(args.dir + '/' + entity):
                with open(args.dir + '/' + entity + '/' + args.material, 'r') as lecture:
                    md = lecture.read()
                    number_of_words = len(md.split())
                    number_of_minutes = round(number_of_words / awpm)
                    print (' |-- ' + args.material + ' has ' + str(number_of_words) + ' words. Reading time is ' + str(number_of_minutes) + ' minutes')
                    entity_minutes += number_of_minutes
                    videos = re.findall('https:\/\/www\.youtube\.com\/watch\?v=[^\)]+', md)
                    if len(videos) != 0:
                        for video in videos:
                            yt = YouTube(video)
                            video_length = yt.length
                            print (' |-- Video ' + video + ' is ' + str(int(video_length // 60)) + ' minutes ' + str(int(video_length % 60)) + ' seconds long')
                            entity_minutes += round(video_length / 60)
                            video_summary += round(video_length / 60)
                if 'assets' in os.listdir(args.dir + '/' + entity):
                    assets = os.listdir(args.dir + '/' + entity + '/assets/')
                    for asset in assets:
                        asset_path = args.dir + '/' + entity + '/assets/' + asset
                        if asset in md:
                            # if '.mp4' in asset:
                            #     length = get_length(asset_path)
                            #     print (' |-- Video ' + asset + ' is ' + str(int(length // 60)) + ' minutes ' + str(int(length % 60)) + ' seconds long')
                            #     entity_minutes += round(length / 60)
                            #     video_summary += round(length / 60)
                            if '.pdf' in asset:
                                pdf_bin = textract.process(asset_path, method='tesseract', language='rus')
                                pdf_text = pdf_bin.decode()
                                number_of_words = len(pdf_text.split())
                                number_of_minutes = round(number_of_words / awpm)
                                print (' |-- PDF ' + asset + ' has ' + str(number_of_words) + ' words. Reading time is ' + str(number_of_minutes) + ' minutes')
                                entity_minutes += number_of_minutes
                                print (' |-- Lab completion time for above PDF is ' + str(number_of_minutes * alcs) + ' minutes (' + str(alcs) + ' times reading time).')
                                entity_minutes += number_of_minutes * alcs
                                labs_summary += number_of_minutes + number_of_minutes * alcs
                        else:
                            if clean:
                                print (' |-- Deleting ' + asset + ' which has no reference')
                                os.remove(asset_path)
                                assets_removed += 1
                            else:
                                print (' |-- No reference: ' + asset)
                                no_ref += 1
                    if lecture_metadata['materialType'] == 'lecture': 
                        lectures_summary += number_of_minutes
                    if lecture_metadata['materialType'] == 'lab': 
                        entity_minutes = 30 # entity_minutes * 2  + deploy_time
                        labs_summary += entity_minutes
                        
            print (' |-- Calculated completion time for ' + entity + ' is ' + str(entity_minutes) + ' minutes')
            if update: 
                new_duration = 'PT' + str(entity_minutes // 60) + 'H' + str(entity_minutes % 60) + 'M'
                lecture_metadata['duration'] = new_duration
                new_metadata = json.dumps(lecture_metadata, indent = 4, ensure_ascii=False)
                with open(args.dir + '/' + entity + '/learn-metadata.json', 'w') as file:
                    file.write(new_metadata)
                print (' |-- Metadata has been updated')

            summary += entity_minutes




print ('---')
print ('Lectures read time: ' + str(lectures_summary // 60) + ' hours ' + str(lectures_summary % 60) + ' minutes' )
print ('Videos watch time: ' + str(video_summary // 60) + ' hours ' + str(video_summary % 60) + ' minutes' )
print ('Labs completion time: ' + str(labs_summary // 60) + ' hours ' + str(labs_summary % 60) + ' minutes' )
print ('Tests completion time: ' + str(tests_summary // 60) + ' hours ' + str(tests_summary % 60) + ' minutes' )
print ('---')
print ('Assets removed: ' + str(assets_removed))
print ('Assets with no references: ' + str(no_ref))
print ('---')
print ('Total time: ' + str(summary // 60) + ' hours ' + str(summary % 60) + ' minutes' )
print ('---')
end_time = datetime.datetime.now()
print ('Script has been running for ' + str((end_time - start_time).seconds // 60) + ' minutes ' + str((end_time - start_time).seconds % 60) + ' seconds')