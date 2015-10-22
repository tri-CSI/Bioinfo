#!/bin/bash

# Pipeline for xenograft analysis
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 19 October 2015

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
STRAND_1=`readlink $1`
STRAND_2=`readlink $2`
bname=`basename $STRAND_1`
BASE_NAME=`expr match "$bname" '\([^-_]*\)'`

mkdir -p $BASE_NAME
cd $BASE_NAME
curdir=`pwd`

LOG_FILE="${BASE_NAME}.$(date +%Y%m%d%H%M%S).trinome.log"

# Load necessary tools and functions
source xenograft.config

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
command="$BWA mem -Mt25 -R '$RG' $HG19 $STRAND_1 $STRAND_2 | samtools view -@ 25 -Sb - > $HU_BAMFILE"
run "$command"

command="$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
run "$command"

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE"
run "$command"

command="$SAMTOOLS index $HU_BAMFILE"
run "$command"

command="$SAMTOOLS view -bf 4 $HU_BAMFILE > $HU_UNALNED"
run "$command"

for chromo in M 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y
do
	target_int="${BASE_NAME}_chr${chromo}.intervals"
	realn_file="${BASE_NAME}_chr${chromo}_realigned.bam"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T RealignerTargetCreator -R $HG19 -I $HU_BAMFILE -o $target_int -L chr${chromo}"
	run "$command"
	
	command="java  -Djava.io.tmpdir=\"/tmp\" -Xmx100g -jar $GATK -T IndelRealigner -R $HG19 -I $HU_BAMFILE -targetIntervals $target_int -L chr${chromo} -o $realn_file"
	run "$command"
done
	
command="$SAMTOOLS cat ${BASE_NAME}_chr*_realigned.bam $HU_UNALNED -o $HU_BAMFILE && rm $HU_UNALNED ${BASE_NAME}_chr*"
run "$command"

command="$SAMTOOLS sort -@ 25 $HU_BAMFILE $HU_SORTED"
run "$command"

command="${PICARD}MarkDuplicates.jar I=${HU_SORTED}.bam O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE && rm ${HU_SORTED}.bam $HU_METRICS_FILE"
run "$command"

command="$SAMTOOLS index $HU_BAMFILE"
run "$command"

# ------------ QC --------------
command="$SAMSTAT $HU_BAMFILE"
run "$command"

mkdir qc
mv ${HU_BAMFILE}.samstat.html qc

command="$FASTQC $STRAND_1 $STRAND_2 -o qc"
run "$command"

# -------------------------------------------------------
# Variant calling and annotation
# -------------------------------------------------------

command="java -Xmx100g -jar $GATK -T UnifiedGenotyper -nt 25 -glm BOTH -R $HG19 -dcov 5000 -I $HU_BAMFILE --output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1 -L $TARGET_REGIONS > $ALL_VARIANTS"
run "$command"

command="$GATK_TO_GVCF --no-default-filters --min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 < $ALL_VARIANTS > $QUAL_FILTERED"
run "$command"
 
command="awk '\$1~/#/ || (\$7~/PASS/ && \$3=NR-64) {print }' $QUAL_FILTERED > $PASS_EXTRACTED"
run "$command"

command="perl $VEP -i $PASS_EXTRACTED -o $VEP_ANNO --cache --vcf --verbose --everything --fork 20 --total_length --maf_1kg --check_existing --allele_number --check_svs --port 3337 --buffer_size 100000 --dir /12TBLVM/Data/VEP79cache"
run "$command"

command="$VEP_STRANDSELECTOR $VEP_ANNO $VEP_CHOOSESTRAND"
run "$command"

command="$VEP_FORMATTOR $VEP_CHOOSESTRAND $VEP_FORMATTED"
run "$command"

command="awk '\$1!~/#/ {print \$1,\$2,\$2+1,\$3}' $PASS_EXTRACTED > $VAR_LIST"
run "$command"

command="$LIFTOVER $VAR_LIST $LO_HG38_MM10 $MSE_VAR_LIST $UNMAPPED"
run "$command"

command="$COMPARE_MSE $VEP_FORMATTED $MSE_VAR_LIST $ALLVAR_LIST"
run "$command"

command="awk -F $'\t' '\$1~/#/ || \$67 < 0.05 {print }' $ALLVAR_LIST > $ASNMAF_LIST"
run "$command"

echo -e "Variant count report \t$BASE_NAME" > $VAR_REPORT

echo >> $VAR_REPORT
echo Unfiltered variants >> $VAR_REPORT
echo >> $VAR_REPORT
allvar=`awk -F '\t' '$1!~/#/' $ALLVAR_LIST | wc -l`
human=`awk -F '\t' '$3~/H/' $ALLVAR_LIST | wc -l`
mouse=`awk -F '\t' '$3~/M/' $ALLVAR_LIST | wc -l`
mouse_percent=`bc <<< "scale=2; $mouse * 100 / $allvar"`
echo -e "All variants:\t$allvar" >> $VAR_REPORT
echo -e "Human unambiguous:\t$human" >> $VAR_REPORT
echo -e "Possibly mouse:\t$mouse" >> $VAR_REPORT
echo -e "Pos. mouse \(%\):\t$mouse_percent" >> $VAR_REPORT

echo >> $VAR_REPORT
echo EAS_MAF \< 0.05 >> $VAR_REPORT
echo >> $VAR_REPORT
allvar=`awk -F '\t' '$1!~/#/' $ASNMAF_LIST | wc -l`
human=`awk -F '\t' '$3~/H/' $ASNMAF_LIST | wc -l`
mouse=`awk -F '\t' '$3~/M/' $ASNMAF_LIST | wc -l`
mouse_percent=`bc <<< "scale=2; $mouse * 100 / $allvar"`
echo -e "All variants:\t$allvar" >> $VAR_REPORT
echo -e "Human unambiguous:\t$human" >> $VAR_REPORT
echo -e "Possibly mouse:\t$mouse" >> $VAR_REPORT
echo -e "Pos. mouse \(%\):\t$mouse_percent" >> $VAR_REPORT


# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
cd ..
