#!/bin/bash
# set -o history -o histexpand

# Pipeline for extracting variants from vcf files.
# Developed by Tran Minh Tri
# Date: 28 May 2015

if [ $# < 1 ] || [[ "$@" != *vcf ]]; then
  echo "Usage: $0"
  exit
fi

echo Files: $@
LOG_FILE="$(date +%s).varEX.log"
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
	echo " + File created : $2" >> ${LOG_FILE}
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
# Extract PASS reads and annotate VCF file
# -------------------------------------------------------

for file in "$@"
do
# File names
VCF="$file"
BASE_NAME=`expr match "$file" '\([^.]*\)'`
EXTRACTED="${BASE_NAME}_np.VAR_extracted.txt"

command="awk -F $'\t' '\$1 !~ /#/ { print \$1,\$2,\$5 }' $VCF > $EXTRACTED"
run "$command" "$EXTRACTED"

echo `wc -l $EXTRACTED` >> ${LOG_FILE}

done
# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE