#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my $ram = 20;
my $ncore = 25;
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

our ($SAMTOOLS, $BWA, $HG_REF, $PICARD, $GATK);
our (@mouse_chrs, @human_chrs, $MILLS, $INDEL1000);

my $infile_list = $ARGV[0];
my $outfile_list = $ARGV[1];

open FLIST, $infile_list;
chomp (my @ALL_FASTQ = <FLIST>);
close (FLIST);

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my $DTST = sprintf("%04d%02d%02d", $year, $mon, $mday);


# Pipeline starts here
open OFILE, $outfile_list;
while ( @ALL_FASTQ ) {
    my $strand_1 = shift( @ALL_FASTQ );
    my $strand_2 = shift( @ALL_FASTQ );

    (my $case) = ( $strand_1 =~ /^(.+?)_/ );
    (my $case_check) = ( $strand_2 =~ /^(.+?)_/ );
    if ($case_check ne $case) { die ("Strand 1 and strand 2 might not be from the same case: " . $case . ", " . $case_check); }

    my $BAMFILE = $case . ".bam";
    my $SORTED = $case . ".sorted.bam";
    my $METRICS_FILE = $case . ".metric";
    my $UNALNED = $case . ".unaligned.bam";
    my $REALGN = $case . ".realigned.bam";
    my $RG = "\@RG\\tID:0\\tLB:Nextera_Rapid_Capture_Enrichment\\tPL:ILLUMINA-NextSeq500\\tPU:\@NS500768\\tSM:$case\\tCN:CTRAD-CSI_Singapore\\tDS:NIL\\tDT:$DTST";

    printJobTitle("Aligning case $case");
    system ( printJobTitle("$BWA mem -Mt$ncore -R '$RG' $HG_REF $strand_1 $strand_2 | samtools view -@ $ncore -Sb - > $BAMFILE") );
    system ( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $BAMFILE -o $SORTED") );
    system ( printJobTitle("java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram" . "g -jar $PICARD MarkDuplicates I=$SORTED O=$BAMFILE METRICS_FILE=$METRICS_FILE") );
    system ( printJobTitle("$SAMTOOLS index $BAMFILE && rm $SORTED $METRICS_FILE") );

    printJobTitle("GATK Indel realignment");
    system ( printJobTitle("$SAMTOOLS view -bf 4 $BAMFILE > $UNALNED") );

    my $forks = 0;
    my $smallbams = "";
    my $smallidx = "";
    my $tgtfiles = "";

    for my $chr ( @human_chrs ) {
        my $target_int = "${case}_chr$chr" . ".intervals ";
        my $realn_file = "${case}_chr$chr" . "_realigned.bam ";
        my $realn_idx = "${case}_chr$chr" . "_realigned.bai ";
        $smallbams .= $realn_file . " ";
        $smallidx .= $realn_idx . " ";
        $tgtfiles .= $target_int . " ";
        
        my $pid = fork;

        if (not defined $pid) {
            printJobTitle("Unable to run parallel, exiting...");
            exit(1);
        }

        my $command = "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
            . "g -jar $GATK -T RealignerTargetCreator -R $HG_REF -I $BAMFILE "
            . "-known $MILLS -known $INDEL1000 "
            . "-o $target_int -L chr$chr && "
            . "java -Djava.io.tmpdir=\"/tmp\" -Xmx$ram"
            . "g -jar $GATK -T IndelRealigner -R $HG_REF -I $BAMFILE "
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

    system( printJobTitle("$SAMTOOLS cat $smallbams $UNALNED -o $REALGN && "
            . "rm $UNALNED $smallbams $tgtfiles $smallidx") );

    system( printJobTitle("$SAMTOOLS sort -T tmp -@ $ncore $REALGN -o $BAMFILE && "
            . "rm $REALGN") );

    system( printJobTitle("$SAMTOOLS index $BAMFILE") );
    printJobTitle("Finished creating $BAMFILE");
    print OFILE "$BAMFILE\n";    
}
close OFILE;
