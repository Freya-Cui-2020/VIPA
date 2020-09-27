#!/usr/bin/perl

use strict;
use warnings;

my $sample = shift;
open my $DEDUP, '<', "$sample.dedup.sam" or die $!;
open my $HSA, '<', "$sample.hsa.sam" or die $!;
open my $HPV, '<', "$sample.virus.sam" or die $!;

my %hash;
while (<$DEDUP>) {
    chomp;
    next if /^@/;
    my ($id, $flag) = (split /\t/)[0,1];
    $hash{$id} = 1 unless $flag & 260;
}

open my $OUT1, '>', "$sample.hsa.dedup.sam" or die $!;
open my $OUT2, '>', "$sample.virus.dedup.sam" or die $!;
while (<$HSA>) {
    chomp;
    my $id = (split /\t/)[0];
    if (exists $hash{$id}) {
        print $OUT1 "$_\n";
    }
}
while (<$HPV>) {
    chomp;
    my $id = (split /\t/)[0];
    if (exists $hash{$id}) {
        print $OUT2 "$_\n";
    }
}
close $OUT1;
close $OUT2;
