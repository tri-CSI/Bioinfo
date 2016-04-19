#!/usr/bin/python3

"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 build_genesRef.py dblist
"""

import argparse, sys, gzip

parser = argparse.ArgumentParser( description="Build geneRef files" )
#parser.add_argument( 'hairpin', metavar="hairpinfa", type = str, help='hairpin.fa.gz from mirbase.' )
parser.add_argument( 'dblist', metavar="dblist", type = str, help='list of database name and the respective filename.' )
		
args = parser.parse_args()
serr = sys.stderr

geneList = {}
filelist = {}
#accession = {}
matureseq = {}

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

