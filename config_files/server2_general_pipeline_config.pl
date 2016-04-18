#!/usr/bin/perl
# Tools

$BWA = '/usr/bin/bwa';
$SAMTOOLS = '/home/biotools/samtools-1.3/samtools';
$BCFTOOLS = '/home/biotools/bcftools-1.3/bcftools';
$SAMSTAT = '/usr/local/bin/samstat';
$PICARD = '/home/biotools/picard-tools-1.141/picard.jar';
$GATK = '/home/biotools/GATK-3.5/GenomeAnalysisTK.jar';
$GATK_TO_GVCF = '/home/biotools/gvcftools-0.16/bin/gatk_to_gvcf';
$STRELKA = '/home/biotools/strelka_1.0.14';
$IDENTIFY = '/home/minhtri/scripts/xenograft/identify_mouse.py';
$MAPQLASSIFY = '/home/biotools/tri-scripts/mapqlassify.py';
$VEP = '/home/biotools/ensembl-tools-release-83/scripts/variant_effect_predictor/variant_effect_predictor.pl';
$MAF_SELECTOR = '/home/biotools/tri-scripts/select_asn_maf.awk';
$MAF_EXTRACTOR = '/home/biotools/tri-scripts/mafextract.sh';
$SELECT_TRANSCRIPT = '/home/minhtri/scripts/vcf/VEPselectTranscript.py';

# Databases;

$HG_REF = '/home/sharedResources/hg19-2/hg19_1toM/hg19_1toM.fa';
$HG19_MTOY = '/home/sharedResources/hg19-2/hg19_MtoY/hg19_MtoY.fa';
$MSE_REF = '/home/minhtri/BAYXENOHH/Ref/NOD_ShiLtJ.1toM.fa';
$HG_ALL = '/home/sharedResources/hg19-2/hg19_all/hg19_all.fa';
$TARGET_REGIONS = '/home/sharedResources/hg19-2/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.bed';
$TARGET_REGIONS_CHR = '/home/minhtri/BAYXENOHH/Ref/NexteraRC_Exome_TR/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.chr';
$HAPMAP = '/home/minhtri/BAYXENOHH/Ref/GATK/hapmap_3.3.hg19.sites.gatk.vcf';
$OMNI = '/home/minhtri/BAYXENOHH/Ref/GATK/1000G_omni2.5.hg19.sites.gatk.vcf';
$SNP1000 = '/home/minhtri/BAYXENOHH/Ref/GATK/1000G_phase1.snps.high_confidence.hg19.sites.gatk.vcf ';
$DBSNP = '/home/minhtri/BAYXENOHH/Ref/GATK/dbsnp_138.hg19.gatk.vcf';
$MILLS = '/home/minhtri/BAYXENOHH/Ref/GATK/Mills_and_1000G_gold_standard.indels.hg19.sites.gatk.vcf';
$INDEL1000 = '/home/minhtri/BAYXENOHH/Ref/GATK/1000G_phase1.indels.hg19.sites.gatk.vcf';
$PHASE3_1000G = '/home/minhtri/BAYXENOHH/Ref/GATK/1000G_phase3_v4_20130502.sites.updatedict.gatk.vcf ';
$VEP_CACHE = '/home/biotools/ensembl-tools-release-83/CACHE/';

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
