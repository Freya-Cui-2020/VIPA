#!/usr/bin/perl -w
use strict;

my $sample = shift;
my $gene_depth = "$sample.SD_for_each_gene";
my $virus_depth = "$sample.virus.depth";
my $virus_cn = "$sample.cn";

open VIRUS, "$virus_depth";
my %virus_length = ();
my %virus_coverage = ();
while(<VIRUS>){
	chomp;
	my @F = split(/\t/, $_);
	$virus_coverage{$F[0]} = $F[1];
	$virus_length{$F[0]} = $F[2];
}
close VIRUS;

my %gene = ();
my %coverage = ();
my %length = ();

open DEPTH, "$gene_depth";
while(<DEPTH>){
	if($_ =~ /^$sample/){
		my @F = split(/\t/, $_);
		$coverage{$F[1]}=$F[4];
		$length{$F[1]}=$F[5];
	}
}
close DEPTH;

open CN, ">$virus_cn";
foreach my $virus_name (sort(keys %virus_coverage)){
	foreach my $gene_name(sort(keys %coverage)){
		my $cn = (2*$length{$gene_name}*$virus_coverage{$virus_name})/($coverage{$gene_name}*$virus_length{$virus_name});
		print CN "$sample\t$virus_name\t$gene_name\t$cn\n";
	}
}

close CN;
