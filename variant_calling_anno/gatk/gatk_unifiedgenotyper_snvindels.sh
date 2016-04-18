#!/bin/bash

# Pipeline for calling variants using GATK UnifiedGenotyper and Ensembl VEP annotation with EAS_MAF and SAS_MAF filter
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 22 Jan 2016

# Usage:
#     1. Copy xenograft.config file to run folder
#     2. Open xenograft.config, change paths to programs (BWA, samtools, GATK...)
#     3. Make sure fastq files have the following format: CASE_NAME-metainfo.fastq.gz or .fastq; CASE_NAME will be used to name output files.
#     4. Run pipeline by typing 
#           bash script_name.sh <forward_strand_fastq> <reverse_strand_fastq>
#     5. A subfolder to run directory will be made, named CASE_NAME

# Set constants
ncore=25
ram=50 
ANNOTATE=0 

# read the options
TEMP=`getopt -o at:m:c: -n "$0" -- "$@"`
eval set -- "$TEMP"

FILTER=11
while true; do
    case "$1" in
        -a) ANNOTATE=1; shift;;
        -t) 
            case "$2" in
                "") shift 2;;
                *) ncore=$2; shift 2;;
            esac ;;
        -m) 
            case "$2" in
                "") shift 2;;
                *) ram=$2; shift 2;;
            esac ;;
        -c) 
            case "$2" in
                "") shift 2;;
                *) config_file=$2; shift 2;;
            esac ;;
        --) shift; break;
    esac
done

# Load necessary tools and functions
source $config_file

# check input fastq names
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-options] <bamfile>"
  exit
fi

# Get input file name info

LOG_FILE="UnifiedGenotyper.$(date +%Y%m%d%H%M%S).log"
HU_BAMFILE=$1
ALL_VARIANTS="gatk_ug_variants.vcf"
QUAL_FILTERED="variants_qual.vcf"
PASS_EXTRACTED="variants_pass.vcf"
ANNOTATED_VAR="vep_annotated.txt"
ASN_ONLY="asn_filtered.txt"

start_log "UNIFIEDGENOTYPER" "Run GATK UnifiedGenotyper, VEP and ASN_MAF filtering" "$0" "$LOG_FILE"

# -------------------------------------------------------
# GATK UG:
# -------------------------------------------------------
java  -Djava.io.tmpdir="/tmp" -Xmx${ram}g -jar $GATK -T UnifiedGenotyper -nt $ncore -glm BOTH -R $HG_REF -dcov 5000 -I $HU_BAMFILE -o $ALL_VARIANTS --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 #-L $TARGET_REGIONS

$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $ALL_VARIANTS > $QUAL_FILTERED

awk 'BEGIN{FS="\t"; OFS=FS;} $1~/#/ || ($7~/PASS/) {print }' $QUAL_FILTERED > $PASS_EXTRACTED

if [ $ANNOTATE == 0 ]; then end_log "$LOG_FILE"; exit; fi

perl $VEP -i $PASS_EXTRACTED -o $ANNOTATED_VAR --cache --vcf --fork 25 --total_length --maf_1kg --buffer_size 100000 --force --pick --dir /12TBLVM/Data/VEP79cache --port 3337

$MAF_SELECTOR $ANNOTATED_VAR | $MAF_EXTRACTOR > $ASN_ONLY

end_log "$LOG_FILE"
