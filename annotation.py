# this script 
# annotation.py
# version 0.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 annotation.py (in the directory of interest)

Input file(s): 
	*.toTranscriptome.out.bam
Output file(s): 
	step 1 (sort): *.toTranscriptome.sorted.bam
	step 2 (anno): *_toTranscriptome_cov.txt
Tool(s):
	Sorting: samtools sort -f 
	Annotation: bedtools genomecov -d
"""


import glob
import os

cases = set()
for file in glob.glob('*.toTranscriptome.out.bam'):
	cases.add(file.split('.')[0])

newFiles = []
for entry in cases:
	print('Processing ',entry)
	sorted = entry + '.toTranscriptome.sorted.bam'
	newFile = entry + '_toTranscriptome_cov.txt'
	
	command = 'samtools sort ' + entry + '.toTranscriptome.out.bam '
	command += sorted + ' -f'
	print(command)
	os.system(command)
	
	command = 'bedtools genomecov -d -ibam ' + sorted
	command += '> ' + newFile
	print(command)
	os.system(command)
	
	print('Done')