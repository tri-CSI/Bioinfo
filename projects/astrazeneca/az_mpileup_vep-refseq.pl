#!/usr/bin/perl
use strict;
use warnings;

my $ram = 20;
my $ncore = 20;

require '/home/biotools/tri-scripts/pipeline_general_config.pl';
our ($SAMTOOLS, $BCFTOOLS, $VEP, $VEP_CACHE, $SELECT_TRANSCRIPT);

my $HG_REF = '/home/minhtri/AZ-Vannessa/Ref/hg19_MtoY.fa';

my $file_list = $ARGV[0];
our $logfile = $ARGV[1];
my $chrm = $ARGV[2];
my $trns = $ARGV[3];
my $gene = $ARGV[4];

my %cases;
my $suf_allvar = ".all_variants.vcf";
my $suf_annotated = ".annotated.vcf";
my $suf_gene = "." . $gene . ".vcf";

# Pipeline starts here

printJobTitle("Find cases");
open( ALL_CASES, $file_list ) or die "Can't open $file_list";

while ( my $line = <ALL_CASES>) {
    chomp( $line );
    my $name = ( split( /_/, $line) ) [0];
    $cases { $name } = $line;
}

close ( ALL_CASES );

while ( my ( $case, $bamfile ) = each %cases ) {
    my $casevar = $case . $suf_allvar;
    my $var_anno = $case . $suf_annotated;
    my $var_brca = $case . $suf_gene;
    
    system( printJobTitle( "$SAMTOOLS mpileup -uvf $HG_REF "
        . "$bamfile -r $chrm -t AD,DP | "
        . "$BCFTOOLS call -vmO v -o $casevar" ));
    
    system( printJobTitle( "perl $VEP "
        . "-i $casevar -o $var_anno "
        . "--cache --vcf --fork $ncore "
        . "--total_length --maf_1kg --no_stats "
        . "--buffer_size 100000 --force " 
        . "--refseq --all_refseq --hgvs --dir $VEP_CACHE --port 3337") ); 

    system( printJobTitle( "$SELECT_TRANSCRIPT $var_anno $var_brca $trns") );
}

printJobTitle("Finished processing $file_list");
