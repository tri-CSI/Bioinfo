#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $ram = 50;
my $ncore = 25;
my $config = '/12TBLVM/biotools/Tri-scripts/general_pipeline_config.pl';
my ($BASE_NAME, $BAM_LIST);
my $FOLDER = '';
our $logfile = 'log.txt';

# Get command line arguments
GetOptions('conf=s' => \$config,
            'log=s' => \$logfile,
            'mem=s' => \$ram,
         'thread=s' => \$ncore,
       'bam_list=s' => \$BAM_LIST,
      'outfolder=s' => \$FOLDER,
         'prefix=s' => \$BASE_NAME);

if (not defined $BAM_LIST)
{ die("Please supply a file that contains all resulting .g.vcf files"); }

# Load config file
require $config;
our ($SAMTOOLS, $BCFTOOLS, $PICARD, $GATK, $MAF_EXTRACTOR, $VEP_STRANDSELECTOR, $VEP_FORMATTOR );
our ($HG_REF, $TRUSIGHT_CANCER_TR, $VEP, $VEP_CACHE);

my %cases;
my $suf_allvar = ".mpileup.vcf";
my $suf_annotated = ".annotated.vcf";
my $suf_choosestrand = ".stranded.txt";
my $suf_formatted = ".formatted.txt";
my $suf_asnmaf = ".asnmaf.txt";

# Pipeline starts here

printJobTitle("Find cases");
open( ALL_CASES, $BAM_LIST ) or die "Can't open $BAM_LIST";

while ( my $line = <ALL_CASES>) {
    chomp( $line );
    my $name = ( split ( /\//, ( split( /\./, $line) )[-2] ) ) [-1];
    $cases { $name } = $line;
}

close ( ALL_CASES );

while ( my ( $case, $bamfile ) = each %cases ) {
    my $casevar = $case . $suf_allvar;
    my $var_anno = $case . $suf_annotated;
    my $var_strd = $FOLDER . $case . $suf_choosestrand;
    my $var_fmt = $FOLDER . $case . $suf_formatted;
    my $var_asn = $FOLDER . $case . $suf_asnmaf;
    
    system( printJobTitle( "$SAMTOOLS mpileup -uvf $HG_REF "
        . "$bamfile -l $TRUSIGHT_CANCER_TR -t AD,DP | "
        . "$BCFTOOLS call -vmO v -o $casevar" ));
    
    system( printJobTitle( "perl $VEP "
        . "-i $casevar -o $var_anno "
        . "--cache --vcf --fork $ncore "
        . "--ccds --canonical --total_length --maf_1kg --no_stats "
        . "--buffer_size 100000 --force " 
        . "--hgvs --dir $VEP_CACHE --port 3337") ); 
    
    system( printJobTitle("$VEP_STRANDSELECTOR $var_anno $var_strd && rm $var_anno") );
    system( printJobTitle("$VEP_FORMATTOR $var_strd $var_fmt && rm $var_strd") );
    system( printJobTitle("$MAF_EXTRACTOR $var_fmt > $var_asn") );
}

printJobTitle("Finished processing $BAM_LIST");
