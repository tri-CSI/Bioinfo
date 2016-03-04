#!/usr/bin/perl
use strict;
use warnings;

my $ram = 20;
my $ncore = 25;

require '/home/biotools/tri-scripts/pipeline_general_config.pl';
our ($SAMTOOLS, $GATK, $HG_REF, $HG_ALL, $VEP, $MAF_SELECTOR, $MAF_EXTRACTOR, $VEP_CACHE);
our ($HAPMAP, $OMNI, $SNP1000, $DBSNP, $MILLS, $INDEL1000);

my $file_list = $ARGV[0];
our $logfile = $ARGV[1];
open FLIST, $file_list;
chomp (my @GVCFS = <FLIST>);

my $gvcf_args = "";
for my $gvcf ( @GVCFS ) {
    $gvcf_args .= " -V $gvcf ";
}

my $joint_vcf = "joint.vcf";
my $snp_recal = "vqsr.snp.recal";
my $snp_tranches = "vqsr.snp.trenches";
my $recalSnp = "recalibrated_snps_raw_indels.vcf";
my $indel_recal = "vqsr.indel.recal";
my $indel_tranches = "vqsr.indel.trenches";
my $recal = "recalibrated.vcf";
my $recalPostCGP = "recalibrated.postCGP.vcf";
my $recalGfiltered = "recalibrated.filtered.vcf";
my @cases;
my $suf_filtered = ".filtered.vcf";
my $suf_annotated = ".annotated.vcf";
my $suf_asnmaf = ".asnmaf.vcf";

# Pipeline starts here

printJobTitle("Joining GVCF files");
system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $GATK -T GenotypeGVCFs -R $HG_REF $gvcf_args -o $joint_vcf") );

printJobTitle("Recalibrating SNPs (VQSR)");
system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" 
    . "g -jar $GATK -T VariantRecalibrator -R $HG_ALL -input $joint_vcf "
    . "-resource:hapmap,known=false,training=true,truth=true,prior=15.0 $HAPMAP "
	. "-resource:omni,known=false,training=true,truth=true,prior=12.0 $OMNI " 
	. "-resource:1000G,known=false,training=true,truth=false,prior=10.0 $SNP1000 " 
	. "-resource:dbsnp,known=true,training=false,truth=false,prior=2.0 $DBSNP " 
	. "-an QD " 
	. "-an FS " 
	. "-an SOR " 
	. "-an MQ "
	. "-an MQRankSum " 
	. "-an ReadPosRankSum " 
	. "-an InbreedingCoeff "
	. "-mode SNP " 
	. "-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 " 
	. "-recalFile $snp_recal " 
	. "-tranchesFile $snp_tranches " )
);

printJobTitle("Applying SNPs recalibration");
system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
    . "g -jar $GATK -T ApplyRecalibration -R $HG_ALL -input $joint_vcf "
    . "-mode SNP "
    . "--ts_filter_level 99.0 "
    . "-recalFile $snp_recal "
    . "-tranchesFile $snp_tranches "
    . "-o $recalSnp" )
);

printJobTitle("Recalibrating INDELs (VQSR)");
system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" 
    . "g -jar $GATK -T VariantRecalibrator -R $HG_ALL -input $recalSnp "
	. "-resource:mills,known=false,training=true,truth=true,prior=12.0 $MILLS " 
	. "-resource:1000G,known=false,training=true,truth=false,prior=10.0 $INDEL1000 " 
	. "-an QD " 
	. "-an FS " 
	. "-an SOR " 
	. "-an MQ "
	. "-an MQRankSum " 
	. "-an ReadPosRankSum " 
	. "-an InbreedingCoeff "
	. "-mode INDEL " 
	. "-tranche 100.0 -tranche 99.9 -tranche 99.0 -tranche 90.0 " 
	. "-recalFile $indel_recal " 
	. "-tranchesFile $indel_tranches " )
);

printJobTitle("Applying INDELs recalibration");
system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
    . "g -jar $GATK -T ApplyRecalibration -R $HG_ALL -input $recalSnp "
    . "-mode INDEL "
    . "--ts_filter_level 99.0 "
    . "-recalFile $indel_recal "
    . "-tranchesFile $indel_tranches "
    . "-o $recal" )
);

printJobTitle("Extract PASS variants for each case");
open( ALLVAR, "$recal" );

while ( my $line = <ALLVAR>) {
    if ( $line =~ /^#CHROM/ ) {
        chomp( $line );
        @cases = split( /\t/, $line);
        splice( @cases, 0, 9);
        last;
    }
}
close ( ALLVAR );

my $forks = 0;
for my $case ( @cases ) {
    my $casevar = $case . $suf_filtered;
    push ( @varfiles, $casevar );
    my $pid = fork;

    if (not defined $pid) {
        printJobTitle("Unable to run parallel, exiting...");
        exit(1);
    }
        
    my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T SelectVariants -R $HG_ALL -V $recal "
        . "-o $casevar -sn $case -env -ef";

    if ($pid) {
        printJobTitle( $command );
        $forks++;
    } else {
        system ( $command );
        exit;
    }
}

for (1 .. $forks) {
    wait();
}

printJobTitle("Variant Effect Predictor (VEP)");
for my $case (@cases) {
    my $var_filt = $case . $suf_filtered;
    my $var_anno = $case . $suf_annotated;
    my $var_asn = $case . $suf_asnmaf;
    system( printJobTitle("perl $VEP "
        . "-i $var_filt -o $var_anno "
        . "--cache --vcf --fork $ncore "
        . "--total_length --maf_1kg --no_stats "
        . "--buffer_size 100000 --force " 
        . "--pick --dir $VEP_CACHE --port 3337") ); 
    system( printJobTitle("$MAF_SELECTOR $var_anno | $MAF_EXTRACTOR -c 11 > $var_asn") );
}

printJobTitle("Finished processing $file_list");
