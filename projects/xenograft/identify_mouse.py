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
parser = argparse.ArgumentParser( description="" )
parser.add_argument( "human", metavar="<human bam file>" )
parser.add_argument( "mouse", metavar="<mouse bam file>" )
parser.add_argument( "-s", "--strict", action='store_true', help="Only keep reads that are strictly better in human bam file" )
parser.add_argument( "-o", "--output", help="Write output file to specified file name rather than standard output" )
parser.add_argument( "-m", "--extracted", help="Write extracted read names to this file" )
args = parser.parse_args()

# Total number of reads substracted from human bam
count = 0
# Print reads if pass quality comparison
humanf = open(args.human)
mousef = open(args.mouse)
ofile = (args.output) and open(args.output, 'a') or sys.stdout

nextline = humanf.readline().strip()
mousenext = mousef.readline().strip()
findMouse = True

while True:
    # reset variables
    read = None
    mouse = None

    # class to hold Reads and Mates of the same name
    class ReadMate:
        def __init__( self, name, qual, firstline ):
            self.lines = [firstline]
            self.count = 1
            self.tscore = qual
            self.name = name
    
    # Register current read
    try:
        tokens = nextline.split("\t")
        if nextline == '' or len(tokens) < 11: 
            raise Exception('EOF or empty line or not enough arguments') 
    except Exception as e:
        print( e.args[0], file=sys.stderr )
        break
    except:
        print( "Unknown error", file=sys.stderr ) 
        break
    
    read = ReadMate(tokens[0], int(tokens[4]), nextline)
    
    # check next line(s)
    while True:
        nextline = humanf.readline().strip()
        try:
            tokens = nextline.split("\t")
            if tokens[0] == read.name:
                read.count += 1
                read.lines.append( nextline )
                read.tscore += int(tokens[4])
            else:   
                break    
        except Exception as e:
            print(e.args, file=sys.stderr)
            break    
        
    # Find matching mouse reads 
    while findMouse:
        tokens = mousenext.split("\t")
        if mousenext == '' or len(tokens) < 11: # EOF
            print( "No more mouse reads", file = sys.stderr )
            findMouse = False 
            break        
        elif tokens[0] < read.name: # loop until matched
            pass
        elif tokens[0] == read.name: # if matched
            if not mouse:
                mouse = ReadMate(tokens[0], int(tokens[4]), mousenext)
            else:
                mouse.count += 1
                mouse.lines.append( nextline )
                mouse.tscore += int(tokens[4])
        else: # if token[0] > read.name
            break    
        mousenext = mousef.readline().strip()
    
    # Compare quality and print
    keep = True
    if mouse: # if match is found
        if (mouse.tscore / mouse.count) > (read.tscore / read.count ) or (args.strict and (mouse.tscore / mouse.count) == (read.tscore / read.count ) ):
            keep = False    
            count += read.count
            # For debugging
#                    print("Extraction found")
#                    print("Read name:", read.name, "\tScore:", str(read.tscore), "\tCount:", str(read.count)) 
#                    print("Mouse name:", mouse.name, "\tScore:", str(mouse.tscore), "\tCount:", str(mouse.count)) 
#                    for line in read.lines: print(line)
            #if input("Continue?") == 'n': print("Total substracted:", count, file = sys.stderr); sys.exit()

    # Write results
    if keep:
        for line in read.lines:
            print(line, file=ofile)           
    elif (args.extracted):
        with open(args.extracted, 'a') as exfile:
            for line in read.lines:
                print(line, file=exfile)

humanf.close()
mousef.close()
ofile.close()

print("Total substracted:", count, file = sys.stderr)
