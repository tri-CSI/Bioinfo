#!/usr/bin/python3
"""
    Author: TRAN Minh Tri - csitmt
    Date: Sep 2015
    Use: python3 mirBase_updator.py <reffile> <infile> <outfile> <mirna_col>
    
    v0.0.1: infile and outfile in format "gene    mirna"
    v0.0.2: User can select miRna column

"""

import sys

delimiter = "\t"
mirna_field = int(sys.argv[4]) - 1

symbol = {}
with open(sys.argv[1], "r") as refFile:
    next(refFile)
    for line in refFile:
        if "new record" in line: continue
        line = line.strip().split(delimiter)
        symbol[line[1]] = line[4]

with open(sys.argv[2], "r") as ifile:
    with open(sys.argv[3], "w") as ofile:
        for line in ifile:
            line = line.strip().split(delimiter)
            try:
                if line[mirna_field] in symbol:
                    # Replace current miRNA column with new one
                    #line[mirna_field] = symbol[line[mirna_field]]
                    # Add a new column
                    line.append( symbol[line[mirna_field]] )

                    ofile.write(delimiter.join(line)+"\n")
                else:
                    ofile.write(delimiter.join(line)+"\n")
                    #print(line[mirna_field])
            except: pass        
