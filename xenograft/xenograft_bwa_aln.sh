#!/bin/bash
set -o history -o histexpand

# Pipeline for analysing xenograft data
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

ALN_HMN_1="1.aln_human.${BASE_NAME}_R1.sai"
ALN_HMN_2="1.aln_human.${BASE_NAME}_R2.sai"
HH_BAMFILE="1.aln_human.${BASE_NAME}.bam"

FASTQ_MSE="2.aln_mouse.${BASE_NAME}#.fastq"
FASTQ_MSE_1="2.aln_mouse.${BASE_NAME}_1.fastq"
FASTQ_MSE_2="2.aln_mouse.${BASE_NAME}_2.fastq"
ALN_MSE_1="3.aln_mouse.${BASE_NAME}_1.sai"
ALN_MSE_2="3.aln_mouse.${BASE_NAME}_2.sai"
MSE_BAMFILE="3.aln_mouse.${BASE_NAME}.bam"

FASTQ_REALN="4.realn_human.${BASE_NAME}#.fastq"
FASTQ_REALN_1="4.realn_human.${BASE_NAME}_1.fastq"
FASTQ_REALN_2="4.realn_human.${BASE_NAME}_2.fastq"
REALN_HMN_1="5.realn_human.${BASE_NAME}_1.sai"
REALN_HMN_2="5.realn_human.${BASE_NAME}_2.sai"
HO_BAMFILE="5.realn_human.${BASE_NAME}.bam"

HH_SORTED="6.HH.sorted.${BASE_NAME}" 				# .bam added by samtools
HH_RM_DUP="6.HH.dup_removed.${BASE_NAME}.bam"
HH_RG_ADDED="6.HH.readgp_add.${BASE_NAME}.bam"
HH_VCF_GATK="6.HH.var_call.${BASE_NAME}.vcf"

HO_SORTED="7.HO.sorted.${BASE_NAME}" 				# .bam added by samtools
HO_RM_DUP="7.HO.dup_removed.${BASE_NAME}.bam"
HO_RG_ADDED="7.HO.readgp_add.${BASE_NAME}.bam"
HO_VCF_GATK="7.HO.var_call.${BASE_NAME}.vcf"

COMBINED_VCF="8.combined.${BASE_NAME}.vcf"
ANNOTATED="8.annotated.${BASE_NAME}.vcf"
CHOOSESTRAND="9.chs_stnd.${BASE_NAME}.txt"
DIV_COL="9.final.${BASE_NAME}.txt"

LOG_FILE="${BASE_NAME}.trinome.log"

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

$BWA aln -l22 -k0 -t10 $HG19 $STRAND_1 > $ALN_HMN_1
log "!!" $? $ALN_HMN_1

$BWA aln -l22 -k0 -t10 $HG19 $STRAND_2 > $ALN_HMN_2
log "!!" $? $ALN_HMN_2

# Flag -F 0x4 excludes reads that are not aligned (take aligned reads only)
$BWA sampe $HG19 $ALN_HMN_1 $ALN_HMN_2 $STRAND_1 $STRAND_2 | $SAMTOOLS_1p2 view -bS -F 0x4 - > $HH_BAMFILE
log "!!" $? $HH_BAMFILE

# -------------------------------------------------------
# BWA alignment to mouse:
# -------------------------------------------------------
begin "Alignment to Mouse genome"

$BAM2FASTQ $HH_BAMFILE -o $FASTQ_MSE 
log "!!" $? $FASTQ_MSE

$BWA aln -l22 -k0 -t10 $MM10 $FASTQ_MSE_1 > $ALN_MSE_1
log "!!" $? $ALN_MSE_1

$BWA aln -l22 -k0 -t10 $MM10 $FASTQ_MSE_2 > $ALN_MSE_2
log "!!" $? $ALN_MSE_2

# Flag -f 0x4 take reads that are not aligned to mouse (therefore unique to human)
$BWA sampe $MM10 $ALN_MSE_1 $ALN_MSE_2 $FASTQ_MSE_1 $FASTQ_MSE_2 | $SAMTOOLS_1p2 view -bS -f 0x4 - > $MSE_BAMFILE
log "!!" $? $MSE_BAMFILE

# -------------------------------------------------------
# Realign to human
# -------------------------------------------------------
begin "Re-alignment to human genome"

$BAM2FASTQ $MSE_BAMFILE -o $FASTQ_REALN
log "!!" $? $FASTQ_REALN

$BWA aln -l22 -k0 -t10 $HG19 $FASTQ_REALN_1 > $REALN_HMN_1
log "!!" $? $REALN_HMN_1

$BWA aln -l22 -k0 -t10 $HG19 $FASTQ_REALN_2 > $REALN_HMN_2
log "!!" $? $REALN_HMN_2

