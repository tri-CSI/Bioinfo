#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 oldsymbol2newhgnc.py <reffile> <infile> <outfile>
"""

import argparse

parser = argparse.ArgumentParser( description="Convert from one gene symbol to another gene symbol." )
parser.add_argument( 'ref', metavar="reference_file", type = str, help='name of reference file. Reference file is in format old_symbol\tnew_symbol, which can be extracted from gene2accession.gz - downloaded from NCBI website.' )
parser.add_argument( 'infile', metavar="input_file", type = str, help='Format: oldSymbol_gene\tdata' )
parser.add_argument( 'outfile', metavar="output_file", type = str, help='May or may not exist (existing file will be overwritten. Output format: new_symbol\tdata' )
		
args = parser.parse_args()

symbol = {}
with open(args.ref, "r") as refFile:
	next(refFile)
	for line in refFile:
		line = line.strip().split("\t")
		if len(line) == 2:
			symbol[line[0]] = line[1]

with open(args.infile, "r") as ifile:
	with open(args.outfile, "w") as ofile:
		for line in ifile:
			line = line.split("\t")
			if line[0] in symbol:
				ofile.write("\t".join([symbol[line[0]], line[1]]))
			else: print("Whaaaaat!", line[0])	
