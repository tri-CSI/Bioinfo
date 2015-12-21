#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 combine.py <reffile> <infile> <outfile>

Verion 1.1: 11000 would include 11*** as well
"""

import argparse
from itertools import combinations as nCr

fileno = 0

def printb(string):
	return '{0:b}'.format(string).zfill(fileno)

def write_to_file(filename, data):
	with open(filename, "w") as ofile:
		print("Writing", filename)
		ctr = 0
		for line in data:
			ofile.write(str(r) + "\t" + line + "\n")
			ctr += 1
		print(ctr, "lines written.")
	

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
	consect = set()
	nonsect = set()
	for combo in nCr(files, r):
		bitmask = sum(k[1] for k in combo)
		intsect = set.intersection(*[k[0] for k in combo])
#		for k in combo: k[0] -= intsect
		consect = consect.union(intsect)
		if (bitmask & 0b010000000) == 0 and (bitmask & 0b000001000) == 0: 
			nonsect = nonsect.union(intsect)
		
		# write to out files:
		filename = args.prefix + "." + printb(bitmask) + ".intersect.txt"
		write_to_file(filename, intsect)
			
	# write to common file:
	filename = args.prefix + ".101110111.intersect." + str(r) + ".txt"
	write_to_file(filename, nonsect)
	filename = args.prefix + ".111111111.intersect." + str(r) + ".txt"
	write_to_file(filename, consect)
			
	r -= 1
