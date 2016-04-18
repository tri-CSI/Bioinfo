#!/bin/bash

# Author: Tran Minh Tri
# A simple script to log processes
# Usage:
#    source log.sh
#    command to be logged
#    log "!!" $? [File created]

set -o history -o histexpand

log ()
{
echo "Process: $1" 
if [ "$2" -eq "0" ]; then
	echo "Process succeeds, file(s) created: $3" 
else
	echo "Process fails with status $2"
	echo "Script exits on $(date)"
fi
}

# Test
ls -lh
log "!!" $? None
