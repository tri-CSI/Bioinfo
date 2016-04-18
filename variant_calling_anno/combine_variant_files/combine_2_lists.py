#!/usr/bin/python3

"""
Script for combining unique variants and intersection between 2 variant-containing files
	* Do a Union for 2 files 
	* Variants are identified as (chr, pos, alt)
	* Line-by-line

Developed by Tran Minh Tri
Date: 23 July 2015
"""

import argparse
import os
import sys
import time

def main(args):
	dictA = {}
	setBlessA = set()
	setAB = set()
	fileA = args.fileA
	fileB = args.fileB
	case = fileA.split(".")[0].split("_")[1]
	type = fileA.split(".")[1]
	fileAB = case + '_union.' + type + ".txt"
	fileAaB = case + '_intersect.' + type + ".txt"
	interS = open(fileAaB, 'w')
	union = open(fileAB, 'w')
	
	for line in open(fileA):
		if '#' in line: continue
		var = line.split()
		chr = var[0]
		pos = var[1]
		alt = var[4]
		qual = float(var[5])
		dictA[(chr,pos,alt)] = [qual, line]
	
	ctr = 0
	for line in open(fileB):
		if '#' in line: continue
		var = line.split()
		chr = var[0]
		pos = var[1]
		alt = var[4]
		item = (chr,pos,alt)
		if item in dictA:
			setAB.add(item)
			if dictA[item][0] < float(var[5]):
				union.write(line)
				interS.write(line)
				dictA[item][0] = False 
			else:
				union.write(dictA[item][1])
				interS.write(dictA[item][1])
				dictA[item][0] = False 
		else:
			setBlessA.add(item)
			union.write(line)
		ctr += 1
	
	for key in dictA:
		if dictA[key][0]: 
			union.write(line)
			ctr += 1
	
	union.close()
	interS.close()
	
	print('Set A:', fileA.split("/")[-1], 'Set B:', fileB.split("/")[-1])
	print('Set A unique:', len(dictA) - len(setAB), 'Set A:', len(dictA))
	print('Set B unique:', len(setBlessA), 'Set B:', len(setBlessA) + len(setAB))
	print('Intersection:', len(setAB))
	print('Intersection file created:', fileAaB)	
	print('Union: ', ctr)
	print('Union file created:', fileAB)
	print('-------------')
	
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