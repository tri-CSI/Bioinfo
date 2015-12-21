#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python convert_ucsc2hgnc.py <ensembl2hgnc.txt> <infile-ucsc2ensembl.txt> <outfile-ucscToGeneName.txt>
"""

import argparse
import sqlite3 as db

parser = argparse.ArgumentParser( description="Convert miRNA family into miRNA, one line per entry." )
parser.add_argument( 'reffile', metavar="ensembl2hgnc", type = str, help='text file containing gene conversion from Ensembl to HGNC.' )
parser.add_argument( 'infile', metavar="input_file", type = str, help='text file containing gene conversion from UCSC known genes to Ensembl.' )
parser.add_argument( 'outfile', metavar="output_file", type = str, help='text file in the format: ucsc\tMGIgenename.' )
		
args = parser.parse_args()

symbol = {}
with open(args.reffile, "r") as refFile:
	next(refFile)
	for line in refFile:
		line = line.strip().split("\t")
		if len(line) == 2:
			symbol[line[0]] = line[1]

with open(args.infile, "r") as ifile:
	with open(args.outfile, "w") as ofile:
		for line in ifile:
			line = line.strip().split("\t")
			if line[1] in symbol:
				ofile.write("\t".join([line[0], symbol[line[1]]]) +"\n")
			else: print("Whaaaaat!", line[1])	
