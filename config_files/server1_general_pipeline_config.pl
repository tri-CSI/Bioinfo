#!/usr/bin/perl
# Tools

$BWA = '/usr/local/bin/bwa';
$SAMTOOLS = 'samtools';
$BCFTOOLS = 'bcftools';
$SAMSTAT = '/usr/local/bin/samstat';
$PICARD = '/12TBLVM/biotools/picard-tools-1.140/picard.jar';
$GATK = '/12TBLVM/biotools/GATK-3.5/GenomeAnalysisTK.jar';
$GATK_TO_GVCF = '/12TBLVM/biotools/gvcftools-0.16/bin/gatk_to_gvcf';
$STRELKA = '/12TBLVM/biotools/strelka_1.0.13';
$MAPQLASSIFY = '/12TBLVM/biotools/Tri-scripts/identify_mouse.py';
$VEP = '/12TBLVM/biotools/VEP83/ensembl-tools-release-83/scripts/variant_effect_predictor/variant_effect_predictor.pl';
$VEP_STRANDSELECTOR="python3 /12TBLVM/Data/MyScriptsOpen/VEPAnnotationSelector_1.1.9.py";
$VEP_FORMATTOR="python3 /12TBLVM/Data/MyScriptsOpen/VAS_Formatter_1.0.5.py";
$MAF_SELECTOR = '/12TBLVM/biotools/Tri-scripts/select_asn_maf.awk';
$MAF_EXTRACTOR = '/12TBLVM/biotools/Tri-scripts/mafextract.sh';

# Databases;

$HG_REF = '/12TBLVM/Data/hg19-2/hg19_1toM/hg19_1toM.fa';
$MSE_REF = '/12TBLVM/Data/mm_10/BALB_cJ.1toM.fa';

# NOTE:
# Need to modify downloaded Ref genome (chromosome 1 to M only)
# Then index by: bwa index, samtools faidx, Picard CreateSequenceDictionary

$HG_ALL = '/12TBLVM/Data/hg19-2/hg19_all/hg19_all.fa';
$TARGET_REGIONS = '/12TBLVM/Data/Nextera/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed';
$TRUSIGHT_CANCER_TR = '/12TBLVM/Data/TruSightCancer/TruSightCancer_TargetedRegions_v1.0.bed';
$TARGET_REGIONS_CHR = '/12TBLVM/Data/Nextera/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.chr';
$HAPMAP = '/12TBLVM/Data/GATK-resource-bundle/hapmap_3.3.hg19.sites.gatk.vcf';
$OMNI = '/12TBLVM/Data/GATK-resource-bundle/1000G_omni2.5.hg19.sites.gatk.vcf';
$SNP1000 = '/12TBLVM/Data/GATK-resource-bundle/1000G_phase1.snps.high_confidence.hg19.sites.gatk.vcf ';
$DBSNP = '/12TBLVM/Data/GATK-resource-bundle/dbsnp_138.hg19.gatk.vcf';
$MILLS = '/12TBLVM/Data/GATK-resource-bundle/Mills_and_1000G_gold_standard.indels.hg19.sites.gatk.vcf';
$INDEL1000 = '/12TBLVM/Data/GATK-resource-bundle/1000G_phase1.indels.hg19.sites.gatk.vcf';
$PHASE3_1000G = '/12TBLVM/Data/GATK-resource-bundle/1000G_phase3_v4_20130502.sites.updatedict.gatk.vcf ';
$VEP_CACHE = '/12TBLVM/Data/VEP83cache/';

@mouse_chrs = ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', 'X', 'Y', 'M');
@human_chrs = ('1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', 'X', 'Y', 'M');

# Helper functions

sub printJobTitle {
    my $job = $_[0];
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    $year += 1900;
    my $message = sprintf("%04d-%02d-%02d %02d:%02d:%02d | %s\n", $year, $mon, $mday, $hour, $min, $sec, $job);
    if (not defined $logfile)
    {   print $message; }
    else {
        open( LOG, ">> $logfile" );
        print LOG $message;
        close( LOG );
    }
    return $job;
}
