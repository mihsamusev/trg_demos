import numpy as np
import cv2
from matplotlib import pyplot as plt
import json

# Load frame pixel coordinates and coresponding ortophoto 
# UTM coordinates
pts_pix = np.loadtxt('data/pix.csv', delimiter=',')
pts_utm = np.loadtxt('data/utm.csv', delimiter=',')

# Calculate transformation matrix h to map UTM to pixels,
# calculate its inverse to map backwards
h, status = cv2.findHomography(pts_utm, pts_pix)
hinv = np.linalg.inv(h)
print(h)

# conversion functions
def pix2utm(pix, hinv):
    '''
    pix: [N x 2] numpy array of pixel coordinates
    hinv: [3 x 3] inverse homography matrix
    
    output: [N x 2] numpy array of UTM coordinates
    '''
    pix = np.append(pix, np.ones((pix.shape[0],1)), axis=1)
    utm = np.dot(hinv, pix.T)
    utm = utm / utm[2,:]
    return utm.T

def utm2pix(utm, hinv):
    '''
    utm: [N x 2] numpy array of UTM coordinates
    h: [3 x 3] homography matrix
    
    output: [N x 2] numpy array of pixel coordinates
    '''
    utm = np.append(utm, np.ones((utm.shape[0],1)), axis=1)
    pix = np.dot(h, utm.T)
    pix = pix / pix[2,:]
    return pix.T

# generate some test data drawn on either frame in pixels
# or ortophoto in utm coordinates,
test_pts_pix = np.array([
    [980, 766],
    [50, 329],
    [251, 331],
    [1918, 747],
    [980, 766]
])

test_pts_utm2 = np.array([
    [559069.1, 6319219.6],
    [559153.8, 6319218.9],
    [559153.8, 6319215.8],
    [559069.1, 6319216.6],
    [559069.1, 6319219.6]
])

# convert data to the oppsite coordinate system
test_pts_utm = pix2utm(test_pts_pix, hinv)
test_pts_pix2 = utm2pix(test_pts_utm2, h)

# visualize
orto = cv2.imread("data/orto.png")
orto = cv2.cvtColor(orto, cv2.COLOR_BGR2RGB)
frame = cv2.imread("data/frame.png")
frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
with open("data/orto_extents.json","r") as f:
    ext = json.load(f)

fig, axs = plt.subplots(1, 2)

axs[0].imshow(frame)
axs[0].plot(test_pts_pix[:,0], test_pts_pix[:,1], "r-s", label="drawn on frame")
axs[0].plot(test_pts_pix2[:,0], test_pts_pix2[:,1], "b-o", label="mapped from orto")
axs[0].set_title("Video frame")
axs[0].legend()

axs[1].imshow(orto, extent=[ext["xmin"], ext["xmax"], ext["ymin"], ext["ymax"]])
axs[1].plot(test_pts_utm[:,0], test_pts_utm[:,1], "r-s", label="mapped from frame")
axs[1].plot(test_pts_utm2[:,0], test_pts_utm2[:,1], "b-o", label="drawn on orto")
axs[1].set_title("Ortophoto")
axs[1].set_xlabel("easting [m]")
axs[1].set_ylabel("northing [m]")
axs[1].legend()

plt.show()