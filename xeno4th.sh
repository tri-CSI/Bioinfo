#!/bin/bash
# set -o history -o histexpand

# Pipeline for xenograft following ILLUMINA-Basespace alignment
# version 0.4.1
# Developed by Tran Minh Tri
# Date: 30 June 2015

if [ $# -ne 2 ] || [[ "$1" != *fastq* ]] || [[ "$2" != *fastq* ]]; then
  echo "Usage: $0 <forward_strand_in_fastq> <reverse_strand_in_fastq>"
  exit
fi

# Tools
BWA="/12TBLVM/biotools/bwa-0.7.7/bwa"
SAMTOOLS_0p1="/12TBLVM/biotools/samtools/samtools"
SAMTOOLS="samtools"
LIFTOVER="/12TBLVM/Data/MinhTri/8_XENOGRAFT_2/liftOver"
PICARD="java -jar /12TBLVM/biotools/picard-tools-1.101/picard-tools-1.101/"
GATK="/12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar"
GATK_TO_GVCF="/12TBLVM/biotools/gvcftools-0.16/bin/gatk_to_gvcf"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"
VEP_STRANDSELECTOR="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py" 
VEP_FORMATTOR="python3 /12TBLVM/Data/MinhTri/8_XENOGRAFT_2/VAS_Formatter_1.0.5.py"
COMPARE_MSE="python3 /12TBLVM/Data/MinhTri/8_XENOGRAFT_2/compareMouse.py"

# Database
HG19="/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa"
BALB_CJ="/12TBLVM/Data/MinhTri/8_XENOGRAFT_2/BALB_cJ.chromosome.fa"
TARGET_REGIONS="/NextSeqVol/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"
LO_HG38_MM10="/12TBLVM/Data/MinhTri/8_XENOGRAFT_2/hg19ToMm10.over.chain.gz"

# Get input file name info
STRAND_1=`readlink $1`
STRAND_2=`readlink $2`
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^-_]*\)'`

mkdir -p $BASE_NAME
cd $BASE_NAME
curdir=`pwd`

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
VAR_LIST="${BASE_NAME}.var_list.bed"
MSE_VAR_LIST="${BASE_NAME}.mse_varlist.bed"
UNMAPPED="${BASE_NAME}.unmapped_varList.bed"
ALLVAR_LIST="${BASE_NAME}_allVariants.txt"
ASNMAF_LIST="${BASE_NAME}_asn_maf.txt"

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

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE"
run "$command" $HU_BAMFILE

command="$SAMTOOLS index $HU_BAMFILE"
run "$command" "A bunch of Samtools index files"

command="$SAMTOOLS view -bf 4 $HU_BAMFILE > $HU_UNALNED"
run "$command" $HU_UNALNED

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${BASE_NAME}_chr${chromo}.intervals"
	realn_file="${BASE_NAME}_chr${chromo}_realigned.bam"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $HU_BAMFILE -o $target_int -L chr${chromo}"
	run "$command" $target_int
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T IndelRealigner -R $HG19 -I $HU_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
	run "$command" $realn_file
done
	
command="$SAMTOOLS cat ${BASE_NAME}_chr*_realigned.bam $HU_UNALNED -o $HU_BAMFILE && rm $HU_UNALNED ${BASE_NAME}_chr*"
run "$command" $HU_BAMFILE

command="$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
run "$command" ${HU_SORTED}.bam

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE && rm ${HU_SORTED}.bam $HU_METRICS_FILE"
run "$command" $HU_BAMFILE

command="$SAMTOOLS index $HU_BAMFILE"
run "$command" "A bunch of Samtools index files"

# -------------------------------------------------------
# Variant calling and annotation
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HU_BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $ALL_VARIANTS"
run "$command" $ALL_VARIANTS

command="$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $ALL_VARIANTS > $QUAL_FILTERED"
run "$command" $QUAL_FILTERED
 
command="awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' $QUAL_FILTERED > $PASS_EXTRACTED"
run "$command" $PASS_EXTRACTED

command="perl $VEP -i $PASS_EXTRACTED -o $VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command" $VEP_ANNO

command="$VEP_STRANDSELECTOR $VEP_ANNO $VEP_CHOOSESTRAND"
run "$command" $VEP_CHOOSESTRAND

command="$VEP_FORMATTOR $VEP_CHOOSESTRAND $VEP_FORMATTED"
run "$command" $VEP_FORMATTED

command="awk '\$1!~/#/ {print \$1,\$2,\$2+1,\$3}' $PASS_EXTRACTED > $VAR_LIST"
run "$command" $VAR_LIST

command="$LIFTOVER $VAR_LIST $LO_HG38_MM10 $MSE_VAR_LIST $UNMAPPED"
run "$command" $MSE_VAR_LIST

command="$COMPARE_MSE $VEP_FORMATTED $MSE_VAR_LIST $ALLVAR_LIST"
run "$command" $ALLVAR_LIST

command="awk -F $'\t' '\$1~/#/ || \$67 < 0.05 {print }' $ALLVAR_LIST > $ASNMAF_LIST"
run "$command" $ASNMAF_LIST

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
