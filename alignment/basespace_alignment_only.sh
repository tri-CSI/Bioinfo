#!/bin/bash

# Pipeline for WGS/WES alignment with Basespace workflow
# 	up to alignment (bamfiles) only
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 01 Jan 2016

# Usage:
#     1. Copy xenograft.config file to run folder
#     2. Open xenograft.config, change paths to programs (BWA, samtools, GATK...)
#     3. Make sure fastq files have the following format: CASE_NAME-metainfo.fastq.gz or .fastq; CASE_NAME will be used to name output files.
#     4. Run pipeline by typing 
#           bash script_name.sh <forward_strand_fastq> <reverse_strand_fastq>
#     5. A subfolder to run directory will be made, named CASE_NAME

# Set constants
ncore=60
ram=10

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


# check input fastq names
if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 [-options] <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Get input file name info
STRAND_1=`readlink -f $1`
STRAND_2=`readlink -f $2`
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^_]*\)'`

LOG_FILE="${BASE_NAME}.$(date +%Y%m%d%H%M%S).bs-align-2bam.log"

# Load necessary tools and functions
source /home/biotools/tri-scripts/basespace_alignment_only.config

mkdir -p $BASE_NAME
cd $BASE_NAME
curdir=`pwd`

# -------------------------------------------------------
# HEADER of LOG_FILE
# -------------------------------------------------------
echo "******************BASESPACE ALIGNMENT********************" > $LOG_FILE
echo "Description : Align paired reads up to bamfile using BS pipeline" >> $LOG_FILE
echo "Start dtime : `date`" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# BWA alignment to human:
# -------------------------------------------------------
run "$BWA mem -Mt$ncore -R '$RG' $HG_REF $STRAND_1 $STRAND_2 | samtools view -@$ncore -Sb - > $HU_BAMFILE"

run "$SAMTOOLS sort -@$ncore -T tmp $HU_BAMFILE -o $HU_SORTED"

run "java -Xmx${ram}g -jar $PICARD MarkDuplicates I=$HU_SORTED O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE"

run "$SAMTOOLS index $HU_BAMFILE"

run "$SAMTOOLS view -bf 4 $HU_BAMFILE > $HU_UNALNED"

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${BASE_NAME}_chr${chromo}.intervals"
	realn_file="${BASE_NAME}_chr${chromo}_realigned.bam"
	
	java -Djava.io.tmpdir="/tmp" -Xmx${ram}g -jar $GATK -T RealignerTargetCreator -R $HG_REF -I $HU_BAMFILE -o $target_int -L chr${chromo} && java  -Djava.io.tmpdir="/tmp" -Xmx${ram}g -jar $GATK -T IndelRealigner -R $HG_REF -I $HU_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file &
done

wait
	
run "$SAMTOOLS cat ${BASE_NAME}_chr*_realigned.bam $HU_UNALNED -o $HU_BAMFILE && rm $HU_UNALNED ${BASE_NAME}_chr*"

run "$SAMTOOLS sort -@$ncore -T tmp $HU_BAMFILE -o $HU_SORTED"

run "java -Xmx${ram}g -jar $PICARD MarkDuplicates I=$HU_SORTED O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE && rm $HU_SORTED $HU_METRICS_FILE"

run "$SAMTOOLS index $HU_BAMFILE"

run "$SAMSTAT $HU_BAMFILE" # qc for bamfile

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
time_total
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
