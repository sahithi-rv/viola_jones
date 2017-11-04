#!/usr/bin

for i in `ls ../text_files`;
do
	echo $i;
	python intto2comp.py "../text_files/$i" "../mem_files/$i.mem";
done;