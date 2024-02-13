#!/usr/bin/env python3

import json
import argparse
import datetime
import pandas as pd

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

white_list = ["_id", "materialType", 
              "video_minutes", "ext_links", "pics", "words", 
              "completed", "material_id", "user_id", "assignedAt", 
              "submitedAt", "score"]



for material in source_file:
    keys = list(material.keys())
    for key in keys:
        if key not in white_list:
            material.pop(key, None)

df = pd.json_normalize(source_file)
df.to_csv(args.csv, index=False)

print ('---')
end_time = datetime.datetime.now()
print ('Script has been running for ' + str((end_time - start_time).seconds // 60) + ' minutes ' + str((end_time - start_time).seconds % 60) + ' seconds')