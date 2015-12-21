#!/bin/bash
# set -o history -o histexpand

# Pipeline for xenograft following ILLUMINA-Basespace alignment
# Developed by Tran Minh Tri
# Date: 30 June 2015

if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
BWA="/12TBLVM/biotools/bwa-0.7.7/bwa"
BAM2FASTQ="/12TBLVM/biotools/bam2fastq-1.1.0/bam2fastq"
SAMTOOLS_0p1="/12TBLVM/biotools/samtools/samtools"
SAMTOOLS="samtools"
PICARD="java -jar /12TBLVM/biotools/picard-tools-1.101/picard-tools-1.101/"
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GVCFTOOLS="/12TBLVM/biotools/gvcftools-0.16/bin/"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
MGxx="/12TBLVM/Data/MinhTri/8_XENOGRAFT_2/BALB_cJ.chromosome.fa.gz"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"

# Get input file name info
STRAND_1="$1"
STRAND_2="$2"
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^-]*\)'`

mkdir -p ${BASE_NAME}_3rd
cd ${BASE_NAME}_3rd
curdir=`pwd`

LOG_FILE="${BASE_NAME}.$(date +%s).trinome.log"

# File names 
# HH - initial human alignment
# MSE - mouse genome unaligned
# HO - human genome re-alignment, after extraction

HH_NAME="HH_${BASE_NAME}"
HH_SORTED="${HH_NAME}.sorted" 
HH_METRICS_FILE="${HH_NAME}.metrics.picard"
HH_BAMFILE="${HH_NAME}.bam" # important
HH_UNALNED="${HH_NAME}_unaligned.bam"
HH_VCF="${HH_NAME}.vcf"
HH_PASS_EXTRACTED="${HH_NAME}.PASS_extracted.vcf"
HH_VEP_ANNO="${HH_NAME}.VEP_anno.vcf"
HH_CHOOSESTRAND="${HH_NAME}.choosestrand.txt"
HH_ANNOTATED="${HH_NAME}.annotated.txt"

HH_ALIGNED_FQ="${BASE_NAME}#.fastq"
HH_ALIGNED_FQ1="${BASE_NAME}_1.fastq"
HH_ALIGNED_FQ2="${BASE_NAME}_2.fastq"
MSE_BAMFILE="MSE_${BASE_NAME}.aligned.bam"
MSE_UNALNED="MSE_${BASE_NAME}.unaligned.bam"

MSE_UNALNED_FQ="MSE_${BASE_NAME}#.unaligned.fastq"
MSE_UNALNED_FQ1="MSE_${BASE_NAME}_1.unaligned.fastq"
MSE_UNALNED_FQ2="MSE_${BASE_NAME}_2.unaligned.fastq"

HO_NAME="HO_${BASE_NAME}"
HO_SORTED="${HO_NAME}.sorted" 
HO_METRICS_FILE="${HO_NAME}.metrics.picard"
HO_BAMFILE="${HO_NAME}.bam" # important
HO_UNALNED="${HO_NAME}_unaligned.bam"
HO_VCF="${HO_NAME}.vcf"
HO_PASS_EXTRACTED="${HO_NAME}.PASS_extracted.vcf"
HO_VEP_ANNO="${HO_NAME}.VEP_anno.vcf"
HO_CHOOSESTRAND="${HO_NAME}.choosestrand.txt"
HO_ANNOTATED="${HO_NAME}.annotated.txt"

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
# BWA alignment to human:
# -------------------------------------------------------
command="$BWA mem -M -v -t25 -R '$RG' $HG19 $STRAND_1 $STRAND_2 | samtools view -@ 25 -Sb - > $HH_BAMFILE"
run "$command" $HH_BAMFILE

command="$SAMTOOLS sort -@ 25 $HH_BAMFILE $HH_SORTED"
run "$command" ${HH_SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${HH_SORTED}.bam O=$HH_BAMFILE METRICS_FILE=$HH_METRICS_FILE"
run "$command" $HH_BAMFILE

command="$SAMTOOLS index $HH_BAMFILE"
run "$command" "A bunch of Samtools index files"

# -------------------------------------------------------
command="samtools view -@ 25 -SbF 4 $HH_BAMFILE | $BAM2FASTQ - -o $HH_ALIGNED_FQ -f"
run "$command" $HH_ALIGNED_FQ

command="$BWA mem -M -v -t25 -R '$RG' $MGxx $HH_ALIGNED_FQ1 $HH_ALIGNED_FQ2 | samtools view -@ 25 -Sb - > $MSE_BAMFILE"
run "$command" $MSE_BAMFILE

# -------------------------------------------------------
# Extract unaligned reads
# -------------------------------------------------------

command="samtools view -@ 25 -Sbf 4 $MSE_BAMFILE | $BAM2FASTQ - -o $MSE_UNALNED_FQ -f"
run "$command" $MSE_UNALNED_FQ

# -------------------------------------------------------
# BWA re-alignment to human:
# -------------------------------------------------------

command="$BWA mem -M -v -t25 -R '$RG' $HG19 $MSE_UNALNED_FQ1 $MSE_UNALNED_FQ2 | samtools view -@ 25 -Sb - > $HO_BAMFILE"
run "$command" $HO_BAMFILE

command="$SAMTOOLS sort -@ 25 $HO_BAMFILE $HO_SORTED"
run "$command" ${HO_SORTED}.bam

command="$SAMTOOLS_0p1 rmdup ${HO_SORTED}.bam $HO_BAMFILE && rm ${HO_SORTED}.bam"
run "$command" $HO_BAMFILE

command="$SAMTOOLS index $HO_BAMFILE"
run "$command" "A bunch of Samtools index files"

# -------------------------------------------------------
# Variant calling on HH
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HH_BAMFILE --output_mode EMIT_ALL_SITES -l OFF -stand_call_conf 1 -L $TARGET_REGIONS | ${GVCFTOOLS}gatk_to_gvcf --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 > $HH_VCF"
run "$command" $HH_VCF

command="awk '{if ((\$1~/#/) || ((\$7~/PASS/))) print }' $HH_VCF > $HH_PASS_EXTRACTED"
run "$command" $HH_PASS_EXTRACTED

# Need permission to write to /12TBLVM/Data/VEP79cache/../../...index
command="perl $VEP -i $HH_PASS_EXTRACTED -o $HH_VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command" $HH_VEP_ANNO 

command="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py $HH_VEP_ANNO $HH_CHOOSESTRAND"
run "$command" $HH_CHOOSESTRAND

command="python3 /12TBLVM/Data/MyScriptsOpen/VAS_Formatter_1.0.4.py $HH_CHOOSESTRAND $HH_ANNOTATED"
run "$command" $HH_ANNOTATED

# -------------------------------------------------------
# Variant calling on HO
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HO_BAMFILE --output_mode EMIT_ALL_SITES -l OFF -stand_call_conf 1 -L $TARGET_REGIONS | ${GVCFTOOLS}gatk_to_gvcf --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 > $HO_VCF"
run "$command" $HO_VCF

command="awk '{if ((\$1~/#/) || ((\$7~/PASS/))) print }' $HO_VCF > $HO_PASS_EXTRACTED"
run "$command" $HO_PASS_EXTRACTED

command="perl $VEP -i $HO_PASS_EXTRACTED -o $HO_VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command" $HO_VEP_ANNO

command="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py $HO_VEP_ANNO $HO_CHOOSESTRAND"
run "$command" $HO_CHOOSESTRAND

command="python3 VAS_Formatter_1.0.5.py $HO_CHOOSESTRAND $HO_ANNOTATED"
run "$command" $HO_ANNOTATED

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
