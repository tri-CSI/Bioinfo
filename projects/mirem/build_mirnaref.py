#!/usr/bin/python3

"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 build_mirnaref.py hairpin mature dblist
"""

import argparse, sys, gzip

parser = argparse.ArgumentParser( description="Convert miRNA family into miRNA, one line per entry." )
#parser.add_argument( 'hairpin', metavar="hairpinfa", type = str, help='hairpin.fa.gz from mirbase.' )
parser.add_argument( 'mature', metavar="maturefa", type = str, help='mature.fa.gz from mirbase.' )
parser.add_argument( 'dblist', metavar="dblist", type = str, help='list of database name and the respective filename.' )
		
args = parser.parse_args()
serr = sys.stderr

mirnaList = {}
filelist = {}
#accession = {}
matureseq = {}

#print('Reading hairpin file', file=serr)
#with gzip.open(args.hairpin) as refFile:
#	for line in refFile:
#		line = line.decode("utf-8")
#		if not '>' in line: continue # skip sequence lines
#		fields = line.strip().split(' ')
#		accession[fields[0][1:]] = fields[1]	
#		print(fields[0][1:])

print('Reading mature file', file=serr)
with gzip.open(args.mature) as refFile:
	for line in refFile:
		fields = line.decode("utf-8").strip().split(' ')
		seq = refFile.readline().decode("utf-8").strip() # mature sequence is on the next line
		matureseq[fields[0][1:]] = seq

print('Reading database list', file=serr)
with open(args.dblist) as refFile:
	for line in refFile:
		[loc, name] = line.strip().split(':')
		filelist[loc] = name

for efile in filelist:
	dbname = filelist[efile]
	print('Reading database:', dbname, file=serr)
	with open(efile) as dbfile:
		for line in dbfile:
			mirna = line.strip()
			try:
				if mirna in mirnaList:
					mirnaList[mirna][1] += '|' + dbname
				else:
					mirnaList[mirna] = [mirna, dbname, matureseq[mirna]]
			except:
				print('mirna not recorded:', mirna, file=serr)
		

print('Writing miRNA info', file=serr)
for record in mirnaList:
	print(';'.join(mirnaList[record]))

