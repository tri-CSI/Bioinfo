#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $ram = 20;
my $ncore = 20;
my $config = '/home/biotools/tri-scripts/pipeline_general_config.pl';
my $FOLDER = ".";
our $logfile = 'log.txt';

# Get command line arguments

GetOptions('conf=s' => \$config,
            'log=s' => \$logfile,
            'mem=s' => \$ram,
         'thread=s' => \$ncore,
      'outfolder=s' => \$FOLDER);
$FOLDER .= "/";

require $config;

our ($VEP, $MAF_EXTRACTOR, $VEP_STRANDSELECTOR, $VEP_FORMATTOR, $VEP_CACHE);

my $file_list = $ARGV[0];

my %cases;
my $suf_annotated = ".annotated.vcf";
my $suf_choosestrand = ".stranded.txt";
my $suf_formatted = ".formatted.txt";
my $suf_asnmaf = ".asnmaf.txt";

# Pipeline starts here

printJobTitle("Find cases");
open( ALL_CASES, $file_list ) or die "Can't open $file_list";

while ( my $line = <ALL_CASES>) {
    chomp( $line );
    my $name = ( split( /\./, $line) ) [0];
    $cases { $name } = $line;
}

close ( ALL_CASES );

while ( my ( $case, $vcf ) = each %cases ) {
    my $var_anno = $FOLDER . $case . $suf_annotated;
    my $var_strd = $FOLDER . $case . $suf_choosestrand;
    my $var_fmt = $FOLDER . $case . $suf_formatted;
    my $var_asn = $FOLDER . $case . $suf_asnmaf;
    
    system( printJobTitle( "perl $VEP "
        . "-i $vcf -o $var_anno "
        . "--cache --vcf --fork $ncore "
        . "--ccds --canonical --total_length --maf_1kg --no_stats "
        . "--buffer_size 100000 --force " 
        . "--hgvs --dir $VEP_CACHE --port 3337") ); 
    
    system( printJobTitle("$VEP_STRANDSELECTOR $var_anno $var_strd") );
    system( printJobTitle("$VEP_FORMATTOR $var_strd $var_fmt") );
    
    system( printJobTitle("$MAF_EXTRACTOR $var_fmt > $var_asn") );
}

printJobTitle("Finished processing $file_list");
