#!/usr/bin/python2

# Script for counting unique reads and intersection between 2 files, line-by-line
# Developed by Tran Minh Tri
# Date: 28 May 2015


import argparse
import os
import sys
import time


def main(args):
	setA = set()
	setBlessA = set()
	setAB = set()
	
	for line in open(args.fileA):
		[chr,start,end] = line.split()
		setA.add((chr,start,end))
	
	for line in open(args.fileB):
		[chr,start,end] = line.split()
		item = (chr,start,end)
		if item in setA:
			setAB.add(item)
		else:
			setBlessA.add(item)
	
	print 'Set A unique:', len(setA) - len(setAB), 'Set A:', len(setA)
	print 'Set B unique:', len(setBlessA), 'Set B:', len(setBlessA) + len(setAB)
	print 'Intersection:', len(setAB)
	
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
		print "File name:", file
		end_time = time.time() - START_TIME
		print( "Total time taken: %d seconds (%.1fm)" % (end_time, end_time/60))
