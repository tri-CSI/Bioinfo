#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $ram = 20;
my $ncore = 25;
my $config = '/home/biotools/tri-scripts/pipeline_general_config.pl';
my $BASE_NAME;
our $logfile = 'log.txt';

# Get command line arguments

GetOptions('conf=s' => \$config,
            'log=s' => \$logfile,
            'mem=s' => \$ram,
         'thread=s' => \$ncore,
       'gvcflist=s' => \$GVCF_LIST,
         'prefix=s' => \$BASE_NAME);

if (not defined $BASE_NAME)
{ die("Please supply a case annotation prefix (example: GC001-PPROJECT-ALPHA)"); }
if (not defined $GVCF_LIST)
{ die("Please supply a file that contains all resulting .g.vcf files"); }

my ($strand_1, $strand_2) = @ARGV;

# Load config file

require $config;
our ($SAMTOOLS, $PICARD, $GATK, $BWA, $VEP, $MAF_SELECTOR, $MAF_EXTRACTOR, $MAPQLASSIFY);
our ($HG_REF, $MSE_REF, $SNP1000, $DBSNP, $MILLS, $INDEL1000, $VEP_CACHE, $TARGET_REGIONS_CHR);
our (@mouse_chrs, @human_chrs);

# Variables

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my $DTST = sprintf("%04d%02d%02d", $year, $mon, $mday);
my $RG = "\@RG\\tID:0\\tLB:Nextera_Rapid_Capture_Enrichment\\tPL:ILLUMINA-NextSeq500\\tPU:\@NS500768\\tSM:$BASE_NAME\\tCN:CTRAD-CSI_Singapore\\tDS:NIL\\tDT:$DTST";

my $HU_BAMFILE = $BASE_NAME . ".human.bam";
my $HU_SORTED = $BASE_NAME . ".human.sorted.bam";
my $HU_METRICS_FILE = $BASE_NAME . ".human.metric";
my $HU_UNALNED = $BASE_NAME . ".human.unaligned.bam";
my $HU_REALGN = $BASE_NAME . ".human.realigned.bam";
my $HU_REC_TABLE = $BASE_NAME . ".human.recal.table";
my $HU_RECAL = $BASE_NAME . ".human.recalibrated.bam";
my $HU_NAMESORTED = $BASE_NAME . ".human.namesorted.bam";

my $HU_SUBTRACTED_SAM = $BASE_NAME . ".human.subtracted.sam";
my $HU_SUBTRACTED_BAM = $BASE_NAME . ".human.subtracted.bam";

my $MSE_BAMFILE = $BASE_NAME . ".mouse.bam";
my $MSE_SORTED = $BASE_NAME . ".mouse.sorted.bam";
my $MSE_METRICS_FILE = $BASE_NAME . ".mouse.metric";
my $MSE_UNALNED = $BASE_NAME . ".mouse.unaligned.bam";
my $MSE_REALGN = $BASE_NAME . ".mouse.realigned.bam";
my $MSE_REC_TABLE = $BASE_NAME . ".mouse.recal.table";
my $MSE_RECAL = $BASE_NAME . ".mouse.recalibrated.bam";
my $MSE_NAMESORTED = $BASE_NAME . ".mouse.namesorted.bam";

my $gvcf = $BASE_NAME . ".g.vcf";

my $forks = 0;
my $smallbams = "";
my $smallidx = "";
my $tgtfiles = "";

# Pipeline starts here

###########################################
# Align to HUMAN genome
###########################################

printJobTitle("Alignment to Human genome");
system ( printJobTitle("$BWA mem -Mt$ncore -R '$RG' $HG_REF $strand_1 $strand_2 | samtools view -@ $ncore -Sb - > $HU_BAMFILE") );

system ( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $HU_BAMFILE -o $HU_SORTED") );

system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $PICARD MarkDuplicates I=$HU_SORTED O=$HU_BAMFILE METRICS_FILE=$HU_METRICS_FILE") );

system ( printJobTitle("$SAMTOOLS index $HU_BAMFILE && rm $HU_SORTED $HU_METRICS_FILE") );

printJobTitle("GATK Indel realignment");
system ( printJobTitle("$SAMTOOLS view -bf 4 $HU_BAMFILE > $HU_UNALNED") );

for my $chr ( @human_chrs ) {
    my $target_int = "${BASE_NAME}_chr$chr" . ".intervals ";
    my $realn_file = "${BASE_NAME}_chr$chr" . "_realigned.bam ";
    my $realn_idx = "${BASE_NAME}_chr$chr" . "_realigned.bai ";
    $smallbams .= $realn_file . " ";
    $smallidx .= $realn_idx . " ";
    $tgtfiles .= $target_int . " ";
    
    my $pid = fork;

    if (not defined $pid) {
        printJobTitle("Unable to run parallel, exiting...");
        exit(1);
    }
        
    my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T RealignerTargetCreator -R $HG_REF -I $HU_BAMFILE "
        . "-known $MILLS -known $INDEL1000 "
        . "-o $target_int -L chr$chr && "
        . "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T IndelRealigner -R $HG_REF -I $HU_BAMFILE "
        . "-known $MILLS -known $INDEL1000 "
        . "-o $realn_file -L chr$chr -targetIntervals $target_int";
    
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

system( printJobTitle("$SAMTOOLS cat $smallbams $HU_UNALNED -o $HU_REALGN && " 
        . "rm $HU_UNALNED $smallbams $tgtfiles $smallidx") ); 

system( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $HU_REALGN -o $HU_BAMFILE && "
        . "rm $HU_REALGN") );

system( printJobTitle("$SAMTOOLS index $HU_BAMFILE") );

printJobTitle("Running Base Recalibration (BQSR)");
system( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" 
                    . "g -jar $GATK -T BaseRecalibrator -nct $ncore -R $HG_REF -I $HU_BAMFILE "
                    . "-knownSites $MILLS -knownSites $INDEL1000 -knownSites $DBSNP "
                    . "-o $HU_REC_TABLE ") ); 
  
system( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" 
                    . "g -jar $GATK -T PrintReads -nct $ncore -R $HG_REF -I $HU_BAMFILE "
                    . "-BQSR $HU_REC_TABLE -o $HU_RECAL") ); 

printJobTitle("Sort by name for Mapqlassify");
system( printJobTitle("$SAMTOOLS sort -@ $ncore -nT tmp $HU_RECAL -o $HU_NAMESORTED") );

system( printJobTitle("$SAMTOOLS view -H $HU_RECAL > $HU_SUBTRACTED_SAM") );

###########################################
# Align to MOUSE genome
###########################################

printJobTitle("Alignment to Mouse genome");
system ( printJobTitle("$BWA mem -Mt$ncore -R '$RG' $MSE_REF $strand_1 $strand_2 | samtools view -@ $ncore -Sb - > $MSE_BAMFILE") );

system ( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $MSE_BAMFILE -o $MSE_SORTED") );

system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $PICARD MarkDuplicates I=$MSE_SORTED O=$MSE_BAMFILE METRICS_FILE=$MSE_METRICS_FILE") );

system ( printJobTitle("$SAMTOOLS index $MSE_BAMFILE") );

printJobTitle("GATK Indel realignment");
system ( printJobTitle("$SAMTOOLS view -bf 4 $MSE_BAMFILE > $MSE_UNALNED") );

$forks = 0;
$smallbams = "";
$smallidx = "";
$tgtfiles = "";

for my $chr ( @mouse_chrs ) {
    my $target_int = "${BASE_NAME}_chr$chr" . ".intervals ";
    my $realn_file = "${BASE_NAME}_chr$chr" . "_realigned.bam ";
    my $realn_idx = "${BASE_NAME}_chr$chr" . "_realigned.bai ";
    $smallbams .= $realn_file . " ";
    $smallidx .= $realn_idx . " ";
    $tgtfiles .= $target_int . " ";
    
    my $pid = fork;

    if (not defined $pid) {
        printJobTitle("Unable to run parallel, exiting...");
        exit(1);
    }
        
    my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T RealignerTargetCreator -R $MSE_REF -I $MSE_BAMFILE "
        . "-o $target_int -L chr$chr && "
        . "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
        . "g -jar $GATK -T IndelRealigner -R $MSE_REF -I $MSE_BAMFILE "
        . "-o $realn_file -L chr$chr -targetIntervals $target_int";
    
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

system( printJobTitle("$SAMTOOLS cat $smallbams $MSE_UNALNED -o $MSE_REALGN && " 
        . "rm $MSE_UNALNED $smallbams $tgtfiles $smallidx") ); 

system( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $MSE_REALGN -o $MSE_BAMFILE && "
        . "rm $MSE_REALGN") );

system( printJobTitle("$SAMTOOLS index $MSE_BAMFILE") );

printJobTitle("Sort by name for Mapqlassify");
system( printJobTitle("$SAMTOOLS sort -@ $ncore -nT tmp $MSE_BAMFILE -o $MSE_NAMESORTED") );

###########################################
# Run MAPQLASSIFY
###########################################

printJobTitle("Run MAPQLASSIFY on namesorted alignment files");

system( "bash -c '" . printJobTitle("$MAPQLASSIFY <($SAMTOOLS view $HU_NAMESORTED) <($SAMTOOLS view $MSE_NAMESORTED) -o $HU_SUBTRACTED_SAM ") . "'");

system ( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $HU_SUBTRACTED_SAM -o $HU_SUBTRACTED_BAM") );

system ( printJobTitle("$SAMTOOLS index $HU_SUBTRACTED_BAM") );

###########################################
# Run HaplotypeCaller
###########################################

printJobTitle("Running HaplotypeCaller by chromosomes");

my $allgvcfs = "";
my $alloutput = "";
my $alloutput_idx = "";
$forks = 0;

for my $chr (@human_chrs) {
    my $target_reg = $TARGET_REGIONS_CHR . $chr . ".bed";
    my $output = "haplotype.chr$chr" . ".g.vcf";
    my $output_idx = "haplotype.chr$chr" . ".g.vcf.idx";
    $allgvcfs .= " -V $output ";
    $alloutput .= " $output ";
    $alloutput_idx .= " $output_idx ";
    
    my $pid = fork;
    if (not defined $pid) {
        printJobTitle("Unable to run parallel, exiting...");
        exit(1);
    }
        
    my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $GATK -T HaplotypeCaller -R $HG_REF -I $HU_SUBTRACTED_BAM -o $output -L $target_reg -ERC GVCF";    

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
system( printJobTitle("rm $alloutput $alloutput_idx") );

open( OFILE, ">>$GVCF_LIST" );
print OFILE "$gvcf\n";
close( OFILE );

printJobTitle("Finished processing case $BASE_NAME");
