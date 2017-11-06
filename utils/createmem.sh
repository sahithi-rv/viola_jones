#!/bin/bash

i=1
for f in *.txt; do
	python intto2comp.py "$f" "$f.mem";
done