#!/usr/bin/env python3

# To run script do the following steps:
# > pip3 install -f requirements.txt
# > chmod +x ./json_to_csv.py
# > ./json_to_csv.py -json raw_data/dev_materials.json --csv dev_materials.csv

import json
import argparse
import datetime
import pandas as pd

# Adding command line parameters
parser = argparse.ArgumentParser(description = "JSON to CSV converter")
parser.add_argument('--json', type=str, help='Materials dump from database')
parser.add_argument('--csv', type=str, help='Output CSV file')
args = parser.parse_args()

if args.json == None or args.csv == None:
    print (parser.print_help())
    exit(1)

print ('JSON file is ' + args.json)
print ('CSV file is ' + args.csv)
print ('---')

start_time = datetime.datetime.now()

f = open(args.json)                     # Opening JSON file
source_file = json.loads(f.read())      # Returns JSON object as  a dictionary
f.close()                               # Closing file

# White list of JSON objects to convert to CSV columns
white_list = ["_id", "materialType", 
              "video_minutes", "pics", "words", 
              "completed", "material_id", "user_id", "assignedAt", 
              "submitedAt", "score"]

# Iterating over list of JSON objects and removing objects which are not whitelisted
for material in source_file:
    keys = list(material.keys())
    for key in keys:
        if key not in white_list:
            material.pop(key, None)

# Converting resulting collection to CSV
df = pd.json_normalize(source_file)
df.to_csv(args.csv, index=False)

print ('---')
end_time = datetime.datetime.now()
print ('Script has been running for ' + str((end_time - start_time).seconds // 60) + ' minutes ' + str((end_time - start_time).seconds % 60) + ' seconds')