#!/bin/bash
# set -o history -o histexpand

# Pipeline following ILLUMINA-Basespace alignment
# Developed by Tran Minh Tri
# Date: 19 May 2015

if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
BWA="/12TBLVM/biotools/bwa-0.7.7/bwa"
BAM2FASTQ="/12TBLVM/biotools/bam2fastq-1.1.0/bam2fastq"
SAMTOOLS_0p1="/12TBLVM/biotools/samtools/samtools"
SAMTOOLS_1p2="samtools"
PICARD="java -jar /12TBLVM/biotools/picard-tools-1.101/picard-tools-1.101/"
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GVCFTOOLS="/12TBLVM/biotools/gvcftools-0.16/bin/"
VEP="/12TBLVM/biotools/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
MM10="/12TBLVM/Data/MinhTri/mm10.fa"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"

# File names
STRAND_1="$1"
STRAND_2="$2"
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^-]*\)'`

ALIGNED="${BASE_NAME}.aligned.bam"
SORTED="${BASE_NAME}.sorted" 
METRICS_FILE="${BASE_NAME}.metrics.picard"
BAMFILE="${BASE_NAME}.bam"
UNALNED="${BASE_NAME}_unaligned.bam"
VCF="${BASE_NAME}.vcf"
PASS_EXTRACTED="${BASE_NAME}.PASS_extracted.vcf"
VEP_ANNO="${BASE_NAME}.VEP_anno.vcf"
CHOOSESTRAND="${BASE_NAME}.choosestrand.vcf"
ANNOTATED="${BASE_NAME}.annotated.vcf"

RG="@RG\tID:{0}\tLB:Nextera_Rapid_Capture_Enrichment\tPL:ILLUMINA-NextSeq500\tPU:@NS500768\tSM:${BASE_NAME}\tCN:CTRAD-CSI_Singapore\tDS:NIL\tDT:20150519"

start_time=$(date +%s)
last_time=$(date +%s)
LOG_FILE="${BASE_NAME}.${last_time}.trinome.log"

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
# BWA alignment to human:
# -------------------------------------------------------
command="$BWA mem -M -v -t12 -R \"$RG\" $HG19 $STRAND_1 $STRAND_2 | samtools view -Sb - > $ALIGNED"
run "$command" $ALIGNED

command="$SAMTOOLS_0p1 sort -@ 8 $ALIGNED $SORTED"
run "$command" ${SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${SORTED}.bam O=$BAMFILE METRICS_FILE=$METRICS_FILE"
run "$command" $BAMFILE

command="$SAMTOOLS_0p1 index $BAMFILE"
run "$command" "A bunch of Samtools index files"

command="$SAMTOOLS_0p1 view -bf 4 $BAMFILE > $UNALNED"
run "$command" $UNALNED

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${BASE_NAME}_chr${chromo}.intervals"
	realn_file="${BASE_NAME}_chr${chromo}_realigned.bam"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx8g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $BAMFILE -o $target_int -L chr${chromo}"
	run "$command" $target_int
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx8g -jar $GATK -T IndelRealigner -R $HG19 -I $BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
	run "$command" $realn_file
done
	
command="$SAMTOOLS_0p1  cat -o $BAMFILE ${BASE_NAME}_chr*_realigned.bam $UNALNED"
run "$command" $BAMFILE

# command="$SAMTOOLS_0p1 sort -@ 8 $ALIGNED $SORTED"
command="$SAMTOOLS_0p1 sort -@ 8 $BAMFILE $SORTED"
run "$command" ${SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${SORTED}.bam O=$BAMFILE METRICS_FILE=$METRICS_FILE"
run "$command" $BAMFILE

command="$SAMTOOLS_0p1 index $BAMFILE"
run "$command" "A bunch of Samtools index files"

command="java -Xmx2g -jar $GATK -T UnifiedGenotyper -glm BOTH -R $HG19 -dcov 5000 -I $BAMFILE --output_mode EMIT_ALL_SITES -l OFF -stand_call_conf 1 -L $TARGET_REGIONS | ${GVCFTOOLS}gatk_to_gvcf --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 > $VCF"
run "$command" $VCF

command="awk '{if ((\$1~/#/) || ((\$7~/PASS/))) print }' $VCF > $PASS_EXTRACTED"
run "$command" $PASS_EXTRACTED

command="perl $VEP -i $PASS_EXTRACTED -o $VEP_ANNO --cache --vcf --verbose --everything --fork 30 --total_length --maf_1kg --check_existing --allele_number --check_svs --buffer_size 100000 --dir /12TBLVM/Data/VEP75cache"
run "$command" $VEP_ANNO

command="python3 /12TBLVM/Data/MyScriptsOpen/choose_strand_vcf08.py $VEP_ANNO $CHOOSESTRAND"
run "$command" $CHOOSESTRAND

command="python3 /12TBLVM/Data/MyScriptsOpen/divideExistingVarsIntoColumns03.py $CHOOSESTRAND $ANNOTATED"
run "$command" $ANNOTATED

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