# Flag -F 0x4 excludes reads that are not aligned (take aligned reads only)
$BWA sampe $HG19 $REALN_HMN_1 $REALN_HMN_2 $FASTQ_REALN_1 $FASTQ_REALN_2 | $SAMTOOLS_1p2 view -bF 0x4 - > $HO_BAMFILE
log "!!" $? $HO_BAMFILE

# -------------------------------------------------------
# Variant calling on HH_BAMFILE
# -------------------------------------------------------
begin "Variant calling on HH file"

$SAMTOOLS_1p2 sort $HH_BAMFILE $HH_SORTED
log "!!" $? ${HH_SORTED}.bam

$SAMTOOLS_0p1 rmdup ${HH_SORTED}.bam $HH_RM_DUP
log "!!" $? $HH_RM_DUP

$PICARD_ADD_READ_GRP I=$HH_RM_DUP O=$HH_RG_ADDED RGID=Xenograft_trial LB=Nextera_Rapid_Capture_Enrichment PL=ILLUMINA-NextSeq50 PU=@NS500768 SM=${BASE_NAME}.HH CN=CTRAD-CSI_Singapore DT=20150415 
log "!!" $? $HH_RG_ADDED

$SAMTOOLS_1p2 index $HH_RG_ADDED
log "!!" $? "A bunch of Samtools index files"

java -jar /12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar -T UnifiedGenotyper --min_base_quality_score 20 -R $HG19 -I $HH_RG_ADDED -o $HH_VCF_GATK --output_mode EMIT_VARIANTS_ONLY -log ${BASE_NAME}.HH.log
log "!!" $? "$HH_VCF_GATK and ${BASE_NAME}.HH.log"

# -------------------------------------------------------
# Variant calling on HO_BAMFILE
# -------------------------------------------------------
begin "Variant calling on HO file"

$SAMTOOLS_1p2 sort $HO_BAMFILE $HO_SORTED
log "!!" $? ${HO_SORTED}.bam

$SAMTOOLS_0p1 rmdup ${HO_SORTED}.bam $HO_RM_DUP
log "!!" $? $HO_RM_DUP

$PICARD_ADD_READ_GRP I=$HO_RM_DUP O=$HO_RG_ADDED RGID=Xenograft_trial LB=Nextera_Rapid_Capture_Enrichment PL=ILLUMINA-NextSeq50 PU=@NS500768 SM=${BASE_NAME}.HO CN=CTRAD-CSI_Singapore DT=20150415 
log "!!" $? $HO_RG_ADDED

$SAMTOOLS_1p2 index $HO_RG_ADDED
log "!!" $? "A bunch of Samtools index files"

java -jar /12TBLVM/biotools/GenomeAnalysisTK-3.3-0/GenomeAnalysisTK.jar -T UnifiedGenotyper --min_base_quality_score 20 -R $HG19 -I $HO_RG_ADDED -o $HO_VCF_GATK --output_mode EMIT_VARIANTS_ONLY -log ${BASE_NAME}.HO.log
log "!!" $? "$HO_VCF_GATK and ${BASE_NAME}.HO.log"

# -------------------------------------------------------
# Combine HH and HO .vcf files
# -------------------------------------------------------
begin "Combine HH and HO .vcf files"

bgzip $HH_VCF_GATK
log "!!" $? "${HH_VCF_GATK}.gz"

tabix ${HH_VCF_GATK}.gz -p vcf
log "!!" $? "${HH_VCF_GATK}.gz.tbi"

bgzip $HO_VCF_GATK
log "!!" $? "${HO_VCF_GATK}.gz"

tabix ${HO_VCF_GATK}.gz -p vcf
log "!!" $? "${HO_VCF_GATK}.gz.tbi"

python /12TBLVM/Data/MinhTri/scripts/combine.py ${HH_VCF_GATK}.gz ${HO_VCF_GATK}.gz $COMBINED_VCF
log "!!" $? $COMBINED_VCF

# -------------------------------------------------------
# Annotate vcf file
# -------------------------------------------------------
begin "Annotate vcf file"

perl /12TBLVM/biotools/ensembl-tools-release-75/scripts/variant_effect_predictor/variant_effect_predictor.pl -i $COMBINED_VCF -o $ANNOTATED --cache --vcf --verbose --everything --fork 30 --total_length --maf_1kg --check_existing --allele_number --check_svs --buffer_size 100000 --dir /12TBLVM/Data/VEP75cache
log "!!" $? $ANNOTATED

python3 /12TBLVM/Data/MyScriptsOpen/choose_strand_vcf08.py $ANNOTATED $CHOOSESTRAND
log "!!" $? $CHOOSESTRAND

python3 /12TBLVM/Data/MyScriptsOpen/divideExistingVarsIntoColumns03.py $CHOOSESTRAND $DIV_COL
log "!!" $? $DIV_COL

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE