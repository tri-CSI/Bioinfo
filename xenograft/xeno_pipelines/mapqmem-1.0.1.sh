#!/bin/bash

# Pipeline for xenograft analysis
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 26 December 2015

# Usage:
#     1. Copy xenograft.config file to run folder
#     2. Open xenograft.config, change paths to programs (BWA, samtools, GATK...)
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
STRAND_1=$1
STRAND_2=$2
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^_]*\)'`

LOG_FILE="${BASE_NAME}.$(date +%Y%m%d%H%M%S).trinome.log"

# Load necessary tools and functions
source mapqmem.config

# -------------------------------------------------------
# HEADER of LOG_FILE
# -------------------------------------------------------
echo "******************XENOGRAFT PIPELINE********************" > $LOG_FILE
echo "Start dtime : `date`" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# BWA alignment to human:
# -------------------------------------------------------
#run "$BWA mem -Mt25 -R '$RG' $HG_REF $STRAND_1 $STRAND_2 | samtools view -@ 25 -Sb - > $HU_BAMFILE"
#
#run "$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
#
#run "java -Xmx50g -jar $PICARD MarkDuplicates I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE"
#
#run "$SAMTOOLS index $HU_BAMFILE"
#
#run "$SAMTOOLS view -bf 4 $HU_BAMFILE > $HU_UNALNED"
#
#for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
#do
#	target_int="${BASE_NAME}_chr${chromo}.intervals"
#	realn_file="${BASE_NAME}_chr${chromo}_realigned.bam"
#	
#	run "java  -Djava.io.tmpdir=\"/tmp\" -Xmx50g -jar $GATK -T RealignerTargetCreator -R $HG_REF -I $HU_BAMFILE -o $target_int -L chr${chromo}"
#		
#	run "java  -Djava.io.tmpdir=\"/tmp\" -Xmx50g -jar $GATK -T IndelRealigner -R $HG_REF -I $HU_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
#	done
#	
#run "$SAMTOOLS cat ${BASE_NAME}_chr*_realigned.bam $HU_UNALNED -o $HU_BAMFILE && rm $HU_UNALNED ${BASE_NAME}_chr*"
#
#run "$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
#
#run "java -Xmx50g -jar $PICARD MarkDuplicates I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE && rm ${HU_SORTED}.bam $HU_METRICS_FILE"
#
#run "$SAMTOOLS index $HU_BAMFILE"
#
## ------------ QC --------------
#run "$SAMSTAT $HU_BAMFILE"
#
#mkdir qc
#mv ${HU_BAMFILE}.samstat.html qc

# -------------------------------------------------------
# BWA alignment to mouse:
# -------------------------------------------------------
run "$SAMTOOLS sort -@25 -nT tmp $HU_BAMFILE -o $HU_NAMESORTED"

run "$BWA mem -Mt25 -R '$RG' $MSE_REF $STRAND_1 $STRAND_2 | samtools view -@ 25 -Sb - > $MSE_BAMFILE"

run "$SAMTOOLS sort -@25 -nT tmp $MSE_BAMFILE -o $MSE_NAMESORTED && rm $MSE_BAMFILE"

run "$SAMTOOLS view -H $HU_BAMFILE > $SUBSTRACTED_SAM"

run "$IDENTIFYMOUSE <($SAMTOOLS view $HU_NAMESORTED) <($SAMTOOLS view $MSE_NAMESORTED) >> $SUBSTRACTED_SAM"

run "$SAMTOOLS sort -@25 -T tmp $SUBSTRACTED_SAM -o $SUB_SORTED && rm $SUBSTRACTED_SAM"

run "$SAMTOOLS index $SUB_SORTED"

# -------------------------------------------------------
# Variant calling and annotation
# -------------------------------------------------------

run "java -Xmx50g -jar $GATK -T UnifiedGenotyper -nt 15 -glm BOTH -R $HG_REF -dcov 5000 -I $SUB_SORTED --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $SS_ALL_VARIANTS"

run "$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $SS_ALL_VARIANTS > $SS_QUAL_FILTERED"
 
run "awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' $SS_QUAL_FILTERED > $SS_PASS_EXTRACTED"

run "perl $VEP -i $SS_PASS_EXTRACTED -o $SS_VEP_ANNO --cache --vcf --verbose --everything --fork 25 --total_length --maf_1kg --check_existing --force_overwrite --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"

run "$VEP_STRANDSELECTOR $SS_VEP_ANNO $SS_VEP_CHOOSESTRAND"

run "$VEP_FORMATTOR $SS_VEP_CHOOSESTRAND $SS_VEP_FORMATTED"

run "$VARLIST $VEP_FORMATTED $SS_VEP_FORMATTED"

run "mv uniqueA.txt $MSE_POSSIBLE"

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
time_total
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
