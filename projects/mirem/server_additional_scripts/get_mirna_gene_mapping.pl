#!/usr/bin/perl
use strict;
use Time::localtime;
##########
#
# Input Data (for gene-list)
#
##########

#
# to use:
# 	perl get_mirna_gene_mapping.pl my_genelist.txt specific_db|freestyle no_of_db(1|2|3|4) dblist(1,1,1,0,0) intersect|union true|false 
#
system("echo \"hello\" > not_ready.txt");

my $original_list = $ARGV[0];
my $list = $original_list.".convert.dedup.txt";
my $number_of_genes_in_ori = `wc -l $original_list | cut -d \" \" -f 1`;
chomp $number_of_genes_in_ori;
my $analysis_choice = $ARGV[1]; #specific_db or freestyle
my $no_of_db = $ARGV[2];

my $db_list = $ARGV[3]; #targetscan_conserved,targetscan_nonconserved,diana_microT,mirDB_mirtarget,miranda_human_conserved,miranda_human_non_conserved,pictar (for 'specific_db' only)
my $intx_union = $ARGV[4]; #intersect/union (only used in specific_db)
my $inc_nc = $ARGV[5]; #include non-conserved? (only used in 'freestyle') true/false
my $skip_computation = $ARGV[6]; #just report mirnas which can target the genes. No pval, no probs
my $pval_thresh = $ARGV[7]; #hypergeometric pval threshold
my $convergence_thresh = $ARGV[8]; #em convergence threshold
my $species = $ARGV[9]; #human or mouse
my $user_list = "$list.list";
my $name_stuff;
my $progs_folder = "/var/www/mirem2/mirvis_progs";
my $db_to_use = "$progs_folder/".$species."_mirna_gene_db";
my $mapping_to_use = "$progs_folder/".$species."_gene_mapping.txt";
my $database_c = "";

my (%pval_hash, %adj_pval_hash, %top_mirna_pval, %top_mirna_adj_pval, %map);

#
# get time
#
my $tm = localtime;
open OPTIONS, ">>options.txt";
printf OPTIONS ("Date of analysis: %02d-%02d-%04d, %02d:%02d:%02d \n", $tm->mday, ($tm->mon)+1, $tm->year+1900, $tm->hour, $tm->min, $tm->sec);
print OPTIONS "Species: $species\n";

#
# cleanup the genelist for dups & convert to gene name
#
my $ori_count = `wc -l $original_list | awk '{print \$1}'`;
chomp $ori_count ;

system("sort $original_list | uniq > $original_list.first_dedup");
open CONV, "$original_list.first_dedup";
open FIN, ">$original_list.first_dedup.conv";
open CHANGE, ">convert.txt";
while(my $line = <CONV>){
	chomp $line; 
	$line =~ s/\r//g;
	if ($line eq "") {next;}
	my $results = `grep \"^$line\t\" $mapping_to_use`;
	chomp $results;
	my ($query, $gene) = split "\t", $results;
	if ($gene ne "") { print FIN $gene."\n"; }

	print CHANGE $line."\t".$gene."\n";
}
close CONV; close FIN; close CHANGE;
system("rm $original_list.first_dedup");
system("sort $original_list.first_dedup.conv | uniq > $list");

my $change_count = `wc -l $list | awk '{print \$1}'`;
chomp $change_count;

#
# get analysis method and database to use
#
if ($analysis_choice eq "freestyle"){
	if($inc_nc eq "false") { $db_list = "1,0,1,1,1,0,1,1,1"; $name_stuff="101110111";}
	elsif($inc_nc eq "true") { $db_list = "1,1,1,1,1,1,1,1,1"; $name_stuff="111111111";}

	$intx_union = "intersect";

	$db_to_use = "$progs_folder/".$species."_intersect_records/$species.$name_stuff.$intx_union.$no_of_db.txt";

	my ($targetscan_c, $targetscan_nc, $diana, $mirdb, $miranda_c, $miranda_nc, $pictar, $pita, $rna22) = split "\,", $db_list;
	if($targetscan_c == 1) {$database_c .= "TargetScan (conserved), "}
        if($targetscan_nc == 1) {$database_c .= "TargetScan (non-conserved), "}
        if($diana == 1) {$database_c .= "Diana, "}
        if($mirdb == 1) {$database_c .= "mirDB, "}
        if($miranda_c == 1) {$database_c .= "Miranda (conserved), "}
        if($miranda_nc == 1) {$database_c .= "Miranda (non-conserved), "}
        if($pictar == 1) {$database_c .= "Pictar, "}
        if($pita == 1) {$database_c .= "PITA, "}
        if($rna22 == 1) {$database_c .= "RNA22, "}
        $database_c =~ s/\, $//;

}

