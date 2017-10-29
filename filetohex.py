# python filetohex.py  <input_file> output_file

import numpy as np
import sys

filein = sys.argv[1];
fileout = sys.argv[2];

l = []

with open(filein,'r') as f:
	for line in f:
		k = int(line.strip());
		h = hex(k)
		h = h.split('x')[1]
		l.append(h.strip())


fd = open(fileout,'w')
for i in l:
	print >> fd, i

