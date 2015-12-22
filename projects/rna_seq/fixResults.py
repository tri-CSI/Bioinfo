# this script 
# fixResults.py
# version 0.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 fixResults.py (in the directory of interest)

Input file(s): 
	*_toTranscriptome_cov.average.txt
Output file(s): 
	*.average.txt
Tool(s):
	awk
"""


import glob
import os

cases = set()
for file in glob.glob('*_toTranscriptome_cov.average.txt'):
	cases.add(file)

newFiles = []
for inFile in cases:
	print('Processing ', inFile)
	newFile = inFile.split('_')[0] + '.average.txt'
	
	command =  "awk -F '\t' -v OFS='\t' '{ if ($1~/^HGNC/) print $2, $1, $3, $4, $5; else print}' "
	command += inFile + ' > ' + newFile
	print(command)
	os.system(command)