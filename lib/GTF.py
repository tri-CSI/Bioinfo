#!/usr/bin/env python
"""
GTF.py
Kamil Slowikowski
December 24, 2013

Changed by: Tran Minh Tri
Org: CTRAD - CSI
ver: 0.0.1

Read GFF/GTF files. Works with gzip compressed files and pandas.

    http://useast.ensembl.org/info/website/upload/gff.html
	
Source: https://gist.github.com/slowkow/8101481
"""
 
 
from collections import defaultdict
import gzip
import pandas as pd
import re
 
 
GTF_HEADER  = ['seqname', 'source', 'feature', 'start', 'end', 'score',
               'strand', 'frame']
R_SEMICOLON = re.compile(r'\s*;\s*')
R_COMMA     = re.compile(r'\s*,\s*')
R_KEYVALUE  = re.compile(r'(\s+|\s*=\s*)')
 
 
def dataframe(filename):
    """ Return 2 dictionaries for GeneId -> Gene name and transcript_id -> (gene_id, gene_name)
    """
    # Each column is a list stored as a value in this dict.
    result = defaultdict(list)
    GeneIdDict = {}
    TranScIdDict = {}
	
    for i, line in enumerate(lines(filename)):
        for key in line:
            if key == "transcript_id" and not key in TranScIdDict:
                TranScIdDict[line[key]] = (line["gene_id"], line["gene_name"])
            if key == "gene_id" and not key in GeneIdDict:
                GeneIdDict[line[key]] = line["gene_name"] 
    return (GeneIdDict, TranScIdDict)
 
 
def lines(filename):
    """Open an optionally gzipped GTF file and generate a dict for each line.
    """
    fn_open = gzip.open if filename.endswith('.gz') else open
 
    with fn_open(filename) as fh:
        for line in fh:
            if line.startswith('#'):
                continue
            else:
                yield parse(line)
 
 
def parse(line):
    """Parse a single GTF line and return a dict.
    """
    result = {}
 
    fields = line.rstrip().split('\t')
 
    for i, col in enumerate(GTF_HEADER):
        result[col] = _get_value(fields[i])
 
    # INFO field consists of "key1=value;key2=value;...".
    infos = re.split(R_SEMICOLON, fields[8])
 
    for i, info in enumerate(infos, 1):
        # It should be key="value".
        try:
            key, _, value = re.split(R_KEYVALUE, info)
        # But sometimes it is just "value".
        except ValueError:
            key = 'INFO{}'.format(i)
            value = info
        # Ignore the field if there is no value.
        if value:
            result[key] = _get_value(value)
 
    return result
 
 
def _get_value(value):
    if not value:
        return None
 
    # Strip double and single quotes.
    value = value.strip('"\'')
 
    # Return a list if the value has a comma.
    if ',' in value:
        value = re.split(R_COMMA, value)
    # These values are equivalent to None.
    elif value in ['', '.', 'NA']:
        return None
 
    return value