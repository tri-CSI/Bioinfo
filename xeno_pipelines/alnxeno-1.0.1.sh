#!/bin/bash

# Pipeline for xenograft analysis using BWA aln
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 22 October 2015

# Usage:
#     1. Copy alnxeno.config file to run folder
#     2. Open alnxeno.config, change paths to programs (BWA, samtools, GATK...)
#     3. Make sure fastq files have the following format: CASE_NAME-metainfo.fastq.gz or .fastq; CASE_NAME will be used to name output files.
#     4. Run pipeline by typing 
#           bash script_name.sh <forward_strand_fastq> <reverse_strand_fastq>
#     5. A subfolder to run directory will be made, named CASE_NAME

# checking input fastq names
if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Get input file name info
STRAND_1=`readlink $1`
STRAND_2=`readlink $2`
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^-_]*\)'`

mkdir -p ${BASE_NAME}_ALN
cd ${BASE_NAME}_ALN
curdir=`pwd`

LOG_FILE="${BASE_NAME}.$(date +%Y%m%d%H%M%S).alnxeno.log"

# Load necessary tools and functions
source xenograft.config

# -------------------------------------------------------
# HEADER of LOG_FILE
# -------------------------------------------------------
echo "******************* ALNXENO PIPELINE ********************" > $LOG_FILE
echo "Start dtime : `date`" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# First alignment to human
# -------------------------------------------------------
run "$BWA mem -l22 -k0 -t25 -R '$RG' $HG_REF $STRAND_1 > $ALN_HU_1"

run "$BWA mem -l22 -k0 -t25 -R '$RG' $HG_REF $STRAND_2 > $ALN_HU_2"

run "$BWA sampe $HG19 $ALN_HU_1 $ALN_HU_2 $STRAND_1 $STRAND_2 | $SAMTOOLS view -bS -F 0x4 - > $HH_BAMFILE"

# -------------------------------------------------------
# Alignment to mouse
# -------------------------------------------------------
run "$BAM2FASTQ $HH_BAMFILE -o $HH_FASTQ"

run "$BWA mem -l22 -k0 -t25 -R '$RG' $MG_REF $HH_FASTQ_1 > $ALN_MSE_1"

run "$BWA mem -l22 -k0 -t25 -R '$RG' $MG_REF $HH_FASTQ_2 > $ALN_MSE_2"

run "$BWA sampe $MG_REF $ALN_MSE_1 $ALN_MSE_2 $HH_FASTQ_1 $HH_FASTQ_2 | $SAMTOOLS view -bS -f 0x4 - > $MSE_BAMFILE"

# -------------------------------------------------------
# Second alignment to human
# -------------------------------------------------------
run "$BAM2FASTQ $MSE_BAMFILE -o $HO_FASTQ"

run "$BWA mem -l22 -k0 -t25 -R '$RG' $HG_REF $HO_FASTQ_1 > $ALN_HO_1"

run "$BWA mem -l22 -k0 -t25 -R '$RG' $HG_REF $HO_FASTQ_2 > $ALN_HO_2"

run "$BWA sampe $HG19 $ALN_HO_1 $ALN_HO_2 $HO_FASTQ_1 $HO_FASTQ_2 | $SAMTOOLS view -bS -F 0x4 - > $HO_BAMFILE"

# -------------------------------------------------------
# Preparation for variant calling
# -------------------------------------------------------

run "$SAMTOOLS sort -@ 25 $HH_BAMFILE $HH_SORTED"

run "${PICARD}MarkDuplicates.jar I=${HH_SORTED}.bam O=$HH_BAMFILE METRICS_FILE=$HH_METRICS_FILE && rm ${HH_SORTED}.bam $HH_METRICS_FILE"

run "$SAMTOOLS index $HH_BAMFILE"

run "$SAMTOOLS sort -@ 25 $HO_BAMFILE $HO_SORTED"

run "${PICARD}MarkDuplicates.jar I=${HO_SORTED}.bam O=$HO_BAMFILE METRICS_FILE=$HO_METRICS_FILE && rm ${HO_SORTED}.bam $HO_METRICS_FILE"

run "$SAMTOOLS index $HO_BAMFILE"

# ------------ QC --------------
mkdir qc

run "$FASTQC $STRAND_1 $STRAND_2 -o qc"

run "$SAMSTAT $HH_BAMFILE" && mv ${HH_BAMFILE}.samstat.html qc
run "$SAMSTAT $MSE_BAMFILE" && mv ${MSE_BAMFILE}.samstat.html qc
run "$SAMSTAT $HO_BAMFILE" && mv ${HO_BAMFILE}.samstat.html qc

# -------------------------------------------------------
# Variant calling and annotation
# -------------------------------------------------------

run "java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG_REF -dcov 5000 -I $HH_BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $HH_ALL_VARIANTS"

run "$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $HH_ALL_VARIANTS | awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' > $HH_PASS_EXTRACTED"

run "perl $VEP -i $HH_PASS_EXTRACTED -o $HH_VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache && rm $HH_PASS_EXTRACTED"

run "$VEP_STRANDSELECTOR $HH_VEP_ANNO $HH_VEP_CHOOSESTRAND && rm $HH_VEP_ANNO"
run "$VEP_FORMATTOR $HH_VEP_CHOOSESTRAND $HH_VEP_FORMATTED && rm $HH_VEP_CHOOSESTRAND"
run "awk -F $'\t' '\$1~/#/ || \$67 < 0.05 {print }' $HH_VEP_CHOOSESTRAND > $HH_ASNMAF"

# ------- HO ---------
run "java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG_REF -dcov 5000 -I $HO_BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $HO_ALL_VARIANTS"

run "$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $HO_ALL_VARIANTS | awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' > $HO_PASS_EXTRACTED"

run "perl $VEP -i $HO_PASS_EXTRACTED -o $HO_VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache && rm $HO_PASS_EXTRACTED"

run "$VEP_STRANDSELECTOR $HO_VEP_ANNO $HO_VEP_CHOOSESTRAND && rm $HO_VEP_ANNO"
run "$VEP_FORMATTOR $HO_VEP_CHOOSESTRAND $HO_VEP_FORMATTED && rm $HO_VEP_CHOOSESTRAND"
run "awk -F $'\t' '\$1~/#/ || \$67 < 0.05 {print }' $HO_VEP_CHOOSESTRAND > $HO_ASNMAF"


# -------------------------------------------------------
# Variant calling report 
# -------------------------------------------------------

echo -e "Variant count report \t$BASE_NAME" > $VAR_REPORT

echo >> $VAR_REPORT
echo Unfiltered variants >> $VAR_REPORT
echo >> $VAR_REPORT
$COUNT_INTERSECTION --fileA $HH_VEP_CHOOSESTRAND --fileB $HO_VEP_CHOOSESTRAND >> $VAR_REPORT 

echo >> $VAR_REPORT
echo EAS_MAF \< 0.05 >> $VAR_REPORT
echo >> $VAR_REPORT
$COUNT_INTERSECTION --fileA $HH_ASNMAF --fileB $HO_ASNMAF >> $VAR_REPORT 

# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
cd ..
