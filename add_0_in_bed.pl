#!/usr/bin/perl
use warnings;
use strict;

my $sample = shift;
my $depth = "$sample.depth";
my $out = "$sample.0.depth";
my $bed = "/BIGDATA1/sysu_zhu_1/script/INT/script/gene_hg38.bed";

open BED, "$bed";

my %flag = ();
while(<BED>){
	chomp;
	my @F = split(/\t/,$_);
	for(my $i=$F[1]+1; $i<=$F[2]; $i++){
		if(!$flag{$F[0]."_".$i}){
			$flag{$F[0]."_".$i} = "TRUE";
			#print $F[0]."\t".$i."\n";
		}
	}
}
close BED;

open DEPTH, "$depth";

my %depth = ();
while(<DEPTH>){
	chomp;
	my @F = split(/\t/,$_);
	$depth{$F[0]."_".$F[1]} = $F[2];
}
close DEPTH;

open OUT, ">$out";
foreach my $i(sort(keys %flag)){
	my @F = split(/_/,$i);
	if($depth{$i}){
		print OUT "$F[0]\t$F[1]\t$depth{$i}\n";
	}else{
		print OUT "$F[0]\t$F[1]\t0\n";
	}
}
close OUT;