#!/usr/bin/python3
# version 1.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 compareMouse.py <human var list> <mse liftover> <out file name> <mouse genome fa>

Input file(s):
        Human variants list
	mouse corresponding liftover
	mouse genome fasta file
Output file(s):
        Annotated variant list
Tools:
        Process line-by-line with Python3
"""

import argparse
import os
import sys
import time
import subprocess as sp

def main(args):
	acgt = {}
	acgt['A'] = ['A', 'a', 'N', 'M', 'W', 'R', 'D', 'H', 'V']
	acgt['C'] = ['C', 'c', 'N', 'S', 'Y', 'M', 'B', 'H', 'V']
	acgt['G'] = ['G', 'g', 'N', 'K', 'S', 'R', 'B', 'D', 'V']
	acgt['T'] = ['T', 't', 'N', 'K', 'Y', 'W', 'B', 'H', 'D']
	varList = {}

	file_hu = getattr(args, "human")
	file_ms = getattr(args, "mouse")    
	outfile = getattr(args, "extracted") 
	counter = 0

	with open(file_ms, "r") as mseVar:
		for line in mseVar:
			counter += 1
			[chrm, start, end, varId] = line.strip().split()
			command = "samtools faidx " + getattr(args, "mse_genome")
			command += " " + chrm + ":" + start + "-" + start
			try:
				varList[varId] = sp.getoutput(command).split()[1]
			except:
				pass
			# print(command) # debug
			if counter % 10000 == 0:
				print(counter, "bases looked up")
		print(counter, "bases looked up")
		

	print("Finish getting mouse bases")

	counter = 0		
	with open(outfile, "w") as ofile:
		with open(file_hu, "r") as hu_file:
			for line in hu_file:
				if '#' in line: 
					ofile.write(line)
					continue
				counter += 1
				tokens = line.strip().split('\t')
				sameBase = False
				varId = tokens[2]
				if varId in varList:
					for var in tokens[4].split(','):
						try:
							if varList[varId] in acgt[var]:
								sameBase = True
						except: pass
						# print(var,varList[varId]) # debug

				if sameBase:
					tokens[2] = 'M:' + varList[varId]
				else:
					tokens[2] = 'H'
				ofile.write('\t'.join(tokens) +"\n")
				if counter % 10000 ==0:
					print(counter, "lines read")
			print(counter, "lines read")
						

if __name__ == "__main__":
	START_TIME = time.time()
	parser = argparse.ArgumentParser( description="get list of unique Var" )
	parser.add_argument( "human", metavar="<variant vcf file>" )
	parser.add_argument( "mouse", metavar="<mouse var list>" )
	parser.add_argument( "extracted", metavar="<outfile name>" )
	parser.add_argument( "mse_genome", metavar="<mouse genome fa file>" )

	parser.add_argument( "-v", "--verbose", action="count", help="Verbose" )
	args = parser.parse_args()
	main(args)

	if args.verbose:
		end_time = time.time() - START_TIME
		print( "Total time taken: %d seconds (%.1fm)" % (end_time, end_time/60))

