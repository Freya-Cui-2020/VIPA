#!/usr/bin/perl

use strict;
use warnings;

open my $IN, '<', shift or die $!;
open my $OUT, '>', shift or die $!;

my %hash;
while (<$IN>) {
    chomp;
    my ($id, $chr, $pos) = split /\t/;
    $hash{"$chr\t$pos"} += 1;
}

print $OUT "chr\tpos\tnum\n";
for my $key (sort { $hash{$b} <=> $hash{$a}} keys %hash) {
    print $OUT "$key\t$hash{$key}\n";
}

close $OUT;
