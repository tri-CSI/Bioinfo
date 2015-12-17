#!/bin/bash
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

ls -lh
log "!!" $? sddd
