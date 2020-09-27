#!/usr/bin/perl

use strict;
use warnings;

my $sample = shift;
open SAM, '<', "$sample.hsa.dedup.sam" or die $!;
#open LEFT, '>', 'left.xls' or die $!;

my (%hash, %mapq_of);
while (<SAM>) {
    chomp;
    my ($id, $mapq) = (split /\t/)[0,4];
    $mapq_of{$id} = 0 unless exists $mapq_of{$id};
    $mapq_of{$id} += 1 if $mapq < 4;
    if (/AS:i:(\d+).*XS:i:(\d+)/) {
        if ($1 != 0 && $1 <= $2) {
#            print LEFT "$id\t$mapq\n";
            $hash{$id} = 1;
        }
    }
}
#close LEFT;

open HSA, '<', "$sample.hsa.dedup.sam" or die $!;
open VIRUS, '<', "$sample.virus.dedup.sam" or die $!;
open OUT_1, '>', "$sample.hsa.dedup.uniq.sam" or die $!;
open OUT_2, '>', "$sample.virus.dedup.uniq.sam" or die $!;

while (<HSA>) {
    chomp;
    my $id = (split /\t/)[0];
    unless ($mapq_of{$id}>1) {
        print OUT_1 "$_\n";
    }
}
while (<VIRUS>) {
    chomp;
    my $id = (split /\t/)[0];
    unless ($mapq_of{$id}>1) {
        print OUT_2 "$_\n";
    }
}

close OUT_1;
close OUT_2;
