#!/usr/bin/python3
# version 0.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 extractSam.py Sequence_list < in.sam > out.sam

Input file(s):
        Sam file
	List of sequences to extract (1 per line)
Output file(s):
        Extracted sam file
Tools:
        Process line-by-line with Python3
"""

import os, sys, argparse

def main(args):
	seq_list = os.path.basename(getattr(args, "seq_list"))
		
	reads = set()
	with open(seq_list) as seqFile:
		for line in seqFile:
			reads.add(line.strip())

	for line in sys.stdin:
		ID = line.split("\t")[0].strip()
		if ID in reads or "@" in ID:
			sys.stdout.write(line)

##########################################

if __name__ == "__main__":
        parser = argparse.ArgumentParser( description="Read sam stream from std input, filter reads provided by seq_list and output to stdout" )
        parser.add_argument( "seq_list", metavar="List of reads to extract" )
        args = parser.parse_args()
        main(args)

