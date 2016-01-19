#!/bin/bash

# Pipeline for calling somatic SVNs and small INDELs using Strelka pipeline
# 	up to vcf files only
# version 1.0.1
# Developed by Tran Minh Tri
# Date: 07 Jan 2016

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

# Load necessary tools and functions
source /home/biotools/tri-scripts/pipeline_general.config

# check input fastq names
if [ $# -ne 1 ]; then
  echo "Usage: $0 [-options] <caselist in format: CASEID\tNORMAL\tTUMOUR>"
  exit
fi

# Get input file name info
curdir=`pwd`
outdir=$curdir/Strelka_result_$(date +%Y%m%d%H%M%S)
mkdir -p $outdir 
config=$outdir/config.ini
cp $STRELKA/etc/strelka_config_bwa_tgtSeq.ini $config

CASELIST=`readlink -f $1`
LOG_FILE="${curdir}/Strelka.$(date +%Y%m%d%H%M%S).log"

# -------------------------------------------------------
# HEADER of LOG_FILE
# -------------------------------------------------------
echo "******************* STRELKA PIPELINE ********************" > $LOG_FILE
echo "Description : Run Strelka variant caller for Somatic SNVs and small INDELs" >> $LOG_FILE
echo "+++++++++++++ Requires matched Normal-Tumour samples" >> $LOG_FILE
echo "Start dtime : `date`" >> $LOG_FILE
echo "Script name : $0" >> $LOG_FILE
echo "Current dir : $curdir" >> $LOG_FILE
echo "Log file at : $LOG_FILE" | tee -a $LOG_FILE
echo "*********************************************************" >> $LOG_FILE

# -------------------------------------------------------
# BWA alignment to human:
# -------------------------------------------------------
while IFS=$'\t' read caseid normal tumour 
do
    NORMAL=`readlink -f $normal`
    TUMOUR=`readlink -f $tumour`
    FOLDER=$curdir/$caseid
    ANA_FD=$FOLDER/myAnalysis

    mkdir -p $FOLDER
    run "$STRELKA/bin/configureStrelkaWorkflow.pl --normal=$NORMAL --tumor=$TUMOUR --ref=$HG_REF --config=$config --output-dir=$ANA_FD"
    cd $ANA_FD
    run "make -j $nproc"
    cd $curdir
    cat $ANA_FD/results/passed.somatic.snvs.vcf <(grep -v "^#" $ANA_FD/results/passed.somatic.indels.vcf) > $outdir/${caseid}.strelka.passed.vcf 
    cat $ANA_FD/results/all.somatic.snvs.vcf <(grep -v "^#" $ANA_FD/results/all.somatic.indels.vcf) > $outdir/${caseid}.strelka.all.vcf 
done < $CASELIST

# -------------------------------------------------------
# FOOTER
# -------------------------------------------------------
time_total
echo >> ${LOG_FILE}
echo "*****************************************************" >> $LOG_FILE
echo "*** Pipeline ends at `date` ***" >> $LOG_FILE
echo "*****************************************************" >> $LOG_FILE
