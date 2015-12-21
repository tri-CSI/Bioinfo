#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 mirBase_updator.py <reffile> <infile> <outfile>
"""

import sys

symbol = {}
with open(sys.argv[1], "r") as refFile:
	next(refFile)
	for line in refFile:
		if "new record" in line: continue
		line = line.strip().split("\t")
		symbol[line[1]] = line[4]

with open(sys.argv[2], "r") as ifile:
	with open(sys.argv[3], "w") as ofile:
		for line in ifile:
			line = line.strip().split("\t")
			try:
				if line[1] in symbol:
					ofile.write("\t".join([line[0], symbol[line[1]]])+"\n")
				else:
					ofile.write("\t".join(line)+"\n")
			except: pass		
