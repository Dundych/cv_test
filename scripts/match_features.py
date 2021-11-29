from datetime import datetime
from itertools import combinations
import argparse
import sys
import os.path
import os
import numpy as np
import math
import cv2


# Parse arguments
ap = argparse.ArgumentParser(description='Script to match features in one image with others')
ap.add_argument('-q', '--query', required=True, help='Querry path. Path to query image')
ap.add_argument('-t', '--train', required=True, help='Train path. Path to train image')
ap.add_argument('-o', '--output', help='Output path. Path to output image. Should contains extension equal to main img')
args = vars(ap.parse_args())

# Assign and verify arguments
query_path = args["query"]
train_path = args["train"]
output_path = args["output"]

if not os.path.isfile(query_path):
    sys.exit("Can't find query image on path '{0}'".format(query_path))
if not os.path.isfile(train_path):
    sys.exit("Can't find train image on path '{0}'".format(train_path))

img1 = cv2.imread(query_path, 0) # queryImage in gray
img2 = cv2.imread(train_path, 0) # trainImage in gray

# Initiate SIFT detector
det = cv2.xfeatures2d.SIFT_create()

# find the keypoints and descriptors
kp1, des1 = det.detectAndCompute(img1, None)
kp2, des2 = det.detectAndCompute(img2, None)

# create BFMatcher object
bf = cv2.BFMatcher()

# Match descriptors.
matches = bf.knnMatch(des1,des2,k=2)

# store all the good matches as per Lowe's ratio test.
good = []
for m,n in matches:
    if m.distance < 0.7*n.distance:
        good.append(m)

# Sort them in the order of their distance.
good = sorted(good, key = lambda x:x.distance)

# Draw first good matches.
img3 = cv2.drawMatches(img1, kp1, img2, kp2, good, None, flags=2)

print( "Done with processing query image '{0}' on train image '{1}'.".format(os.path.basename(query_path), os.path.basename(train_path)) )
print( "Keypoints on Query: {0}. points: {1}".format(len(kp1), [ kp.pt for kp in kp1 ]) )
print( "Keypoints on Train: {0}. points: {1}".format(len(kp2), [ kp.pt for kp in kp2 ]) )
print( "Matches on Query: '{0}'. points: {1}".format(len(good), [ kp1[kp.queryIdx].pt for kp in good ]) )
print( "Matches on Train: '{0}'. points: {1}".format(len(good), [ kp2[kp.trainIdx].pt for kp in good ]) )

# Save result to file if 'output' param provided
if not output_path == None:
    cv2.imwrite(output_path, img3)
    # cv2.imwrite("res{0}.png".format(datetime.now().strftime('%Y%m%dT%H%M%S')),img3)
    print( "Result image with matched features saved in '{0}'.".format(output_path) )


