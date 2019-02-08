from datetime import datetime
from itertools import combinations
import argparse
import sys
import os.path
import os
import numpy as np
import math
import cv2

def dist(p, q):
    "Return the Euclidean distance between points p and q."
    return math.hypot(p[0] - q[0], p[1] - q[1])

def sparse_subset(points, r):
    """Return a maximal list of elements of points such that no pairs of
    points in the result have distance less than r.

    """
    result = []
    for p in points:
        if all(dist(p, q) >= r for q in result):
            result.append(p)
    return result

def concatenate_cv2_images(img1, img2, axis=0):
    "Concatenate two cv2 imgs to one. axis=0 for vertically (default), 1 for horizontally"
    if axis not in [0, 1]:
        sys.exit("Axis should be 0 or 1 but '{0}'".format(axis))
    
    h1, w1 = img1.shape[:2]
    h2, w2 = img2.shape[:2]
    vis = None
    if axis == 1:
        vis = np.zeros((max(h1, h2), w1+w2, 3), np.uint8)
        vis[:h1, :w1, :3] = img1
        vis[:h2, w1:w1+w2, :3] = img2
    else:
        vis = np.zeros((h1+h2, max(w1, w2), 3), np.uint8)
        vis[:h1, :w1, :3] = img1
        vis[h1:h1+h2, :w2, :3] = img2
    return vis

# Parse arguments
ap = argparse.ArgumentParser(description='Script to get number of occurrence template on image with additional checks.' +
                            ' Feature detection and matching used for making final decision.')
ap.add_argument('-q', '--query', required=True, help='Query image path. Path to query image')
ap.add_argument('-t', '--train', required=True, help='Train image path. Path to train image')
ap.add_argument('-r', '--ratio', default=0.65, type=float, help='Threshold ratio (0.01 - 1) Default 0.65 is a good value to start with,' +
                            ' it detected all template with a minimum of false positives.')
ap.add_argument('-o', '--output', help='Output path. Path to output image. Should contains extension equal to main img')
args = vars(ap.parse_args())

# Assign and verify arguments
query_path = args["query"]
train_path = args["train"]
output_path = args["output"]
threshold = args["ratio"]

if not os.path.isfile(query_path):
    sys.exit("Can't find query file on path '{0}'".format(query_path))
if not os.path.isfile(train_path):
    sys.exit("Can't find train image on path '{0}'".format(train_path))

image = cv2.imread(train_path)
query = cv2.imread(query_path)
h, w = query.shape[:2] # Size of query (note! that collumns and rows switched in opencv)

# Common consts
#  Radius is a distanse between points to decide that template matches are equal. Use as radius 50% of min side of query
radius = min([h, w]) * 0.5
#  Offset is value that used to deside if matched points has the same coords in query and croped image.
#    It is  50% of radius of point sparsing
offset = radius * 0.5

#  Find matches and select results above threshold
result = cv2.matchTemplate(image, query, cv2.TM_CCOEFF_NORMED) # Use 'normed' method to easy choose a threshold from 0 to 1
loc = np.where(result >= threshold)
points = zip(*loc[::-1]) # Get matched points (note! - Remember to switch collumns and rows to get x(w),y(h))

#  Save vals of matched points
vals = [ result[pt[1]][pt[0]] for pt in points ]

#  Sparce points to reduce matches
sparsed_points = sparse_subset(points, radius)

#  Match features on every cropped image build from sparced point to deside if it is real object from query
#    Initiate SIFT detector
det = cv2.xfeatures2d.SIFT_create()
#    Create BFMatcher object
bf = cv2.BFMatcher()
#    Convert query and image to gray
query_gray = cv2.cvtColor(query,cv2.COLOR_BGR2GRAY)
image_gray = cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)

#    Loop memory
res_img = np.zeros((0, 0, 3), np.uint8) # cross loop image to save result

