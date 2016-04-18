#!/bin/bash
# set -o history -o histexpand

# Pipeline to extrct amino acid info from VCF files
# Developed by Tran Minh Tri
# Date: 27 May 2015

if [ $# < 1 ] || [[ "$@" != *vcf ]]; then
  echo "Usage: $0"
  exit
fi

echo $@
# Tools
VEP="/12TBLVM/biotools/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl"

LOG_FILE="$(date +%s).aaa.log"
RG="@RG\tID:{0}\tLB:Nextera_Rapid_Capture_Enrichment\tPL:ILLUMINA-NextSeq500\tPU:@NS500768\tSM:${BASE_NAME}\tCN:CTRAD-CSI_Singapore\tDS:NIL\tDT:20150519"

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
EXTRACTED="${BASE_NAME}.aaa.txt"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^TP53$/ { print \$1,\$2,\$36,\$52 }' $VCF > $EXTRACTED"
run "$command" "$EXTRACTED"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^KRAS$/ { print \$1,\$2,\$36,\$52 }' $VCF >> $EXTRACTED"
run "$command" "$EXTRACTED"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^ARID1A$/ { print \$1,\$2,\$36,\$52 }' $VCF >> $EXTRACTED"
run "$command" "$EXTRACTED"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^FAT4$/ { print \$1,\$2,\$36,\$52 }' $VCF >> $EXTRACTED"
run "$command" "$EXTRACTED"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^CDH1$/ { print \$1,\$2,\$36,\$52 }' $VCF >> $EXTRACTED"
run "$command" "$EXTRACTED"

command="awk -F $'\t' '\$37 ~ /HGNC/ && \$36 ~ /^PIK3A$/ { print \$1,\$2,\$36,\$52 }' $VCF >> $EXTRACTED"
run "$command" "$EXTRACTED"

echo `wc -l $EXTRACTED`

done
# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE