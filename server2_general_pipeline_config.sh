# Tools
BWA="/usr/bin/bwa"
SAMTOOLS="/home/biotools/samtools-1.2/samtools"
SAMSTAT="/usr/local/bin/samstat"
PICARD="/home/biotools/picard-tools-1.141/picard.jar"
GATK="/home/biotools/GATK-3.5/GenomeAnalysisTK.jar"
GATK_TO_GVCF="/home/biotools/gvcftools-0.16/bin/gatk_to_gvcf"
STRELKA="/home/biotools/strelka_1.0.14"
IDENTIFY="/home/minhtri/scripts/xenograft/identify_mouse.py"
VEP="/12TBLVM/biotools/VEP79/ensembl-tools-release-79/scripts/variant_effect_predictor/variant_effect_predictor.pl"
MAF_SELECTOR="/12TBLVM/Data/MinhTri/6_SCRIPTS/vcf/select_asn_maf.awk"
MAF_EXTRACTOR="/12TBLVM/Data/MinhTri/6_SCRIPTS/vcf/mafextract.sh"


# Database
HG_REF="/home/sharedResources/hg19-2/hg19_1toM/hg19_1toM.fa"
TARGET_REGIONS="/home/sharedResources/hg19-2/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed"

# Functions
start_time=$(date +%s)
last_time=$(date +%s)

function getTime {
	hours=$[ $1 / 3600 ]
	minutes=$[ $[$1 % 3600] / 60]
	seconds=$[ $[$1 % 3600] % 60]
	echo "${hours}:${minutes}:${seconds}"
}

function run {
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

function start_log {
    echo "******************* $1 ********************" > $4
    echo "Description : $2" >> $4
    echo "Start dtime : `date`" >> $4
    echo "Script name : $3" >> $4
    echo "Current dir : $(pwd)" >> $4
    echo "Log file at : $4" | tee -a $4
    echo "*********************************************************" >> $4
}

function end_log {
    time_total
    echo >> $1
    echo "*****************************************************" >> $1
    echo "*** Pipeline ends at `date` ***" >> $1
    echo "*****************************************************" >> $1
}
