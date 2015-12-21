#!/usr/bin/python3
"""
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: python3 annotateBedgraph.py <reffile.gtf> <infile> <outfile>
"""

import argparse
import sqlite3 as db

parser = argparse.ArgumentParser( description="Convert miRNA family into miRNA, one line per entry." )
parser.add_argument( 'reffile', metavar="ref_gtf_file", type = str, help='Gtf file containing gene info.' )
parser.add_argument( 'infile', metavar="input_file", type = str, help='text file in the format: geneSymbol\tmiRnaFamily.' )
parser.add_argument( 'outfile', metavar="output_file", type = str, help='text file in the format: geneSymbol\tmiRna.' )
		
args = parser.parse_args()

createGtf = '''
DROP TABLE IF EXISTS gtf;
CREATE TABLE gtf 
(id INTEGER PRIMARY KEY, chr text, src text, type text, start int, end int, ref1 text, direction text, ref2 text, anno text);
'''

insertGtf = '''insert into gtf (chr, src, type, start, end, ref1, direction, ref2, anno) values (?,?,?,?,?,?,?,?,?);'''

selectGene = '''select anno from gtf WHERE chr=:Chr AND type="gene" AND start <= :End AND end >= :Start'''

conn = db.connect('database.db')
with conn:	
	c = conn.cursor()
	
	c.executescript(createGtf)
	with open(args.reffile) as ifile:
		for line in ifile:
			if "#" in line: continue
			values = line.strip().split("\t")
			if not values[2] == "gene": continue
			values[3] = int(values[3])
			values[4] = int(values[4])
			values = tuple(values)
			c.execute(insertGtf, values)
	ctr = 0
	with open(args.infile) as ifile:
		with open(args.outfile, "w") as ofile:
			for line in ifile:
				ctr += 1
				if ctr %10000 == 0:
					print(ctr,"lines")
				line = line.strip().split("\t")
				try:
					chrom = line[0]
					startPos = int(line[1]) 
					endPos = int(line[2])
					
					c.execute(selectGene, {"Chr": chrom, "Start": startPos, "End": endPos} )

					rows = c.fetchall()
					for row in rows:
						anno = row[0].split(';')
						geneSymbol = ''
						for entry in anno:
							if "gene_name" in entry:
								geneSymbol = entry.split('"')[1]
								break

						if not geneSymbol == '':
							ofile.write("\t".join([geneSymbol, line[3]])+"\n")
				except: pass			
