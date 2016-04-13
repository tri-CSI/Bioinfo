#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $ram = 50;
my $ncore = 25;
my $config = '/12TBLVM/biotools/Tri-scripts/general_pipeline_config.pl';
my ($BASE_NAME, $GVCF_LIST);
my $FOLDER = '.';
our $logfile = 'log.txt';

# Get command line arguments
GetOptions('conf=s' => \$config,
            'log=s' => \$logfile,
            'mem=s' => \$ram,
         'thread=s' => \$ncore,
       'gvcflist=s' => \$GVCF_LIST,
      'outfolder=s' => \$FOLDER,
         'prefix=s' => \$BASE_NAME);
if (not defined $GVCF_LIST)
{ die("Please supply a file that contains all resulting .g.vcf files"); }

# Load config file
require $config;
our ($SAMTOOLS, $PICARD, $GATK, $MAPQLASSIFY);
our ($HG_REF, $TRUSIGHT_CANCER_TR);

# Variables
my $infile_list = $ARGV[0];

# Pipeline starts here

###########################################
# Run HaplotypeCaller
###########################################
open FLIST, $infile_list;
chomp (my @ALL_BAM = <FLIST>);
close (FLIST);


# Pipeline starts here
open OFILE, ">$GVCF_LIST";
while ( @ALL_BAM ) {
    my $BAMFILE = shift( @ALL_BAM );
    my $name = $FOLDER . "/" . ( split ( /\//, ( split( /\./, $BAMFILE) )[-2] ) ) [-1];
    my $SORTED = $name . ".sorted.bam";
    my $gvcf = $name . ".g.vcf";

    printJobTitle("Processing $BAMFILE");
    system ( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $BAMFILE -o $SORTED") );

    system ( printJobTitle("$SAMTOOLS index $SORTED") );
    
    system( printJobTitle( "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $GATK -T HaplotypeCaller -R $HG_REF -I $SORTED -o $gvcf -L $TRUSIGHT_CANCER_TR -ERC GVCF") );    
    print OFILE "$gvcf\n";    
}
close OFILE;
