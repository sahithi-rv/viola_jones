from PIL import Image
import numpy as np
import sys
image1 = sys.argv[1];
fileout = sys.argv[2];

img1 = Image.open(image1).convert('L');

arr1 = np.asarray(img1);

out = []

R = arr1.shape[0]
C = arr1.shape[1]

for i in range(0,R):
	for j in range(0,C):
		num = arr1[i][j]
		k = format(num if num >= 0 else (1 << bits) + num, '016b')
		out.append(k)

fd = open(fileout,'w')
for i in out:
	print >> fd, i
