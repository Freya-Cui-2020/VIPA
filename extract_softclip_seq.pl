#!/usr/bin/perl

use strict;
use warnings;

my ($sample, $fq1, $fq2, $path, $suffix) = @ARGV;
open HSA, '<', "filter.softclip_candidate_$sample.hsa.sam" or die $!;
if ($suffix =~ /gz$/) {
    open FQ1, "gzip -dc $path/$fq1 |" or die $!;
    open FQ2, "gzip -dc $path/$fq2 |" or die $!;
} else {
    open FQ1, "$path/$fq1" or die $!;
    open FQ2, "$path/$fq2" or die $!;
}
open OUT1, '>', "softclip_${sample}_1.fq" or die $!;
open OUT2, '>', "softclip_${sample}_2.fq" or die $!;

my %hash;
while (<HSA>) {
    chomp;
    my $id = (split /\t/)[0];
    $hash{$id} = 1;
}

while (<FQ1>) {
    chomp;
    my $name = $_;
    my $id = substr((split /\s/, $name)[0], 1);
    chomp(my $seq = <FQ1>);
    chomp(my $mark = <FQ1>);
    chomp(my $qual = <FQ1>);
    if (exists $hash{$id}) {
        print OUT1 "$name\n$seq\n$mark\n$qual\n";
    }
}
while (<FQ2>) {
    chomp;
    my $name = $_;
    my $id = substr((split /\s/, $name)[0], 1);
    chomp(my $seq = <FQ2>);
    chomp(my $mark = <FQ2>);
    chomp(my $qual = <FQ2>);
    if (exists $hash{$id}) {
        print OUT2 "$name\n$seq\n$mark\n$qual\n";
    }
}
close OUT1;
close OUT2;