# {
#     'point': pt,
#     'matches': matches,
#     'good_matches': good_matches,
#     'common_good_matches': common_good_matches
# }
accepted_points = [] # points to keep. list with dict
rejected_points = [] # points to reject. list with dict
#    Loop to match
for pt in sparsed_points:
    # Crop image (note! remember - sparsed points is (x,y) but crop function gets args (y:len,x:len))
    crop_img = image_gray[pt[1]:pt[1] + h, pt[0]:pt[0] + w]

    # find the keypoints and descriptors with SURF
    img1, img2 = query_gray, crop_img
    kp1, des1 = det.detectAndCompute(img1, None)
    kp2, des2 = det.detectAndCompute(img2, None)

    # Match descriptors.
    matches = bf.knnMatch(des1,des2,k=2)

    # Store all the good matches as per Lowe's ratio test.
    good_matches = []
    for m,n in matches:
        if m.distance < 0.7*n.distance:
            good_matches.append(m)

    # Sort them in the order of their distance.
    good_matches = sorted(good_matches, key = lambda x:x.distance)

    # Get match points with the same coords on img1 and img2 (within small offset)
    common_good_matches = [] # list to keep matches
    for good_match in good_matches:
        is_x_matching_within_offset = abs(kp1[good_match.queryIdx].pt[1] - kp2[good_match.trainIdx].pt[1]) <= offset
        is_y_matching_within_offset = abs(kp1[good_match.queryIdx].pt[0] - kp2[good_match.trainIdx].pt[0]) <= offset
        if is_x_matching_within_offset and is_y_matching_within_offset: 
            common_good_matches.append(good_match)

    # Make decision. and save result to list
    # To keep sparsed point - We should have at least 3 common points and more or equal than half of good matches
    res_dict = {
                    'point': pt,
                    'matches': matches,
                    'good_matches': good_matches,
                    'common_good_matches': common_good_matches
                }
    if len(common_good_matches) >= 3 and len(common_good_matches) >= len(good_matches)*0.55:
        accepted_points.append(res_dict)
    else:
        rejected_points.append(res_dict)

    # Draw black frame on images for visual separation
    cv2.rectangle(img1, (0, 0), img1.shape[:2][::-1], (0, 0, 0), 2)
    cv2.rectangle(img2, (0, 0), img2.shape[:2][::-1], (0, 0, 0), 2)
    # Draw good matches to img
    img3 = cv2.drawMatches(img1, kp1, img2, kp2, good_matches, None, flags=2)
    # Draw common good matches to img
    img4 = cv2.drawMatches(img1, kp1, img2, kp2, common_good_matches, None, flags=2)

    # Add images to result
    img34 = concatenate_cv2_images(img3, img4, axis=1)
    res_img = concatenate_cv2_images(res_img, img34, axis=0)


#  Draw red rectangle on matched querys
for pt in points:
    cv2.rectangle(image, pt, (pt[0] + w, pt[1] + h), (0, 0, 255), 2)

#  Draw blue rectangle on matched querys, find centers of the rectangles. Draw small sircles on the centers
accepted_rectangle_centers = []
for pt in [ point_dict['point'] for point_dict in accepted_points ]:
    # blue rectangle
    cv2.rectangle(image, pt, (pt[0] + w, pt[1] + h), (255, 0, 0), 2)
    rectangle_center = (pt[0] + w/2, pt[1] + h/2)
    # blue circle r=10
    cv2.circle(image, rectangle_center, 10, (255, 0, 0), thickness=2, lineType=8, shift=0)
    accepted_rectangle_centers.append(rectangle_center)

print( "Done with processing query image '{0}' on train image '{1}'.".format(os.path.basename(query_path), os.path.basename(train_path)) )
print( "Threshold: '{0}'. Radius: '{1}'. Offset: '{2}'.".format(threshold, radius, offset) )
print( "Draft points found: '{0}'. first 10 points: '{1}'".format(len(points), points[:10]) )
print( "Clouds found: '{0}'. points: '{1}'".format(len(sparsed_points), sparsed_points) )
print( "Accepted points: '{0}'. Details:'{1}'.".format(
            len(accepted_points),
            [ { 'mtc': len(point_dict['matches']),
                'gd': len(point_dict['good_matches']),
                'cmn': len(point_dict['common_good_matches'])} for point_dict in accepted_points ]))
print( "Rejected points: '{0}'. Details:'{1}'.".format(
            len(rejected_points),
            [ { 'mtc': len(point_dict['matches']),
                'gd': len(point_dict['good_matches']),
                'cmn': len(point_dict['common_good_matches'])} for point_dict in rejected_points ]))
print( "Accepted rectangle centers: '{0}'.".format(accepted_rectangle_centers) )

# Save result to file if 'output' param provided
if not output_path == None:
    cv2.imwrite(output_path, concatenate_cv2_images(image, res_img))
    print( "Result image with located objects from query img saved in '{0}'.".format(output_path) )
