# this script 
# compute_average.py
# version 0.0.1
# Author: Tran Minh Tri

##Usage
# python compute_average.py (in the directory of interest)

import glob
import os
import sys
sys.path.insert(0, '/12TBLVM/Data/MinhTri/6_SCRIPTS')
import GTF

print 'Loading gtf file'
hg19 = GTF.dataframe("/12TBLVM/Data/hg19-2/GENCODE/gencode.v22.annotation.gtf")

print 'Start reading files'
cases = set()
for file in glob.glob('*_toTranscriptome_cov.txt'):
	cases.add(file.split('.')[0])

newFiles = []
for entry in cases:
	print 'Processing ' + entry
	
	original_file = open(entry + '.txt', 'r')
	new_file = open(entry + '.average.txt', 'w')
	new_file.write("HGNC_symbol\tEnsembl_symbol\tTranscript_id\tTotal_coverage\tAverage_coverage\n") # Header
	summary = {}
	
	total_cov = 0
	for line in original_file:
		(tscpt_id, tscpt_no, tscpt_cov) = line.split("\t")		
		tscpt_cov = int(tscpt_cov)
		tscpt_no = int(tscpt_no)
		if tscpt_no == 1:
			summary[tscpt_id] = (tscpt_cov, tscpt_cov)
			total_cov = tscpt_cov
		else:
			total_cov += tscpt_cov
			summary[tscpt_id] = (total_cov, total_cov/float(tscpt_no))
	
	for tscpt in summary:
		filtered = hg19[hg19.transcript_id == tscpt]
		HGSC_symbol = filtered['gene_name'].get_value(0) # 0-indexed
		Ensembl_id = filtered['gene_id'].get_value(0)
		
		next_line = HGSC_symbol + '\t' + Ensembl_id + '\t' + tscpt + '\t'
		(total_cov, average_cov) = summary[tscpt_id]
		next_line += total_cov + '\t' + average_cov + '\n'
		new_file.write(next_line)
			
	print 'Done processing ' + entry