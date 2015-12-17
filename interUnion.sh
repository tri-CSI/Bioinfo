#!/bin/bash
# set -o history -o histexpand

"""
Pipeline to: 
	1. Count intersection and union of HH, HO files
	2. Output Venn diagram info
	3. Create union files
Tools:
	1. python script varList2
Requirements:
	1. Both HH and HO files in directory
	
Developed by Tran Minh Tri
Date: 23 July 2015
"""

if [ $# < 1 ] || [[ "$@" != HH*.txt ]]; then
  echo "Usage: $0 <HH filenames>"
  exit
fi

echo $@
# Tools
LOG_FILE="$(date +%s).interUnion.log"
RESULT="result.interUnion.log"

start_time=$(date +%s)
last_time=$(date +%s)

function getTime () {
hours=$[ $1 / 3600 ]
minutes=$[ $[$1 % 3600] / 60]
seconds=$[ $[$1 % 3600] % 60]
echo "${hours}:${minutes}:${seconds}"
}

function run () {
echo >> ${LOG_FILE}
echo "-+- PROCESS -+- : $1" >> ${LOG_FILE}
echo " + Proc start on $(date)" >> ${LOG_FILE}
eval $1
if [ $? -eq 0 ]; then
	echo " + Proc completed successfully" >> ${LOG_FILE}
else
	echo " + Process fails with status $?" >> ${LOG_FILE}
	echo >> $LOG_FILE
	echo "Script exits on $(date)" >> ${LOG_FILE}
	exit
fi

time_elapsed=$[ `date +%s` - $last_time ]
last_time=$(date +%s)
echo " + Proc runtime : $(getTime $time_elapsed)" >> ${LOG_FILE}

time_elapsed=$[ `date +%s` - $start_time ]
echo " + Time elapsed : $(getTime $time_elapsed)" >> ${LOG_FILE}
}

# -------------------------------------------------------
# HEADER
# -------------------------------------------------------
echo "*********************************************************" > $LOG_FILE
echo "*** Starting pipeline on `date` ***" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# 
# -------------------------------------------------------
echo "Result for analysis run on `date`:" > $RESULT

for file in "$@"
do
# File names
HH="$file"
HO="${file/HH/HO}"
BASE_NAME=`expr match "$file" '\([^.]*\)'`

echo >> $RESULT
echo ${file/HH_/>>> CASE: } >> $RESULT

command="python3 /12TBLVM/Data/MinhTri/6_SCRIPTS/varList2.py --fileA $HH --fileB $HO >> $RESULT"
run "$command"

done
# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
