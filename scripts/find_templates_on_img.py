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

# Parse arguments
ap = argparse.ArgumentParser(description='Script to get number of occurrence template on image')
ap.add_argument('-t', '--template', required=True, help='Template path. Path to template image')
ap.add_argument('-i', '--image', required=True, help='Main image path. Path to image')
ap.add_argument('-r', '--ratio', default=0.65, type=float, help='Threshold ratio (0.01 - 1) Default 0.65 is a good value to start with,' +
                            ' it detected all template with a minimum of false positives.')
ap.add_argument('-o', '--output', help='Output path. Path to output image. Should contains extension equal to main img')
args = vars(ap.parse_args())

# Assign and verify arguments
template_path = args["template"]
image_path = args["image"]
output_path = args["output"]
threshold = args["ratio"]

if not os.path.isfile(template_path):
    sys.exit("Can't find template file on path '{0}'".format(template_path))
if not os.path.isfile(image_path):
    sys.exit("Can't find image on path '{0}'".format(image_path))

image = cv2.imread(image_path)
template = cv2.imread(template_path)
h, w = template.shape[:2] #Size of template

result = cv2.matchTemplate(image, template, cv2.TM_CCOEFF_NORMED) # Use 'normed' method to easy choose a threshold
loc = np.where(result >= threshold)

points = zip(*loc[::-1]) # Switch collumns and rows and get matched points

#  Save vals of matched points
#  Draw red rectangle on matched templates
vals = []
for pt in points:
    cv2.rectangle(image, pt, (pt[0] + w, pt[1] + h), (0, 0, 255), 2)
    vals.append(result[pt[1]][pt[0]])

#  Radius is a distanse between points to deside that points are equal. Use as radius 50% of min side of template
radius = min([h, w]) * 0.5
sparsed_points = sparse_subset(points, radius)

#  Draw blue rectangle on matched templates, find centers of the rectangles. Draw small sircles on the centers
sparsed_rectangle_centers= []
for pt in sparsed_points:
    # blue rectangle
    cv2.rectangle(image, pt, (pt[0] + w, pt[1] + h), (255, 0, 0), 2)
    rectangle_center = (pt[0] + w/2, pt[1] + h/2)
    # blue circle r=10
    cv2.circle(image, rectangle_center, 10, (255, 0, 0), thickness=2, lineType=8, shift=0)
    sparsed_rectangle_centers.append(rectangle_center)

print( "Done with processing template '{0}' on image '{1}'.".format(os.path.basename(template_path), os.path.basename(image_path)) )
print( "Template size(h, w): '{0}, {1}'.".format(h, w) )
print( "Found: '{0}'.".format(len(points)) )
print( "Threshold: '{0}'.".format(threshold) )
if len(vals) > 0:
    print( "Accepted values: '{0}'. Min: '{1}'. Max: '{2}'.".format(vals, min(vals), max(vals)) )
    print( "Accepted points: '{0}'.".format(points) )
    print( "Point clouds: '{0}'. With radius:'{1}'. With coords: '{2}'.".format( len(sparsed_points), radius, sparsed_points) )
    print( "Rectangle centers: '{0}'.".format(sparsed_rectangle_centers) )

# Save result to file if 'output' param provided
if not output_path == None:
    cv2.imwrite(output_path, image)
    # cv2.imwrite("{0}/res{1}.png".format(os.path.dirname(output_path),datetime.now().strftime('%Y%m%dT%H%M%S')),cv2.normalize(result, None, 0, 255, norm_type=cv2.NORM_MINMAX))
    print( "Result image with located template saved in '{0}'.".format(output_path) )