elsif ($analysis_choice eq "specific_db"){
	my ($targetscan_c, $targetscan_nc, $diana, $mirdb, $miranda_c, $miranda_nc, $pictar, $pita, $rna22) = split "\,", $db_list;
	$name_stuff=$targetscan_c."".$targetscan_nc."".$diana."".$mirdb."".$miranda_c."".$miranda_nc."".$pictar."".$pita."".$rna22;

	$db_to_use = "$progs_folder/".$species."_intersect_records/$species.$name_stuff.$intx_union.txt";
	if($targetscan_c == 1) {$database_c .= "TargetScan (conserved), "}
        if($targetscan_nc == 1) {$database_c .= "TargetScan (non-conserved), "}
        if($diana == 1) {$database_c .= "Diana, "}
        if($mirdb == 1) {$database_c .= "mirDB, "}
        if($miranda_c == 1) {$database_c .= "Miranda (conserved), "}
        if($miranda_nc == 1) {$database_c .= "Miranda (non-conserved), "}
        if($pictar == 1) {$database_c .= "Pictar, "}
        if($pita == 1) {$database_c .= "PITA, "}
        if($rna22 == 1) {$database_c .= "RNA22, "}
	$database_c =~ s/\, $//;
}

#
# get mirna-gene interactions according to user gene-list
#
open FILE, $list;
system("rm $list.list || true");
while(my $g = <FILE>) {
	chomp $g;
        system("grep '\t$g\t' $db_to_use >> $list.list");
}
close FILE;

#
# get total number of genes in the db  
#
my $total_no_of_genes = `cut -f 2 $db_to_use | sort | uniq | wc -l | head -n 1 | awk '{print \$1}'`;
my $no_of_genes_in_list = `wc -l $list | head -n 1 | awk '{print \$1}'`;
chomp $total_no_of_genes; chomp $no_of_genes_in_list;

