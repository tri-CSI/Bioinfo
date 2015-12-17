#!/bin/bash

# Pipeline for extracting variants from a gene and run annotation on it
# Developed by Tran Minh Tri
# Date: 20 May 2015

if [ $# < 1 ] || [[ "$@" != *vcf ]]; then
  echo "Usage: $0 <original_vcf_file\(s\)_in_vcf>"
  exit
fi

# Functions
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
TIME=$(date +%s)
LOG_FILE="${TIME}.extractor.log"

echo "*********************************************************" > $LOG_FILE
echo "*** Starting pipeline on `date` ***" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

for file in "$@"
do
# File names
ORIGINAL_VCF="$file"
BASE_NAME=`expr match "$ORIGINAL_VCF" '\([^-]*\)'`
EXTRACTED="1.${BASE_NAME}.extracted.vcf"
ANNOTATED="2.${BASE_NAME}.annotated.vcf"
CHOOSESTRAND="3.${BASE_NAME}.chs_stnd.txt"
FINAL="4.${BASE_NAME}.final.txt"

start_time=$(date +%s)
last_time=$(date +%s)


# Extract IDH2 chr15:90,627,212-90,645,708
command="awk '{if ((\$1~/#/) || (\$1==\"chr15\" && \$2>=90627212 && \$2 <=90645708)) print}' $ORIGINAL_VCF > $EXTRACTED"
run "$command" $EXTRACTED

# -------------------------------------------------------
# Annotate vcf file
# -------------------------------------------------------
command="perl /12TBLVM/biotools/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl -i $EXTRACTED -o $ANNOTATED --cache --vcf --verbose --everything --fork 30 --total_length --maf_1kg --check_existing --allele_number --check_svs --buffer_size 100000 --dir /12TBLVM/Data/VEP75cache"
run "$command" $ANNOTATED

command="python3 /12TBLVM/Data/MyScriptsOpen/choose_strand_vcf08.py $ANNOTATED $CHOOSESTRAND"
run "$command" $CHOOSESTRAND

command="python3 /12TBLVM/Data/MyScriptsOpen/divideExistingVarsIntoColumns03.py $CHOOSESTRAND $FINAL"
run "$command" $FINAL

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
done

echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE