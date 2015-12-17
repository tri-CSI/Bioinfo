#!/bin/bash
# set -o history -o histexpand

"""
Pipeline to: 
	1. Filter ASN_MAF info from annotated files
	2. Count number of variants in original files and filtered files
Tools:
	1. awk extract reads where ASN_MAF < 0.05 (column 49)
	
Developed by Tran Minh Tri
Date: 22 July 2015
Changed: 6 Aug 2015: regex
"""

if [ $# < 1 ] || [[ "$@" != *.txt ]]; then
  echo "Usage: $0 <filenames>"
  exit
fi

echo $@
# Tools
LOG_FILE="$(date +%s).asn_maf.log"
RESULT="result.asn_maf.log"

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
echo "Result for analysis run on `date`:" > $RESULT

for file in "$@"
do
# File names
VCF="$file"
BASE_NAME=`expr match "$file" '\(.*[1-9][^.]*\)'`
EXTRACTED="${BASE_NAME}.asn_maf.txt"

echo >> $RESULT
echo $file >> $RESULT

command="awk -F $'\t' '{ nE = split(\$48,EAS,\"&\"); nS = split(\$50,SAS,\"&\"); for (i=1;i<=nE;i++) { split(EAS[i],var,\":\"); if (var[1] == \$5) eas=var[2] } ; for (i=1;i<=nS;i++) { split(SAS[i],var,\":\"); if (var[1] == \$5) sas=var[2] } ; if ((\$1~/#/) || ((eas < 0.05) && (sas < 0.05))) print }' $VCF > $EXTRACTED"
run "$command" "$EXTRACTED"

echo -n "Total variants: " >> $RESULT
egrep -cv '#|^$' $VCF >> $RESULT
echo -n "ASN_MAF < 0.05: " >> $RESULT
egrep -cv '#|^$' $EXTRACTED >> $RESULT

done
# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
