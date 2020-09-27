#!/usr/bin/perl -w
use strict;
die "Usage:perl $0 <infile>\n" unless (1==@ARGV);

open IN , "$ARGV[0]" || die "$!\n";
my ($l2,$l3,$l4);
while (<IN>){
	chomp;
	$l2=<IN>;
	$l3=<IN>;
	$l4=<IN>;
	chomp $l2;
	chomp $l3;
	chomp $l4;
	$l2 = (split(/\s+/,$l2))[1];
	$l3 = (split(/\s+/,$l3))[1];
	$l4 = (split(/\s+/,$l4))[1];
	<IN>;
	print "$_\t$l2\t$l3\t$l4\t101\n";
}
close IN;
