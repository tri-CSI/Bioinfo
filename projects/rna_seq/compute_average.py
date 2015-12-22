# this script 
# compute_average.py
# version 0.0.2
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 compute_average.py (in the directory of interest)

Input file(s): 
	*_toTranscriptome_cov.txt
Output file(s): 
	*_toTranscriptome_cov.average.txt
Tools:
	GTF.py to load GTF files
	Process line-by-line with Python
"""

import glob
import os
import sys
sys.path.insert(0, '/12TBLVM/Data/MinhTri/6_SCRIPTS')
import GTF

print('Loading gtf file.')
(GeneDict, TransScDict) = GTF.dataframe("/12TBLVM/Data/hg19-2/GENCODE/gencode.v22.annotation.gtf")

print('Listing files to be processed:')
cases = set()
for file in glob.glob('*_toTranscriptome_cov.txt'):
	cases.add(file.split('.')[0])
	print('\t', file)

for entry in cases:
	summary = {}
	
	# Read file
	original_file = open(entry + '.txt', 'r')
	print('Reading input file:', original_file.name)
	total_cov = 0
	counter = 0
	for line in original_file:
		(tscpt_id, tscpt_no, tscpt_cov) = line.split("\t")		
		tscpt_cov = float(tscpt_cov)
		tscpt_no = int(tscpt_no)
		
		if tscpt_no == 1:
			summary[tscpt_id] = (tscpt_cov, tscpt_cov)
			total_cov = tscpt_cov
		else:
			total_cov += tscpt_cov
			summary[tscpt_id] = (int(total_cov), total_cov/tscpt_no)
			
		counter += 1
		if counter % 10000000 == 0: print('\t', counter, 'lines read')	
	original_file.close()
	
	# Write file
	new_file = open(entry + '.average.txt', 'w')
	print('Writing output file:', new_file.name)
	new_file.write("HGNC_symbol\tEnsembl_symbol\tTranscript_id\tTotal_coverage\tAverage_coverage\n") # Header	
	counter = 0
	for key in summary:
		(total_cov, average_cov) = summary[key]
		
		(geneId, geneName) = TransScDict[key]
		Ensembl_id = geneId
		HGSC_symbol = geneName
		
		next_line = HGSC_symbol + '\t' + Ensembl_id + '\t' + key + '\t'
		next_line += str(total_cov) + '\t' + str(average_cov) + '\n'
		new_file.write(next_line)

		counter += 1
		if counter % 1000 == 0: print('\t', counter, 'lines')
	new_file.close()
	
	print('Done processing case', entry, 'with', counter, 'transcripts.')
