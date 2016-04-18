#!/usr/bin/perl
use strict;
use warnings;

require '/home/biotools/tri-scripts/pipeline_general_config.pl';
our ($SAMTOOLS, $GATK, $HG_REF);

my $TARGET_REGIONS = '/home/minhtri/BAYXENOHH/Ref/NexteraRC_Exome_TR/NexteraRapidCapture_Exome_TargetedRegions_v1.2Used.chr';
my $inputbam = $ARGV[0];
my $gvcf = $inputbam .".g.vcf";
my $ram = 20;
my @chrs = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, "M", "X", "Y");

# --------------------
# Pipeline starts here

printJobTitle("Indexing bam file");
system ( printJobTitle("$SAMTOOLS index $inputbam") );

printJobTitle("Calling HaplotypeCaller by chromosomes");
my $allgvcfs = "";
my $forks = 0;
for my $chr (@chrs) {
    my $target_reg = $TARGET_REGIONS . $chr . ".bed";
    my $output = $inputbam . ".chr$chr" . ".g.vcf";
    $allgvcfs .= " -V $output ";
    
    my $pid = fork;
    if (not defined $pid) {
        printJobTitle("Unable to run parallel, exiting...");
        exit(1);
    }
        
    my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $GATK -T HaplotypeCaller -R $HG_REF -I $inputbam -o $output -L $target_reg -ERC GVCF";    

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

printJobTitle("Combining g.vcf files...");
system( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -cp $GATK org.broadinstitute.gatk.tools.CatVariants -R $HG_REF $allgvcfs -out $gvcf -assumeSorted") ); 
system( printJobTitle("rm " . $inputbam . ".chr*") );

printJobTitle("Finished processing $inputbam");
