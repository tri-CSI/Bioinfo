#!/usr/bin/python2

# Pipeline for extracting variants regions given in a bed file
# Developed by Tran Minh Tri
# Date: 21 May 2015


import argparse
import os
import sys
import time


def main(args):
	dict={}
	
	refFile = args.filter
	for line in open(refFile):
		[chr,start,end] = line.split()
		if chr in dict.keys():
			dict[chr].append([int(start), int(end)])
		else:
			dict[chr] = [ [int(start), int(end)] ]
	
	for file in args.files:
		outfile = os.path.splitext(file)[0] + ".filtered.txt"
		writer = open(outfile ,"w")
		
		for line in open(file):
			tokens = line.split()
			
			for intv in dict[tokens[0]]: 
				if int(tokens[1]) >= intv[0] and int(tokens[1]) <= intv[1]:
					writer.write(line)
			
		writer.close()
		
##########################################

if __name__ == "__main__":
	START_TIME = time.time()
	parser = argparse.ArgumentParser( description="filter vcf files" )
	parser.add_argument( "--files", metavar="vcf files", nargs="+")
	parser.add_argument( "--filter", metavar="bed file containing filtering coordinates" )
	parser.add_argument( "-v", "--verbose", action="count", help="Verbose" )
	args = parser.parse_args()
	main(args)
	
	if args.verbose:
		end_time = time.time() - START_TIME
		print( "Total time taken: %d seconds (%.1fm)" % (end_time, end_time/60))
