from PIL import Image
import numpy as np
import sys
image1 = sys.argv[1];
fileout = sys.argv[2];

img1 = Image.open(image1).convert('L');

arr1 = np.asarray(img1);


#arr1 = np.array([[1, 1, 1],[1,1,1],[1,1,1]])

out = []
bits = 32

R = arr1.shape[0]
C = arr1.shape[1]
ii = np.zeros((R,C), dtype = np.int)
ii[0][0] = arr1[0][0];
for i in range(1,R):
	ii[i][0] = ii[i-1][0]+ arr1[i][0];

for j in range(1,C):
	ii[0][j] = ii[0][j-1] + arr1[0][j]

for i in range(1,R):
	for j in range(1,C):
		ii[i][j] = ii[i-1][j] + ii[i][j-1] - ii[i-1][j-1] + arr1[i][j];

for i in range(0,R):
	for j in range(0,C):
		num = ii[i][j]
		k = format(num if num >= 0 else (1 << bits) + num, '032b')
		out.append(k)

fd = open(fileout,'w')
for i in out:
	print >> fd, i
		