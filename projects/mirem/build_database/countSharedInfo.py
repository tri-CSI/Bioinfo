#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 countShared.py TargetScan Diana MirDB Miranda Pictar PITA RNA22 
"""

import argparse
from itertools import combinations as nCr

parser = argparse.ArgumentParser( description="Generate relation file for circos plot." )
parser.add_argument( 'files', metavar="file", type = str, nargs="+", help='name of file(s) to be combined, Conserved and NonConserved should have been combined before running.' )
		
args = parser.parse_args()

syms = [ 'tgs', 'dia', 'mdb', 'mrd', 'ptr', 'pit', 'r22' ]
pos = [ 0 for i in range(7) ]
color = { 2: 'yellow', 3: 'green', 4: 'blue', 5: 'orange', 6: 'purple', 7: 'red' }

files = []
for f in args.files:
	fset = set(line.strip() for line in open(f))
	files.append(fset)

files = [ list(k) for k in zip( syms, files, pos) ]

r = len(files)
count = 0
with open('segdup.txt', 'w') as ofile:
	while r>1:
		with open('segdup'+str(r)+'.txt', 'w') as ocase:
			with open('heatmap'+str(r)+'.txt', 'w') as hcase:
				for combo in nCr(files, r):
					intsect = set.intersection(*[k[1] for k in combo])
					nos = len(intsect)

					# write to out files:
					for pair in nCr(combo, 2):
						first, second = pair
						ocase.write("\t".join([ first[0], str(first[2]), str(first[2] + nos), second[0], str(second[2]), str(second[2] + nos)]) + "\n")
						count += 1
										
					# increment positions
					for k in combo: 
						k[1] -= intsect
						start =	k[2]
						end = start + nos
						hcase.write("\t".join([ k[0], str(start), str(end), 'color=' + color[r]]) + "\n")
						k[2] = end

		ofile.write(str(r) + str(count)	+ "\n")			
		r -= 1
