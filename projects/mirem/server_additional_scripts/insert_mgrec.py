#!/usr/bin/python
# -*- coding: utf-8 -*-

# 
# Load hsa and mmu miRNA database on to sqlite.
#
# Author: TRAN MINH TRI
# Date: 26 Nov 2015
# 

CREATE_SCRIPT='''
DROP TABLE IF EXISTS Mirna;
CREATE TABLE Mirna ( 
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    mirna TEXT UNIQUE, 
    sequence TEXT 
);
DROP TABLE IF EXISTS Genes;
CREATE TABLE Genes ( 
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    genename TEXT, 
    species TEXT,
    UNIQUE (genename, species) 
);
DROP TABLE IF EXISTS Databases;
CREATE TABLE Databases ( 
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    dbname TEXT UNIQUE, 
    desc TEXT 
);
DROP TABLE IF EXISTS GeneMirnaRec;
CREATE TABLE GeneMirnaRec ( 
    mirna_id INTEGER, 
    database_id INTEGER,
    gene_id INTEGER,
    FOREIGN KEY (mirna_id) REFERENCES Mirna(id), 
    FOREIGN KEY (database_id) REFERENCES Databases(id), 
    FOREIGN KEY (gene_id) REFERENCES Genes(id), 
    PRIMARY KEY (mirna_id, database_id, gene_id)
);
'''

import sqlite3 as lite
import argparse

# Get filenames to build database
parser = argparse.ArgumentParser( description="Load hsa and mmu miRNA database on to sqlite." )
parser.add_argument( 'human', metavar="<hsa-mir-ref>", type = str, help='human miRNA ref file' )
parser.add_argument( 'mouse', metavar="<mmu-mir-ref>", type = str, help='mouse miRNA ref file' )
parser.add_argument( 'humandb', metavar="<hsa-ref>", type = str, help='human miRNA dblist file' )
parser.add_argument( 'mousedb', metavar="<mmu-ref>", type = str, help='mouse miRNA dblist file' )
args = parser.parse_args()


fileList = {}
# A helper function
def load_db ( dblist ):
    with open ( dblist ) as ref:
        for line in ref:
            f, dbname = line.strip().split(":")
            fileList [ dbname ] = f
            cur.execute( "INSERT OR IGNORE INTO Databases VALUES (null, ?, null)", (dbname, ) )
    

def insert_one_db ( db, species ):
    with open ( fileList [ db ] ) as dbfile:
        for line in dbfile:
            try:
                gene, mirna = line.strip().split("\t")
            except:
                continue
            cur.execute( "INSERT OR IGNORE INTO Genes VALUES (null, ?, ?)", (gene, species) )
            cur.execute( "SELECT id FROM Genes WHERE genename = ? ", (gene, ) )
            gene_id = cur.fetchone()[0]
            cur.execute( "SELECT id FROM Mirna WHERE mirna = ? ", (mirna, ) )
            mirna_id = cur.fetchone()[0]
            cur.execute( "SELECT id FROM Databases WHERE dbname = ? ", (db, ) )
            db_id = cur.fetchone()[0]
            cur.execute( "INSERT OR IGNORE INTO GeneMirnaRec VALUES (?, ?, ?)", (mirna_id, db_id, gene_id) )
                            

def insert_mirnas( table, refFile ):
    query = "INSERT INTO " + table + " VALUES (null,?,?) " 
    
    with open( refFile ) as ref:
        for line in ref:
            mirna, dbs, seq = line.strip().split(";")
            cur.execute( query, (mirna, seq) )

# start the connection
con = lite.connect('mirem.db')

with con:
    cur = con.cursor()    
#    cur.executescript( CREATE_SCRIPT )

#    insert_mirnas( "Mirna", args.human )
#    insert_mirnas( "Mirna", args.mouse )
    load_db( args.humandb )
    
#for db in fileList:
#    with con:
#        cur = con.cursor()    
#        insert_one_db ( db, "hsa" )
#    load_db( args.mousedb )
#for db in fileList:
#    with con:
#        cur = con.cursor()    
#        insert_one_db ( db, "mmu" )
