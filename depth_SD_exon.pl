#!/usr/bin/perl -w
use strict;
use Statistics::Descriptive;

my $sample = shift;
my $depth = "$sample.0.depth";
my $gene = "/BIGDATA1/sysu_zhu_1/script/INT/script/gene_hg38.bed";
my $depth_for_each_exon = "$sample.depth_for_each_exon.txt";
my $SD_for_each_gene = "$sample.SD_for_each_gene";

open DEPTH, "$depth";
open GENE, "$gene";
open DEPTH_EXON, ">$depth_for_each_exon";
open SD, ">$SD_for_each_gene";

my %exon_chr = ();
my %exon_start = ();
my %exon_end = ();
my %exon_count = ();
my %exon_len = ();

while(<GENE>){
	chomp;
	my @F = split(/\t/, $_);
	my @G = split(/_/, $F[3]);
	my $exon_name = $G[0]."_".$G[1];
	$exon_chr{$exon_name} = $F[0];
	if(!$exon_start{$exon_name}){
		$exon_start{$exon_name} = $F[1];
	}
	if($F[1] < $exon_start{$exon_name}){
		$exon_start{$exon_name} = $F[1];
	}
	if(!$exon_end{$exon_name}){
		$exon_end{$exon_name} = $F[2];
	}
	if($F[2] > $exon_end{$exon_name}){
		$exon_end{$exon_name} = $F[2];
	}
}
close GENE;

while(<DEPTH>){
	chomp;
	my @F = split(/\t/, $_);
	my $chr = $F[0];
	my $pos = $F[1];
	my $count = $F[2];
	foreach my $key(keys %exon_chr){
		if($chr eq $exon_chr{$key} && $pos <= $exon_end{$key} && $pos >= $exon_start{$key}){
			if($exon_count{$key}){
				$exon_count{$key} = $exon_count{$key} + $count;
			}else{
				$exon_count{$key} = $count;
			}
			if($exon_len{$key}){
				$exon_len{$key} = $exon_len{$key} + 1;
			}else{
				$exon_len{$key} = 1;
			}
			last;
		}
	}
}
close DEPTH;

my %depth = ();
my %gene_length = ();
my %gene_coverage = ();
foreach my $i(sort(keys %exon_count)){
	my $dep = $exon_count{$i}/$exon_len{$i};
	my @F = split(/_/, $i);
	my $gene = $F[0];
	push @{$depth{$gene}}, $dep;
	if(!$gene_length{$gene}){
		$gene_length{$gene} = $exon_len{$i};
	}else{
		$gene_length{$gene} += $exon_len{$i};
	}
	if(!$gene_coverage{$gene}){
		$gene_coverage{$gene} = $exon_count{$i};
	}else{
		$gene_coverage{$gene} += $exon_count{$i};
	}
	print DEPTH_EXON "$sample\t$i\t$exon_count{$i}\t$exon_len{$i}\t$dep\n";
}

foreach my $i(sort(keys %depth)){
	my @depth = @{$depth{$i}};
	my $stat = Statistics::Descriptive::Full->new();
	$stat->add_data(\@depth);
	my $mean = $stat->mean();
	my $variance = $stat->variance();
	print SD "$sample\t$i\t$mean\t$variance\t$gene_coverage{$i}\t$gene_length{$i}\n";
}
close DEPTH_EXON;
close SD;
