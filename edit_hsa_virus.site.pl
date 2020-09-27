#!/usr/bin/perl

use strict;
use warnings;

open my $ALL, '<', 'merge.hsa_virus.site.xls' or die $!;
open my $HSA, '<', 'merge.hsa.stat.xls' or die $!;
open my $OUT, '>', 'merge.edit_hsa_virus.site.xls' or die $!;
my %hash;
while (<$ALL>) {
    chomp;
    my ($chr, $pos1, $pos2) = (split /\t/)[1,2,4];
    $hash{"$chr\t$pos1"}{$pos2} += 1;
}
print $OUT "hsa_chr\thsa_pos\thsa_num\tvirus_pos\tvirus_num\n";
while (<$HSA>) {
    chomp;
    my ($chr,$pos,$num) = split /\t/;
    next if $chr eq "chr";
    my %hash_tmp =  %{$hash{"$chr\t$pos"}};
#    my $len = keys %hash_tmp;
#    if ($len == 1) {
#        for my $key (keys %hash_tmp) {
#            print $OUT "$_\t$key\t$hash_tmp{$key}\n";
#        }
#        next;
#    }
    my $count = 0;
    for my $key (sort {$hash_tmp{$b} <=> $hash_tmp{$a}} keys %hash_tmp) {
        $count += 1;
        if ($count == 1) {
            print $OUT "$_\t$key\t$hash_tmp{$key}\n";
        } else {
            print $OUT "\t\t\t$key\t$hash_tmp{$key}\n";
        }
    }
}
close $OUT;
