#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 combine.py <reffile> <infile> <outfile>
"""

import argparse
from itertools import combinations as nCr

fileno = 0

def printb(string):
	return '{0:b}'.format(string).zfill(fileno)

parser = argparse.ArgumentParser( description="Collate databases into mutually exclusive sets. Please provide databases in correct order." )
parser.add_argument( 'files', metavar="file", type = str, nargs="+", help='name of file(s) to be combined, you may supply one or more.' )
parser.add_argument( '-p', dest='prefix', metavar="prefix", type = str, help='Prefix of output name', required=True )
		
args = parser.parse_args()

files = []
for f in reversed(args.files):
	fset = set(line.strip() for line in open(f))
	files.append([fset, 1 << fileno])
	fileno += 1

r = fileno
while r>0:
	for combo in nCr(files, r):
		bitmask = sum(k[1] for k in combo)
		intsect = set.intersection(*[k[0] for k in combo])
		for k in combo: k[0] -= intsect
		
		# write to out files:
		filename = args.prefix + "." + printb(bitmask) + ".intersect.txt"
		with open(filename, "w") as ofile:
			print("Writing", filename)
			ctr = 0
			for line in intsect:
				ofile.write(str(r) + "\t" + line + "\n")
				ctr += 1
			print(ctr, "lines written.")
			
	r -= 1
