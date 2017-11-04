# python intto2comp.py  <input_file> output_file
import sys

filein = sys.argv[1];
fileout = sys.argv[2];

l = []
out = []
with open(filein,'r') as f:
	s = f.readline();

l = s.split(',');

for item in l:
	num = int(item.strip())
	bits = 32
	k = format(num if num >= 0 else (1 << bits) + num, '032b')
	out.append(k)

fd = open(fileout,'w')
for i in out:
	print >> fd, i