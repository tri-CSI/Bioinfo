#!/bin/bash
# set -o history -o histexpand

# Pipeline for alignment following ILLUMINA-Basespace BWA Enrichment workflow
# version 0.1.2
# Developed by Tran Minh Tri
# Date: 11 Nov 2015

# History:
# v0.1.1: 05 Oct 2015

if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
BWA="/12TBLVM/biotools/bwa-0.7.7/bwa"
SAMTOOLS="samtools"
PICARD="java -jar /12TBLVM/biotools/picard-tools-1.101/picard-tools-1.101/"
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GATK_TO_GVCF="/12TBLVM/biotools/gvcftools-0.16/bin/gatk_to_gvcf"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"
VEP_STRANDSELECTOR="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py" 
VEP_FORMATTOR="python3 /12TBLVM/Data/MyScriptsOpen/VAS_Formatter_1.0.5.py"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"

# Get input file name info
STRAND_1=$1
STRAND_2=$2
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^_]*\)'`

#mkdir -p $BASE_NAME
#cd $BASE_NAME
#curdir=`pwd`

LOG_FILE="${BASE_NAME}.$(date +%s).trinome.log"

# File names 
HU_SORTED="${BASE_NAME}.sorted" 
HU_METRICS_FILE="${BASE_NAME}.metrics.picard"
HU_BAMFILE="${BASE_NAME}.bam" 
HU_UNALNED="${BASE_NAME}_unaligned.bam"
ALL_VARIANTS="${BASE_NAME}.all_variants.vcf"
QUAL_FILTERED="${BASE_NAME}.qual_filtered.vcf"
PASS_EXTRACTED="${BASE_NAME}.PASS_extracted.vcf"
VEP_ANNO="${BASE_NAME}.annotated.vcf"
VEP_CHOOSESTRAND="${BASE_NAME}.choosestrand.txt"
VEP_FORMATTED="${BASE_NAME}.formatted.txt"

# Read groups
DATE=`date +%Y%m%d`
RG="@RG\tID:{0}\tLB:Nextera_Rapid_Capture_Enrichment\tPL:ILLUMINA-NextSeq500\tPU:@NS500768\tSM:${BASE_NAME}\tCN:CTRAD-CSI_Singapore\tDS:NIL\tDT:$DATE"

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
	
	timenow=`date +"%Y-%m-%d %H:%M:%S"`
	echo "$timenow Process: $1" >> ${LOG_FILE}
	eval $1
	
	if [ $? -ne 0 ]; then
		echo " + Process fails with status $?" >> ${LOG_FILE}
		echo >> $LOG_FILE
		echo "Script exits on $(date)" >> ${LOG_FILE}
		exit
	fi
	
	time_elapsed=$[ `date +%s` - $last_time ]
	last_time=$(date +%s)
	echo " ++++++++ Process runtime: $(getTime $time_elapsed)" >> ${LOG_FILE}
}

function time_total {
	echo >> $LOG_FILE
	
	time_elapsed=$[ `date +%s` - $start_time ]
	echo "Total time elapsed : $(getTime $time_elapsed)" >> ${LOG_FILE}
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
# BWA alignment to human:
# -------------------------------------------------------
#run "$BWA mem -M -t25 -R '$RG' $HG19 $STRAND_1 $STRAND_2 | samtools view -@ 5 -Sb - > $HU_BAMFILE"
#
#run "$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
#
#run "${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE"
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
#	run "java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $HU_BAMFILE -o $target_int -L chr${chromo}"
#	
#	run "java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T IndelRealigner -R $HG19 -I $HU_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
#done
#	
#run "$SAMTOOLS cat ${BASE_NAME}_chr*_realigned.bam $HU_UNALNED -o $HU_BAMFILE && rm $HU_UNALNED ${BASE_NAME}_chr*"
#
#run "$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
#
#run "${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE && rm ${HU_SORTED}.bam $HU_METRICS_FILE"
#
#run "$SAMTOOLS index $HU_BAMFILE"

# ------------ QC --------------
#run "$SAMSTAT $HU_BAMFILE"
#
#mkdir qc
#mv ${HU_BAMFILE}.samstat.html qc

# -------------------------------------------------------
# Variant calling and annotation
# -------------------------------------------------------

#run "java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HU_BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $ALL_VARIANTS"
#
#run "$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $ALL_VARIANTS > $QUAL_FILTERED"
# 
#run "awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' $QUAL_FILTERED > $PASS_EXTRACTED"

run "perl $VEP -i $PASS_EXTRACTED -o $VEP_ANNO --cache --vcf --verbose --everything --fork 5 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"

run "$VEP_STRANDSELECTOR $VEP_ANNO $VEP_CHOOSESTRAND"

run "$VEP_FORMATTOR $VEP_CHOOSESTRAND $VEP_FORMATTED"

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
time_total
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
