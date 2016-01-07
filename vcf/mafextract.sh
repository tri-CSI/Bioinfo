#!/bin/bash

# Usage:
#   ./mafextract.sh  [-e|s|b] annotated_varlist.txt > filtered_varlist.txt
# Flags:
#   e for EAS_MAF < 0.05
#   s for SAS_MAF < 0.05
#   b (default) for EAS_MAF < 0.05 OR SAS_MAF < 0.05

# read the options
TEMP=`getopt -o bes -n "$0" -- "$@"`
eval set -- "$TEMP"

FILTER=11
while true; do
    case "$1" in 
        -e) FILTER=10; shift;;
        -s) FILTER=01; shift;;
        -b) FILTER=11; shift;;
        --) shift; break;;
    esac
done

# set input file name
filename=$1

awk -v FILTER=$FILTER -F'\t' '
BGEIN {
    FS="\t";
    OFS="\t";
}

{
    EAS = $67;
    SAS = $68;
    TO_PRINT = 0;
    
    if ( $1~/^#/ ) TO_PRINT = 1;
    else if ( EAS < 0.05 && and(FILTER,10) ) TO_PRINT=1;
    else if ( SAS < 0.05 && and(FILTER,01) ) TO_PRINT=1;
  
    if ( TO_PRINT ) print;
}
' $filename 
