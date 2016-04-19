#!/usr/bin/python3

"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 targetScan_fam2miRna.py <familyfile> <infile> <outfile>
"""

import argparse

parser = argparse.ArgumentParser( description="Convert miRNA family into miRNA, one line per entry." )
parser.add_argument( 'family', metavar="family_file", type = str, help='text file containing miRNA family and miRNA names.' )
parser.add_argument( 'infile', metavar="input_file", type = str, help='text file in the format: geneSymbol\tmiRnaFamily.' )
parser.add_argument( 'outfile', metavar="output_file", type = str, help='text file in the format: geneSymbol\tmiRna.' )
parser.add_argument( 'specid', metavar="species_ID", type = str, help='species ID (human: 9606, mouse: 10090,...).' )
		
args = parser.parse_args()

mirFam = {}

with open(args.family) as refFile:
	for line in refFile:
		if "family" in line: continue
		field = line.split()
		key = field[0]
		mir = field[3]
		if field[2] == args.specid:
			if key in mirFam: mirFam[key].append(mir)
			else: mirFam[key] = [mir]

with open(args.infile) as inFile:
	with open(args.outfile, "w") as outFile:
		for line in inFile:
			if "Gene" in line: continue
			[gene, fam] = line.strip().split("\t")
			if not fam in mirFam: continue
			for mir in mirFam[fam]:
				line2write = gene + "\t" + mir + "\n"
				outFile.write(line2write)
