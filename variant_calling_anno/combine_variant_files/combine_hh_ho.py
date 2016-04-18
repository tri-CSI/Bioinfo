#!/usr/bin/python2
# Author: Tran Minh Tri
# Combine 2 lists of variants (HH and HO) and label where each variant come from (HO, HH or both)

import argparse
import os
import sys
import time
import vcf


def main(args):
	counter = 1
	bf = 0
	bf_hh = 0
	bf_ho = 0
	hh = 0
	ho = 0

	file_HH = os.path.basename(getattr(args, "vcf_HH"))
	file_HO = os.path.basename(getattr(args, "vcf_HO"))    
	outfile = os.path.basename(getattr(args, "combined")) 

	reader_HH = vcf.Reader(open(file_HH))
	reader_HO = vcf.Reader(open(file_HO))
	writer = vcf.Writer(open(outfile ,"w"), reader_HH)
		
	for current in reader_HH:
		try:
			matches = reader_HO.fetch(str(current.CHROM), current.POS, current.POS)
		except:
			matches = []
		finally:
			for record in matches:
				if current.ALT == record.ALT:
					if current.QUAL > record.QUAL:
						current.ID = 'BF-HH'
						bf_hh = bf_hh + 1
					elif current.QUAL < record.QUAL:
						current = record
						current.ID = 'BF-HO'
						bf_ho = bf_ho + 1
					else:
						current.ID = 'BF'
						bf = bf + 1
			
			if not current.ID:
				current.ID = 'HH'
				hh = hh + 1
			current.ID = 'VAR' + str(counter) + '_' +  current.ID
			counter = counter + 1
			writer.write_record(current)
	
	# go through HO file	
	reader_HH = vcf.Reader(open(file_HH))
	reader_HO = vcf.Reader(open(file_HO))

	for current in reader_HO:
		try:
			matches = reader_HH.fetch(str(current.CHROM), current.POS, current.POS)
		except:
			matches = []
		finally:
			for record in matches:
				if current.ALT == record.ALT:
					current.ID = 'dun take'
			
			if not current.ID:
				current.ID = 'VAR' + str(counter) + '_HO'
				ho = ho + 1
				counter = counter + 1
				writer.write_record(current)
	
	print '***Summary***'
	print 'Category Total'
	print 'All     ', counter-1
	print 'HH      ', hh
	print 'HO      ', ho
	print 'BF      ', bf
	print 'BF-HH   ', bf_hh
	print 'BF-HO   ', bf_ho

	

##########################################

if __name__ == "__main__":
    START_TIME = time.time()
    parser = argparse.ArgumentParser( description="merge 2 vcf files" )
    parser.add_argument( "vcf_HH", metavar="HH_VCF_file" )
    parser.add_argument( "vcf_HO", metavar="HO_VCF_file" )
    parser.add_argument( "combined", metavar="outfile_name" )

    parser.add_argument( "-v", "--verbose", action="count", help="Verbose" )
    args = parser.parse_args()
    main(args)

    if args.verbose:
        end_time = time.time() - START_TIME
        print( "Total time taken: %d seconds (%.1fm)" % (end_time, end_time/60))
