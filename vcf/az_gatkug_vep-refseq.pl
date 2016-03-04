#!/usr/bin/perl
use strict;
use warnings;

my $ram = 20;
my $ncore = 45;

require '/home/biotools/tri-scripts/pipeline_general_config.pl';
our ($GATK, $GATK_TO_GVCF, $VEP, $MAF_SELECTOR, $MAF_EXTRACTOR, $VEP_CACHE);

my $HG_REF = '/home/minhtri/AZ-Vannessa/Ref/hg19_MtoY.fa';

my $file_list = $ARGV[0];
our $logfile = $ARGV[1];

my %cases;
my $suf_allvar = ".all_variants.vcf";
my $suf_filtered = ".filtered.vcf";
my $suf_annotated = ".annotated.vcf";
my $suf_asnmaf = ".asnmaf.vcf";

# Pipeline starts here

printJobTitle("Find cases");
open( ALL_CASES, $file_list ) or die "Can't open $file_list";

while ( my $line = <ALL_CASES>) {
    chomp( $line );
    my $name = ( split( /_/, $line) ) [0];
    $cases { $name } = $line;
}

close ( ALL_CASES );

my $forks = 0;
while ( my ( $case, $bamfile ) = each %cases ) {
    my $casevar = $case . $suf_allvar;
    my $var_filt = $case . $suf_filtered;
    my $var_anno = $case . $suf_annotated;
    my $var_asn = $case . $suf_asnmaf;
    
    system( printJobTitle( "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T UnifiedGenotyper -nt $ncore "
        . "-glm BOTH -R $HG_REF -dcov 5000 -I $bamfile -o $casevar " 
        . "--output_mode EMIT_VARIANTS_ONLY -l OFF -stand_call_conf 1" ));
    
    system( printJobTitle("$GATK_TO_GVCF --no-default-filters "
        . "--min-qd 2.0000 --min-gqx 30.0000 --min-mq 20.0000 "
        . "< $casevar > $var_filt" ));
    
    system( printJobTitle("perl $VEP "
        . "-i $var_filt -o $var_anno "
        . "--cache --vcf --fork $ncore "
        . "--total_length --maf_1kg --no_stats "
        . "--buffer_size 100000 --force " 
        . "--refseq --all_refseq --hgvs --dir $VEP_CACHE --port 3337") ); 
    
    system( printJobTitle("$MAF_SELECTOR $var_anno | $MAF_EXTRACTOR -c 11 > $var_asn") );
}

printJobTitle("Finished processing $file_list");
