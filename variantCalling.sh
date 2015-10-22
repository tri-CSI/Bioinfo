#!/bin/bash
# set -o history -o histexpand

# Pipeline for variant calling and 2 Feroz's scripts
# Developed by Tran Minh Tri
# Date: 6 July 2015

if [ $# -ne 1 ] || [[ "$1" != *bam* ]]; then
  echo "Usage: $0 <bam_file>"
  exit
fi

# Tools
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GVCFTOOLS="/12TBLVM/biotools/gvcftools-0.16/bin/"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"

# Get input file name info
bname=`basename $1`
BASE_NAME=`expr match "$bname" '\([^b]*\)'`

LOG_FILE="${BASE_NAME}$(date +%s).triVarCal.log"

# File names 
# HH - human alignment

BAMFILE="$1" # important
VCF="${BASE_NAME}vcf"
VEP_ANNO="${BASE_NAME}VEP_anno.vcf"
CHOOSESTRAND="${BASE_NAME}choosestrand.txt"
ANNOTATED="${BASE_NAME}annotated.txt"

# Read groups
RG="@RG\tID:{0}\tLB:Nextera_Rapid_Capture_Enrichment\tPL:ILLUMINA-NextSeq500\tPU:@NS500768\tSM:${BASE_NAME}\tCN:CTRAD-CSI_Singapore\tDS:NIL\tDT:20150519"

# Functions
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
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE


# -------------------------------------------------------
# Variant calling on HH
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 20 -glm BOTH -R $HG19 -dcov 5000 -I $BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS | ${GVCFTOOLS}gatk_to_gvcf --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 > $VCF"
run "$command" $VCF

command="perl $VEP -i $VCF -o $VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command" $VEP_ANNO

command="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py $VEP_ANNO $CHOOSESTRAND"
run "$command" $CHOOSESTRAND

command="python3 /12TBLVM/Data/MinhTri/8_XENOGRAFT_2/VAS_Formatter_1.0.5.py $CHOOSESTRAND $ANNOTATED"
run "$command" $ANNOTATED

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
