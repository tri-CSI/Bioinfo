#!/usr/bin/python
# -*- coding: utf-8 -*-

import sqlite3 as lite
import sys

# Start the connection
con = lite.connect('/var/www/mirem2/mirvis_progs/mirem.db')

with con:    
    cur = con.cursor()    
    for line in sys.stdin:
        try:
            mirna = line.strip().split()[0]
            cur.execute('SELECT sequence FROM Mirna WHERE mirna=:mra', { "mra" : mirna } )

            data = cur.fetchone()
            print(">" + mirna + "\n" + data[0] )
        except:
            pass