if ($skip_computation eq "false") {
	#
	# get number of genes (in the genelist) interacting with each mirna
	#
	system("cut -f 3 $list.list | sort | uniq -c | sort -k 1,1nr | awk '{print \$1\"\\t\"\$2}'> $list.genes_mirna");

	#
	# get number of genes (in the db) interacting with each mirna 
	#
	if (!(-e "$db_to_use.genes_mirna")) {
		system("cut -f 3 $db_to_use | sort | uniq -c | sort -k 1,1nr | awk '{print \$1\"\\t\"\$2}' > $db_to_use.genes_mirna");
	}

	my (%list_no_of_gene_in_mirna, %db_no_of_gene_in_mirna);

	open LIST, "$list.genes_mirna";
	while(my $line = <LIST>){
		chomp $line;
		my ($no, $mirna) = split "\t", $line;
		$list_no_of_gene_in_mirna{$mirna} = $no;
	}
	close LIST;

	open DB, "$db_to_use.genes_mirna";
	while(my $line = <DB>){
	    chomp $line;
	    my ($no, $mirna) = split "\t", $line;
            $db_no_of_gene_in_mirna{$mirna} = $no;
	}
	close DB;

	open LISTMAP, ">listmap.txt";
	## phyper(q, m, n, k, lower.tail = TRUE, log.p = FALSE)
	
	## q      vector of quantiles representing the number of white balls drawn without replacement from an urn which contains both black and$
	## m      the number of white balls in the urn.
	## n      the number of black balls in the urn.
	## k      the number of balls drawn from the urn.
	print LISTMAP "mirna\tno_of_gene_in_mirna(db):no_of_gene_not_in_mirna(db):no_of_gene_in_list:no_of_gene_in_mirna(list)\tp-value\n";
	foreach my $mirna ( keys %list_no_of_gene_in_mirna ) 
	{
		my $n = $list_no_of_gene_in_mirna{$mirna};
		my $d = $db_no_of_gene_in_mirna{$mirna};
		my $t = $total_no_of_genes-$d;
		print LISTMAP $mirna."\t".$d.":".$t.":".$no_of_genes_in_list.":".$n;
		
		print LISTMAP "\n";
	}
	close LISTMAP;
	%list_no_of_gene_in_mirna = ();
	%db_no_of_gene_in_mirna = ();

	##now we find out the hypergeometric probability p-value
	system("R CMD BATCH $progs_folder/add_hypergeometric_pval.R"); #output is listmap_w_pval.txt
	system("sort -k 3,3g listmap_w_pval.txt > listmap_w_pval.txt.tmp");
	system("mv listmap_w_pval.txt.tmp listmap_w_pval.txt");


	## record the p-value and adjusted p-value
	open PVAL, "listmap_w_pval.txt";
	my $entry_count = 0;
	my $top10count =0;
	while(my $line = <PVAL>){
		chomp $line;		
		my ($mirna, $details, $pval, $adj_pval) = split "\t", $line;
		if($adj_pval <= $pval_thresh && $entry_count<=1000) {
			$pval_hash{$mirna} = $pval;
			$adj_pval_hash{$mirna} = $adj_pval;
			$entry_count++;
		}
		if($top10count <= 1000) {
			$top_mirna_pval{$mirna} = $pval;
			$top_mirna_adj_pval{$mirna} = $adj_pval;
			$top10count++;
		}

		if($entry_count >= 1000) {last;}
	}
	close PVAL;

	my %report_mirna_targets;
	my %em_prob;

        ## if theres more than one miRNA significant in adj p-value treshold, pass them to EM-algorithm
	if ($entry_count > 1) {
		open OUT, ">$list.list.adj_pval_hash.txt";
		open FILE, $user_list;
		while(my $line = <FILE>){
			chomp $line;
			my ($a, $b, $c) = split "\t", $line;
			if(defined($adj_pval_hash{$c})) {print OUT $b."\t".$c."\n"}
		}
		
		system("java -classpath $progs_folder Geneset2miRNA $list.list.adj_pval_hash.txt $convergence_thresh"); #output is matrix_output.txt & em_pval.txt

		open EM, "em_pval.txt"; # hsa-miR-142-3p  7.2275671434466E-8
		while(my $line = <EM>) {
			chomp $line;
			my ($mirna, $prob) = split "\t", $line;
			$em_prob{$mirna} = $prob;
		}
		close EM;
	}

	elsif ($entry_count == 1) {
		open OUT, ">$list.list.adj_pval_hash.txt";
                open FILE, $user_list;
                while(my $line = <FILE>){
                        chomp $line;
                        my ($a, $b, $c) = split "\t", $line;
                        if(defined($adj_pval_hash{$c})) {print OUT $b."\t".$c."\n"}
                }
		system("java -classpath $progs_folder Geneset2miRNA $list.list.adj_pval_hash.txt 1"); #output is matrix_output.txt & em_pval.txt
	}

        ## get the gene targets of the predicted miRNAs
	open LIST, "$list.list";
	while(my $line = <LIST>) {
		chomp $line;
		my ($b, $gene, $mirna) = split "\t", $line;
		if (defined($top_mirna_adj_pval{$mirna})) {$report_mirna_targets{$mirna}.=$gene.",";}
	}
	close LIST;

	## we print the full results here. User have to download this.
    open RESULTS, ">results_full.txt";
        print RESULTS "miRNA\tp-value\tadjusted_p-value\tEM-probability\tratio\ttarget_genes\n";
        foreach my $mirna ( sort {$top_mirna_adj_pval{$a} <=> $top_mirna_adj_pval{$b}} keys %top_mirna_adj_pval ) {
                my @garr = split "\,", $report_mirna_targets{$mirna};
                if($em_prob{$mirna} eq "") {
			#print RESULTS $mirna."\t".$pval_hash{$mirna}."\t".$adj_pval_hash{$mirna}."\t"."-"."\t".scalar(@garr)."/".$change_count."\t".$report_mirna_targets{$mirna}."\n";		
			print RESULTS $mirna."\t".$top_mirna_pval{$mirna}."\t".$top_mirna_adj_pval{$mirna}."\t"."-"."\t".scalar(@garr)."/".$change_count."\t".$report_mirna_targets{$mirna}."\n";		
                }
                else {
			#print RESULTS $mirna."\t".$pval_hash{$mirna}."\t".$adj_pval_hash{$mirna}."\t".$em_prob{$mirna}."\t".scalar(@garr)."/".$change_count."\t".$report_mirna_targets{$mirna}."\n";
			print RESULTS $mirna."\t".$top_mirna_pval{$mirna}."\t".$top_mirna_adj_pval{$mirna}."\t".$em_prob{$mirna}."\t".scalar(@garr)."/".$change_count."\t".$report_mirna_targets{$mirna}."\n";

                }
        }
	close RESULTS;
        system("awk 'NR==1; {if(NR > 1) {print \$0 | \"sort -k 4,4gr -k 3,3g\"}}' results_full.txt > results_full.tmp");
        system("mv results_full.tmp results_full.txt");
        system("head -n 51 results_full.txt > results.txt");

    # 
    #   Draw Phylogenetic tree of miRNA with HG p-value < 0.05
    #
   #system("awk 'NR>1 && NR<27 && \$3<0.05' results_full.txt | $progs_folder/get_mature_sequences.py > mirna.fa");
    system("sed '1d' results.txt | $progs_folder/get_mature_sequences.py > mirna.fa");
    system("$progs_folder/muscle3.8.31_i86linux32 -in mirna.fa -out mirna_aligned.fa && rm mirna.fa");
    system("$progs_folder/catfasta2phyml.pl mirna_aligned.fa > mirna_aligned.phy");
    system("$progs_folder/PhyML-3.1_linux32 -i mirna_aligned.phy && rm mirna_aligned.phy mirna_aligned.phy_phyml_stats.txt");
    system("java -cp $progs_folder/forester_1038.jar org.forester.application.phyloxml_converter -f=nn -o mirna_aligned.phy_phyml_tree.txt mirna_aligned.phy_phyml_tree.xml");
    system("$progs_folder/beautify_phyloxml.py results.txt mirna_aligned.phy_phyml_tree.xml");


	## draw the matrix
	$entry_count++;
	system("cut -f 1-$entry_count matrix_output.txt > matrix_output.txt.tmp");
	system("mv matrix_output.txt.tmp matrix_output.txt");
	system("R CMD BATCH --vanilla --slave \"--args matrix_output.txt\" $progs_folder/draw_heatmap.R");
}

print OPTIONS "No of input genes (includes blank lines): $ori_count\n";
print OPTIONS "No of input genes after conversion and duplicate removal: $change_count\n";
print OPTIONS "Database(s) chosen: $database_c";
if ($analysis_choice eq "freestyle") {
	$database_c =~ s/(conserved)//g;
	print OPTIONS " - [$no_of_db out of 7 databases]\n";
}
else { print OPTIONS "\n" }
print OPTIONS "Hypergeometric p-value threshold: $pval_thresh\n";
print OPTIONS "EM convergence threshold: $convergence_thresh\n";
close OPTIONS;
#remove all intermediate files
system("rm not_ready.txt");
#system("rm not_ready.txt *.first_dedup.conv *.convert.dedup.txt.genes_mirna *.genes_mirna *.list *.list.adj_pval_hash.txt listmap_w_pval.txt listmap.txt em_pval.txt *.Rout");
system("tar -pczf mirem_analysis.tar.gz convert.txt matrix_output.txt mirvis_user.txt mirvis_user.txt.convert.dedup.txt options.txt results.txt results_full.txt");
