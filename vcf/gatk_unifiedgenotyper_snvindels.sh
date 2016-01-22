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

# read the options
TEMP=`getopt -o t:m: -n "$0" -- "$@"`
eval set -- "$TEMP"

FILTER=11
while true; do
    case "$1" in
        -t) 
            case "$2" in
                "") shift 2;;
                *) ncore=$2; shift 2;;
            esac ;;
        -m) 
            case "$2" in
                "") shift 2;;
                *) ncore=$2; shift 2;;
            esac ;;
        --) shift; break;
    esac
done

# Load necessary tools and functions
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GATK_TO_GVCF="/12TBLVM/biotools/gvcftools-0.16/bin/gatk_to_gvcf"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"
MAF_SELECTOR="/12TBLVM/Data/MinhTri/6_SCRIPTS/vcf/select_asn_maf.awk"
MAF_EXTRACTOR="/12TBLVM/Data/MinhTri/6_SCRIPTS/vcf/mafextract.sh"

# check input fastq names
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-options] <bamfile>"
  exit
fi

# Get input file name info

HG_REF="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"
LOG_FILE="UnifiedGenotyper.$(date +%Y%m%d%H%M%S).log"
HU_BAMFILE=$1
ALL_VARIANTS="haplotype_variants.vcf"
QUAL_FILTERED="variants_qual.vcf"
PASS_EXTRACTED="variants_pass.vcf"
ANNOTATED_VAR="vep_annotated.txt"
ASN_ONLY="asn_filtered.txt"

# -------------------------------------------------------
# HEADER of LOG_FILE
# -------------------------------------------------------
echo "******************* UNIFIEDGENOTYPER ********************" > $LOG_FILE
echo "Description : Run GATK UnifiedGenotyper, VEP and ASN_MAF filtering" >> $LOG_FILE
echo "Start dtime : `date`" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# BWA alignment to human:
# -------------------------------------------------------
java  -Djava.io.tmpdir="/tmp" -Xmx${ram}g -jar $GATK -T UnifiedGenotyper -nt $ncore -glm BOTH -R $HG_REF -dcov 5000 -I $HU_BAMFILE -o $ALL_VARIANTS --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS

$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $ALL_VARIANTS > $QUAL_FILTERED

awk 'BEGIN{FS="\t"; OFS=FS} $1~/#/ || ($7~/PASS/ && $3=NR-64) {print }' $QUAL_FILTERED > $PASS_EXTRACTED

perl $VEP -i $PASS_EXTRACTED -o $ANNOTATED_VAR --cache --vcf --fork 25 --total_length --maf_1kg --buffer_size 100000 --force --pick --dir /12TBLVM/Data/VEP79cache --port 3337

$MAF_SELECTOR $ANNOTATED_VAR | $MAF_EXTRACTOR > $ASN_ONLY

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
