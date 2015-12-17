#!/bin/bash
set -o history -o histexpand

# Pipeline for analysing xenograft data starting at alignment 
# step up to variant calling, excluding annotation
# Developed by Tran Minh Tri
# Date: 22 Apr 2015

if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
BWA="/12TBLVM/biotools/bwa-0.7.12/bwa"
BAM2FASTQ="/12TBLVM/biotools/bam2fastq-1.1.0/bam2fastq"
SAMTOOLS_0p1="/12TBLVM/biotools/samtools/samtools"
SAMTOOLS_1p2="samtools"
PICARD_ADD_READ_GRP="java -jar /12TBLVM/biotools/picard-tools-1.101/picard-tools-1.101/AddOrReplaceReadGroups.jar"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
MM10="/12TBLVM/Data/MinhTri/mm10.fa"

# File names
STRAND_1="$1"
STRAND_2="$2"
BASE_NAME=`expr match "$STRAND_1" '\([^-]*\)'`

BAMFILE="1.mem_algmt.${BASE_NAME}.bam"

SORTED="2.sorted.${BASE_NAME}" 				# .bam added by samtools
RM_DUP="3.dup_removed.${BASE_NAME}.bam"
RG_ADDED="4.readgp_add.${BASE_NAME}.bam"
VCF_GATK="5.var_call.${BASE_NAME}.vcf"

LOG_FILE="${BASE_NAME}.tri-xenome.log"

start_time=$(date +%s)
last_time=$(date +%s)

begin()
{
echo >> ${LOG_FILE}
echo ">>> $1" >> ${LOG_FILE}
}

log ()
{
echo >> ${LOG_FILE}
echo "-+- PROCESS -+- : $1" >> ${LOG_FILE}

if [ $2 -eq 0 ]; then
	echo " + File created : $3" >> ${LOG_FILE}
else
	echo " + Process fails with status $2" >> ${LOG_FILE}
	echo >> $LOG_FILE
	echo "Script exits on $(date)" >> ${LOG_FILE}
	exit
fi

time_elapsed=$[ `date +%s` - $last_time ]
last_time=$(date +%s)
hours=$[ $time_elapsed / 3600 ]
minutes=$[ $[$time_elapsed % 3600] / 60]
seconds=$[ $[$time_elapsed % 3600] % 60]
echo " + Proc runtime : $hours hrs $minutes mins $seconds secs" >> ${LOG_FILE}

time_elapsed=$[ `date +%s` - $start_time ]
hours=$[ $time_elapsed / 3600 ]
minutes=$[ $[$time_elapsed % 3600] / 60]
seconds=$[ $[$time_elapsed % 3600] % 60]
echo " + Time elapsed : $hours hrs $minutes mins $seconds secs" >> ${LOG_FILE}
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
# BWA alignment to human:
# -------------------------------------------------------
begin "Alignment to human genome"
$BWA mem -M -v -t10 $HG19 $STRAND_1 $STRAND_2 | samtools view -Sb - > $BAMFILE
log "!!" $? $BAMFILE

# -------------------------------------------------------
# Variant calling on HH_BAMFILE
# -------------------------------------------------------
begin "Sort bamfile"
$SAMTOOLS_1p2 sort $BAMFILE $SORTED
log "!!" $? ${SORTED}.bam

begin "Remove duplicates"
$SAMTOOLS_0p1 rmdup ${SORTED}.bam $RM_DUP
log "!!" $? $RM_DUP

begin "Add read groups"
$PICARD_ADD_READ_GRP I=$RM_DUP O=$RG_ADDED RGID=Xenograft_trial LB=Nextera_Rapid_Capture_Enrichment PL=ILLUMINA-NextSeq50 PU=@NS500768 SM=${BASE_NAME}.xenome CN=CTRAD-CSI_Singapore DT=20150415 
log "!!" $? $RG_ADDED

begin "Index bamfile"
$SAMTOOLS_1p2 index $RG_ADDED
log "!!" $? "A bunch of Samtools index files"

begin "Variant calling with UnifiedGenotyper"
java -jar /12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar -T UnifiedGenotyper --min_base_quality_score 20 -R $HG19 -I $RG_ADDED -o $VCF_GATK --output_mode EMIT_VARIANTS_ONLY -log ${BASE_NAME}.xenome.log
log "!!" $? "$VCF_GATK and ${BASE_NAME}.xenome.log"

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
