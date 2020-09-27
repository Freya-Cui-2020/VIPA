#!/usr/bin/perl

use strict;
use warnings;

open my $STAT, '<', 'hsa.stat.xls' or die $!;

my @list;
while (<$STAT>) {
    chomp;
    my ($chr,$pos) = (split /\t/)[0,1];
    next if $chr eq 'chr';
    push @list, [$chr,$pos];
#    print "@{$list[0]}";
#    last;
}

my (%hash, %hash_merge);

for my $i (0..$#list) {
    my ($chr_1, $pos_1) = @{$list[$i]};
    next if exists $hash{"$chr_1\t$pos_1"};
    for my $j ($i..$#list) {
        my ($chr_2, $pos_2) = @{$list[$j]};
        if ($chr_1 eq $chr_2 and abs($pos_1-$pos_2) <= 10) {
            $hash{"$chr_2\t$pos_2"} = 1;
            $hash_merge{"$chr_2\t$pos_2"} = "$chr_1\t$pos_1";
        }
    }
}
open my $SITE, '<', 'hsa.site.xls' or die $!;
open my $OUT, '>', 'merge.hsa.site.xls' or die $!;
while (<$SITE>) {
    chomp;
    my ($id,$chr,$pos) = split /\t/;
    if (exists $hash_merge{"$chr\t$pos"}) {
        my $tmp_info = $hash_merge{"$chr\t$pos"};
        print $OUT "$id\t$tmp_info\n";
    } else {
        print $OUT "$_\n";
    }
}
close $OUT;
