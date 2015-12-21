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

mkdir -p $BASE_NAME
cd $BASE_NAME
curdir=`pwd`

LOG_FILE="${BASE_NAME}.$(date +%s).trinome.log"

# File names 
# HU - initial human alignment
# MSE - mouse genome unaligned
# HO - human genome re-alignment, after extraction

HU_NAME="HU_${BASE_NAME}"
HU_BAMFILE="${HU_NAME}.bam" # important
HU_SORTED="${HU_NAME}.sorted" 
HU_RMDUP="${HU_NAME}.rmdup.bam"
HU_METRICS_FILE="${HU_NAME}.metrics.picard"
HU_UNALNED="${HU_NAME}_unaligned.bam"
HU_VCF="${HU_NAME}.vcf"
HU_PASS_EXTRACTED="${HU_NAME}.PASS_extracted.vcf"
HU_VEP_ANNO="${HU_NAME}.VEP_anno.vcf"
HU_CHOOSESTRAND="${HU_NAME}.choosestrand.txt"
HU_ANNOTATED="${HU_NAME}.annotated.txt"

HU_ALIGNED_FQ="${BASE_NAME}#.hu_aligned.fastq"
HU_ALIGNED_FQ1="${BASE_NAME}_1.hu_aligned.fastq"
HU_ALIGNED_FQ2="${BASE_NAME}_2.hu_aligned.fastq"

MSE_NAME="MSE_${BASE_NAME}"
MSE_BAMFILE="${MSE_NAME}.bam"

MSE_ALNED_FQ="${MSE_NAME}#.mse_aligned.fastq"
MSE_ALNED_FQ1="${MSE_NAME}_1.mse_aligned.fastq"
MSE_ALNED_FQ2="${MSE_NAME}_2.mse_aligned.fastq"
MSE_UNALNED_FQ="${MSE_NAME}#.mse_unaligned.fastq"
MSE_UNALNED_FQ1="${MSE_NAME}_1.mse_unaligned.fastq"
MSE_UNALNED_FQ2="${MSE_NAME}_2.mse_unaligned.fastq"

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
command="$BWA mem -M -v -t25 -R '$RG' $HG19 $STRAND_1 $STRAND_2 | samtools view -@ 25 -Sb - > $HU_BAMFILE"
run "$command" $HU_BAMFILE

command="$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
run "$command" ${HU_SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_RMDUP METRICS_FILE=$HU_METRICS_FILE"
run "$command" $HU_RMDUP

command="$SAMTOOLS index $HU_RMDUP"
run "$command" "A bunch of Samtools index files"

command="$SAMTOOLS view -bf 4 $HU_RMDUP > $HU_UNALNED"
run "$command" $HU_UNALNED

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${HU_NAME}_chr${chromo}.intervals"
	realn_file="${HU_NAME}_chr${chromo}_realigned.bam"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $HU_RMDUP -o $target_int -L chr${chromo}"
	run "$command" $target_int
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T IndelRealigner -R $HG19 -I $HU_RMDUP -targetIntervals $target_int -L chr${chromo} -o $realn_file"
	run "$command" $realn_file
done
	
command="$SAMTOOLS cat -o $HU_RMDUP ${HU_NAME}_chr*_realigned.bam $HU_UNALNED && rm $HU_UNALNED ${HU_NAME}_chr*"
run "$command" $HU_RMDUP

command="$SAMTOOLS sort -@ 25 $HU_RMDUP $HU_SORTED"
run "$command" ${HU_SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_RMDUP METRICS_FILE=$HU_METRICS_FILE && rm ${HU_SORTED}.bam"
run "$command" $HU_RMDUP

command="$SAMTOOLS index $HU_RMDUP"
run "$command" "A bunch of Samtools index files"

# -------------------------------------------------------
# BWA alignment to mouse:
# -------------------------------------------------------
command="samtools view -@ 25 -SbF 4 $HU_BAMFILE | $BAM2FASTQ - -o $HU_ALIGNED_FQ -f"
run "$command" $HU_ALIGNED_FQ

command="$BWA mem -M -v -t25 -R '$RG' $MGxx $HU_ALIGNED_FQ1 $HU_ALIGNED_FQ2 | samtools view -@ 25 -Sb - > $MSE_BAMFILE"
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

command="$SAMTOOLS view -bf 4 $HO_BAMFILE > $HO_UNALNED"
run "$command" $HO_UNALNED

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${HO_NAME}_chr${chromo}.intervals"
	realn_file="${HO_NAME}_chr${chromo}_realigned.bam"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $HO_BAMFILE -o $target_int -L chr${chromo}"
	run "$command" $target_int
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T IndelRealigner -R $HG19 -I $HO_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
	run "$command" $realn_file
done
	
command="$SAMTOOLS cat -o $HO_BAMFILE ${HO_NAME}_chr*_realigned.bam $HO_UNALNED && rm ${HO_NAME}_chr* $HO_UNALNED"
run "$command" $HO_BAMFILE

command="$SAMTOOLS sort -@ 25 $HO_BAMFILE $HO_SORTED"
run "$command" ${HO_SORTED}.bam

command="$SAMTOOLS_0p1 rmdup ${HO_SORTED}.bam $HO_BAMFILE && rm ${HO_SORTED}.bam"
run "$command" $HO_BAMFILE

command="$SAMTOOLS index $HO_BAMFILE"
run "$command" "A bunch of Samtools index files"

# -------------------------------------------------------
# Variant calling on HU
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HU_BAMFILE --output_mode EMIT_ALL_SITES -l OFF -stand_call_conf 1 -L $TARGET_REGIONS | ${GVCFTOOLS}gatk_to_gvcf --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 > $HU_VCF"
run "$command" $HU_VCF

command="awk '{if ((\$1~/#/) || ((\$7~/PASS/))) print }' $HU_VCF > $HU_PASS_EXTRACTED"
run "$command" $HU_PASS_EXTRACTED

# Need permission to write to /12TBLVM/Data/VEP79cache/../../...index
command="perl $VEP -i $HU_PASS_EXTRACTED -o $HU_VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command" $HU_VEP_ANNO 

command="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py $HU_VEP_ANNO $HU_CHOOSESTRAND"
run "$command" $HU_CHOOSESTRAND

command="python3 /12TBLVM/Data/MyScriptsOpen/VAS_Formatter_1.0.4.py $HU_CHOOSESTRAND $HU_ANNOTATED"
run "$command" $HU_ANNOTATED

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

command="python3 /12TBLVM/Data/MyScriptsOpen/VAS_Formatter_1.0.4.py $HO_CHOOSESTRAND $HO_ANNOTATED"
run "$command" $HO_ANNOTATED

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
