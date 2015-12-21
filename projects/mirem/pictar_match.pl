#!/usr/bin/perl
=head
	Author: TRAN Minh Tri - csitmt
	Date: Sep 2015
	Use: perl match.pl <infile> <mirna_prefix> > stdout
=cut

my $ifile = $ARGV[0];
my $prefix = $ARGV[1];

open (INFILE, "$ifile");

while ($line = <INFILE>) {
chomp($line);
($gene, $miRna) = split(/\t/, $line);

my $str = $miRna;
my @phrases;
my $class = '';
my $subClass = '';

while ($str =~ /([\w\d\-\.]+)\|/) {
#	print "Match: $1 in $str\n";
	$part = $1;
	$str = $';

	if ($part =~ /^(([a-zA-Z]{3}-)\d+)[^\d]*/) {
#		print "Class: $2\tSubclass: $1\n";
		$class = $2;
		$subClass = $1;
		push (@phrases, $part);
	}
	elsif ($part =~ /^[\d]/) {
		if ($class eq '') { 
			die "Error in class: $part, $str \n"; }
		else {
			push (@phrases, $class . $part); }
	}
	elsif ($part =~ /^[^\d]/) {
		if ($subClass eq '') { 
			die "Error in subclass: $part, $str \n"; }
		else {
			push (@phrases, $subClass . $part); }
	}
	else {die "Case not supported: $part, $str \n"; }
	
#	print "Phrases: ", join(", ", @phrases), "\n";
}
#	print "Phrases: ", join(", ", @phrases), "\n";

while ($case = shift(@phrases)) {
	print "$gene\t$prefix-$case\n";
}

}
close(INFILE);
