import json
from pprint import pprint


def findkey(obj, key):
    if key in obj:
        return obj[key]
    for k, v in obj.items():
        if isinstance(v, dict):
            ret = findkey(v, key)
            print ret
            return ret if ret is not None else ""
        return ""


def findallkeys(obj, noinc):
    """
    Find all keys in this obj
    """
    ret = []
    for k in obj.iterkeys():
        if noinc is not None and k not in noinc:
            if isinstance(obj[k], dict):
                ret += [k] + findallkeys(obj[k], noinc)
            ret += [k]

    return ret


def get_ascii(string):
    """
    Temp?
    """
    if isinstance(string, str):
        return True
    elif isinstance(string, unicode):
        return False
    else:
        return str(string)


def csvify_to_file(headers, infile, outfile):
    """
    Flatten the json entry. This is pretty simple, and relies on a bit
    of preprocessing of the json keys to make sure there are no conflictions.
    """
    with open(infile, "r") as ins, open(outfile, "w") as outs:
        outs.write(",".join(headers) + "\n")  # write header to top of file
        for line in ins:
            j = json.loads(line)
            ents = []
            for h in headers:
                k = findkey(j, h)
                ents += str(k) if get_ascii(k) else ""
            outs.write(",".join(ents) + "\n")

# headers just enumerate what to flatten to csv. Assumes distinction
# across fields.
bus_headers = ['city', 'review_count', 'name', 'neighborhoods',
               'type', 'business_id', 'full_address', 'state',
               'longitude', 'stars', 'latitude', 'attributes',
               'Take-out', 'Drive-Thru', 'Outdoor Seating', 'Caters',
               'Noise Level', 'Delivery', 'Attire', 'Has TV',
               'Price Range', 'Takes Reservations', 'Waiter Service',
               'Accepts Credit Cards', 'Good for Kids', 'Good For Groups',
               'Alcohol', 'attributes', 'open', 'categories']
csvify_to_file(bus_headers,
               "data/json_origin/yelp_academic_dataset_business.json",
               "data/business.csv")

checkin_headers = ['checkin_info', '9-5', '7-5', '13-3', '17-6',
                   '13-0', '17-3', '10-0', '18-4', '14-6', 'checkin_info',
                   'type', 'business_id']
csvify_to_file(checkin_headers,
               "data/json_origin/yelp_academic_dataset_checkin.json",
               "data/checkin.csv")

review_headers = ['funny', 'useful', 'cool', 'user_id',
                  'review_id', 'text', 'business_id',
                  'stars', 'date', 'type']
csvify_to_file(review_headers,
               "data/json_origin/yelp_academic_dataset_review.json",
               "data/review.csv")

tip_headers = ['user_id', 'text', 'business_id', 'likes', 'date', 'type']
csvify_to_file(tip_headers,
               "data/json_origin/yelp_academic_dataset_tip.json",
               "data/tip.csv")

user_headers = ['yelping_since', 'votes', 'funny', 'useful', 'cool', 'votes',
                'user_id', 'name', 'elite', 'type', 'compliments', 'profile',
                'cute', 'funny', 'plain', 'writer', 'note', 'photos', 'hot',
                'more', 'cool', 'compliments', 'fans', 'average_stars',
                'review_count', 'friends']
csvify_to_file(user_headers,
               "data/json_origin/yelp_academic_dataset_user.json",
               "data/user.csv")
