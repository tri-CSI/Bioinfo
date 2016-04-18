#!/usr/bin/python3

"""
Script for counting unique variants and intersection between 2 variant-containing files
	* Variants are identified as (chr, pos, alt)
	* Line-by-line
	* Skip comments and empty lines
Developed by Tran Minh Tri
Date: 23 July 2015
"""

import argparse
import os
import sys
import time

def main(args):
	setA = set()
	setBlessA = set()
	setAB = set()
	fileA = args.fileA
	fileB = args.fileB
	
	for line in open(fileA):
		if '#' in line: continue
		var = line.split()
		chr = var[0]
		pos = var[1]
		alt = var[4]
		setA.add((chr,pos,alt))
	
	for line in open(fileB):
		if '#' in line: continue
		var = line.split()
		chr = var[0]
		pos = var[1]
		alt = var[4]
		item = (chr,pos,alt)
		if item in setA:
			setAB.add(item)
		else:
			setBlessA.add(item)
	
	print('Set A:', fileA.split("/")[-1], 'Set B:', fileB.split("/")[-1])
	print('Set A unique:', len(setA) - len(setAB), "\tSet A:", len(setA))
	print('Set B unique:', len(setBlessA), "\tSet B:", len(setBlessA) + len(setAB))
	print('Intersection:', len(setAB))
	
##########################################

if __name__ == "__main__":
	START_TIME = time.time()
	parser = argparse.ArgumentParser( description="count intersection element" )
	parser.add_argument( "--fileA", metavar="text file A" )
	parser.add_argument( "--fileB", metavar="text file B" )
	parser.add_argument( "-v", "--verbose", action="count", help="Verbose" )
	args = parser.parse_args()
	main(args)

	if args.verbose:
		end_time = time.time() - START_TIME
		print( "Total time taken: %d seconds (%.1fm)" % (end_time, end_time/60))
