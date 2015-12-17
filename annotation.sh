#!/bin/bash
# set -o history -o histexpand

# Pipeline to annotate VCF files
# Developed by Tran Minh Tri
# Date: 26 May 2015

if [ $# < 1 ] || [[ "$@" != *vcf* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
VEP="/12TBLVM/biotools/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl"

LOG_FILE="$(date +%s).anno.log"
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
PASS_EXTRACTED="${BASE_NAME}.PASS_extracted.vcf"
VEP_ANNO="${BASE_NAME}.VEP_anno.vcf"
CHOOSESTRAND="${BASE_NAME}.choosestrand.vcf"
ANNOTATED="${BASE_NAME}.annotated.vcf"

command="awk '{if ((\$1~/#/) || ((\$7~/PASS/))) print }' $VCF > $PASS_EXTRACTED"
run "$command" "$PASS_EXTRACTED"

command="perl $VEP -i $PASS_EXTRACTED -o $VEP_ANNO --cache --vcf --verbose --everything --fork 30 --total_length --maf_1kg --check_existing --allele_number --check_svs --buffer_size 100000 --dir /12TBLVM/Data/VEP75cache"
run "$command" "$VEP_ANNO"

command="python3 /12TBLVM/Data/MyScriptsOpen/choose_strand_vcf08.py $VEP_ANNO $CHOOSESTRAND"
run "$command" "$CHOOSESTRAND"

command="python3 /12TBLVM/Data/MyScriptsOpen/divideExistingVarsIntoColumns03.py $CHOOSESTRAND $ANNOTATED"
run "$command" "$ANNOTATED"

done
# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE