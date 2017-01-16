#! /usr/bin/python2.7
# -*- coding: utf-8 -*-

"""
Script for converting all of the json data in ./data/json_origin/ to csv
files in the ./data/ directory.
"""

import json
import csv

__author__ = "Dodge W. Coates"


def _findkey(obj, key):
    if key in obj:
        return obj[key]
    for k, v in obj.items():
        if isinstance(v, dict):
            value = _findkey(v, key)
            if value is not None:
                return value


def findkey(obj, key):
    v = _findkey(obj, key)
    return v if v is not None else ""


def _findallkeys(obj, noinc):
    """
    Find all terminal keys in this obj
    """
    ret = []
    for k in obj.iterkeys():
        if noinc is not None and k not in noinc:
            if isinstance(obj[k], dict):
                ret += _findallkeys(obj[k], noinc)
            else:
                ret += [k]
    return ret


def findallkeys(obj, noinc):
    return map(str, _findallkeys(obj, noinc))


def allkeys(ff, noinc=[]):
    """
    Return the list of unique keys in the dataset.
    This will then be reduced to a list of keys to look for in the json.

    GREAT CARE TO BE TAKEN WITH THIS FUNCTION!!

    If there are conflicting keynames in the dataset's json (at
    different levels, presumably), this can have disastrously bad
    effects on the csvification. Because python likes to scramble dict
    keyname orders, this means that iterating over the keys to locate
    values in the json objects (to tranlate a json object to a csv
    line) will be undefined; it could grab the value for either of the
    conflicting keys on a given findkey call.
    """
    with open(ff) as dataset:
        j = json.loads(dataset.readline().strip())
        s1 = set(findallkeys(j, noinc))
        for line in dataset:
            j = json.loads(line.strip())
            s1.union(set(findallkeys(j, noinc)))

    return list(s1)


def coerce_to_string(s):
    try:
        return str(s).encode("ascii")
    except:
        return ""


def csvify_to_file(headers, infile, outfile):
    """
    Flatten the json entry. This is pretty simple, and relies on a bit
    of preprocessing of the json keys to make sure there are no conflictions.
    """
    with open(infile, "r") as ins, open(outfile, "wb") as outs:
        csvwriter = csv.writer(outs)
        csvwriter.writerow(headers)  # write header to top of file
        for line in ins:
            j = json.loads(line)
            ents = []
            for h in headers:
                ents += [coerce_to_string(findkey(j, h))]
            csvwriter.writerow(ents)


# Convert the businesses file to csv
print("[1/5] Converting 'business' json file to csv...")
business_file = "data/json_origin/yelp_academic_dataset_business.json"
bus_headers = allkeys(business_file,
                      # Don't care about this stuff
                      noinc=["Ambience", "Good For", "hours", "Parking"])
csvify_to_file(bus_headers, business_file, "data/business.csv")


# Convert the check-ins file to csv
print("[2/5] Converting 'checkin' json file to csv...")
checkin_file = "data/json_origin/yelp_academic_dataset_checkin.json"
checkin_headers = allkeys(checkin_file)
csvify_to_file(checkin_headers, checkin_file, "data/checkin.csv")

# Convert the reviews file to csv
print("[3/5] Converting (big) 'review' json file to csv...")
review_file = "data/json_origin/yelp_academic_dataset_review.json"
review_headers = allkeys(review_file)
csvify_to_file(review_headers, review_file, "data/review.csv")

# Convert the tips file to csv
print("[4/5] Converting 'tip' json file to csv...")
tip_file = "data/json_origin/yelp_academic_dataset_tip.json"
tip_headers = allkeys(tip_file)
csvify_to_file(tip_headers, tip_file, "data/tip.csv")

# Convert the users file to csv
print("[5/5] Converting 'user' json file to csv...")
user_file = "data/json_origin/yelp_academic_dataset_user.json"
user_headers = allkeys(user_file)
csvify_to_file(user_headers, user_file, "data/user.csv")
