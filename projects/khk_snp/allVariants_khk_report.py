#!/bin/python3
# version 0.0.1
# Author: Tran Minh Tri
# Organization: CSI - CTRAD

"""
Usage:
python3 var_report.py (in the directory of interest)

Input file(s):
        GC*_asn_maf.txt
Output file(s):
        AllAnnotatedVariants.txt
Tools:
        Process line-by-line, file-by-file with Python
"""

import glob
from collections import OrderedDict

def parseReads(frmt, reads):
    frmt = frmt.split(':')
    reads = reads.split(':')
    result = ''
    for (i, element) in enumerate(frmt):
        if element == 'AD':
            result = reads[i]
            break
    result = result.split(',')
    return result[0] + '|' + result[1]

print('Listing files to be processed:')
cases = {}
for file in glob.glob('GC*_allVar.txt'):
    case = file.split('_')[0]
    cases[case] = file
    print('\t', file)

cases = OrderedDict(sorted(cases.items(), key=lambda t: t[0]))

variants = {}
var_count = 0
last_case = ''
exclude = [2, 5, 6, 7, 8, 9]
exclude.reverse()

for case in cases:
    summary = {}
    last_case = case
    # Read file
    file = open(cases[case], 'r')
    print('Reading input file:', file.name)

    for line in file:
        if "#" in line:
            continue
        var = line.split('\t')
        key = var[0] + '_' + var[1] + '_' + var[3] + '_' + var[4]
        if not key in variants:
            var_count += 1
            var_cases = {}
            var_cases[case] = 1
            var_sum = 1
            var_res = 1 if case in ['GC117', 'GC119'] else 0
            var_nonRes = 1 if case in ['GC127', 'GC84'] else 0
            var_quals = {}
            var_quals[case] = var[5]
            var_reads = {}
            var_reads[case] = parseReads(var[8], var[9])
            for item in exclude:
                var.pop(item)
            variants[key] = [var_cases, var_sum, var_res, var_nonRes, var_quals, var_reads, "\t".join(var)]
        else:
            variants[key][0][case] = 1 # cases
            variants[key][1] += 1 # sum
            variants[key][2] += case in ['GC117', 'GC119'] and 1 or 0
            variants[key][3] += case in ['GC127', 'GC84'] and 1 or 0
            variants[key][4][case] = var[5] # qual
            variants[key][5][case] = parseReads(var[8], var[9]) # reads
    file.close()

print('Generating header')
header = []
header.append('ID')
header.append('Variant')
for case in cases: 
    header.append(case)
header.append('Sum')
header.append('Responders sum (117, 119)')
header.append('Non-responders sum (127, 84)')
for case in cases: 
    header.append(case + '_Quality')
for case in cases: 
    header.append(case + '_Reads')
ifile = open(cases[last_case], 'r')
for line in ifile:
    if '#CHR' in line:
        in_header = line.split('\t')
        for item in exclude:
            in_header.pop(item)
        header += in_header
        break
ifile.close()

print('Writing output file...')
ofile = open('AllAnnotatedVariants.txt', 'w')
ofile.write('\t'.join(header))
ctr = 0
for key in variants:
    ctr += 1
    if ctr % 10000 == 0:
        print('\t' + str(ctr) + ' variants writen')
    [var_cases, var_sum, res, nonRes, quals, reads, details] = variants[key]
    line = 'var' + str(ctr) + '\t' + key + '\t'
    for case in cases:
        if case in var_cases:
            line += '1\t'
        else:
            line += '0\t'
    line += str(var_sum) + '\t' + str(res) + '\t' + str(nonRes) + '\t'
    for case in cases:
        if case in quals:
            line += quals[case] + '\t'
        else:
            line += '\t'
    for case in cases:
        if case in reads:
            line += reads[case] + '\t'
        else:
            line += '\t'
    line += details
    ofile.write(line)
print('\t' + str(ctr) + ' variants writen')
print('Finish writing ' + ofile.name)
ofile.close()
