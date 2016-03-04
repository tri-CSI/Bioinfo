#!/usr/bin/python3
# version 1.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 identify_mouse.py <human.bam> <mse.bam>

Input file(s):
        Human alignment bam file
	mouse alignment bam file
Output file(s):
        Human sam file with low-er quality mapped reads subtracted TO STDOUT without header
Tools:
        Process line-by-line with Python3
"""

import argparse, sys
import pysam as ps

parser = argparse.ArgumentParser( description="" )
parser.add_argument( "human", metavar="<name-sorted human bam file>" )
parser.add_argument( "mouse", metavar="<name-sorted mouse bam file>" )
parser.add_argument( "-s", "--strict", action='store_true', help="Only keep reads that are strictly better in human bam file" )
parser.add_argument( "-o", "--output", help="Write output file to specified file name rather than standard output" )
parser.add_argument( "-m", "--extracted", help="Write extracted reads to this file" )
args = parser.parse_args()

# Total number of reads substracted from human bam
count = 0

# Print reads if pass quality comparison
humanf = ps.AlignmentFile( args.human )
mousef = ps.AlignmentFile( args.mouse )
ofile = ps.AlignmentFile( args.output, 'wb', template=humanf )
exfile = open( args.extracted, 'a' )

human_idx = humanf.fetch( until_eof = True )
mouse_idx = mousef.fetch( until_eof = True )

print("Traversing human bam file by reads")

read = next( human_idx, None )
mread = next( mouse_idx, None )
mycount = 1

while True:
    if read is None: exit()
    curr = None
    mouse = None
    
    # class to hold Reads and Mates of the same name
    class ReadMate:
        def __init__( self, name, qual, firstline ):
            self.lines = [firstline]
            self.count = 1
            self.tscore = qual
            self.name = name
    
    curr = ReadMate(read.query_name, read.mapping_quality, read)
    
    while True:
        read = next( human_idx, None )
        mycount += 1
        if mycount % 10000000 == 0: print(mycount)
    
        if read is not None and read.query_name == curr.name:
            curr.count += 1
            curr.lines.append( read )
            curr.tscore += read.mapping_quality
        else:
            break
    
    while mread is not None:
        if mread.query_name == curr.name:
            if not mouse:
                mouse = ReadMate( mread.query_name, mread.mapping_quality, mread)
            else:
                mouse.count += 1
                mouse.lines.append( mread )
                mouse.tscore += mread.mapping_quality
        elif mread.query_name > curr.name:
            break
        mread = next( mouse_idx, None )
    
    keep = True

    if mouse:
        if (mouse.tscore / mouse.count) > (curr.tscore / curr.count ) or (args.strict and (mouse.tscore / mouse.count) == (curr.tscore / curr.count ) ):
            keep = False    
            count += curr.count
            
    if keep:
        for each in curr.lines:
            ofile.write( each )           
    elif (args.extracted):
        exfile.write( curr.name )

humanf.close()
mousef.close()
ofile.close()
exfile.close()

print("Total substracted:", count)
