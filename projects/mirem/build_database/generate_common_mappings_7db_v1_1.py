#!/usr/bin/python3
# -*- coding: utf-8 -*-
"""
Created on Tue Sep  8 12:03:07 2015

@author: TRAN MINH TRI - CSITMT

Combine into {human,mouse}.1010001.intersect.{1,2,3,4}.txt
Change variables and run the script in progs folder
Compatible with combine_v1.1 script
"""

from itertools import combinations as comb
import os

progDirtory = "."
allDatabase = 9
conserveInc = [0b111111111, 0b101110111]
speciesList = ['human', 'mouse']
commondbMap = [1, 2, 3, 4, 5, 6, 7]

def printb(num): return '{0:b}'.format(num).zfill(allDatabase)
    
for species in speciesList:
    workingDir = progDirtory + "/" + species + "_intersect_records/"
    for nonCon in conserveInc:
        db = set()
        for shift in range(allDatabase): 
            if (nonCon >> shift) & 1 > 0: db.add(1 << shift)       
        for common in commondbMap:
            outfile = workingDir + species + "." + \
                printb(nonCon) + ".intersect." + str(common) + ".txt"
            infileList = []
            dbSet = comb(db, common)
            for combi in dbSet:
                bitmask = printb(sum([j for j in combi]))
                infileList.append(workingDir + species + "." + bitmask + ".intersect.txt")
            with open("tmp", "w") as out:
                out.write(''.join(sorted(set([open(f).read() for f in infileList]))))
                os.system("sort -u tmp > 'outfile'")
