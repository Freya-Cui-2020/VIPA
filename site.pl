#!/usr/bin/perl

use strict;
use warnings;

open my $IN, '<', shift or die $!;
open my $OUT, '>', shift or die $!;
while (<$IN>) {
    chomp;
    my ($id, $chr, $pos, $cigar) = (split /\t/)[0,2,3,5];
    $cigar =~ s/H/S/g;
    $cigar =~ s/\d+I//g;
    my @cigar_list = ($cigar =~ /(\d+\D)/g);
    my ($num, $mark);
    my $new_cigar = '';
    my $temp = 0;
    for my $each (@cigar_list) {
        ($num,$mark) = ($each =~ /(\d+)(\D)/);
        if ($mark eq 'S') {
            if ($temp == 0) {
                $new_cigar .= $each;
            } else {
                $new_cigar = "$new_cigar${temp}M$each";
                $temp = 0;
            }
        } else {
            $temp += $num;
        }
    }
    if ($mark ne 'S') {
        $new_cigar = "$new_cigar${temp}M";
    }
    if ($new_cigar =~ /^(\d+)M(\d+)S$/) {
        $pos = $pos + $1 - 1;
        print $OUT "$id\t$chr\t$pos\n";
    } elsif ($new_cigar =~ /^(\d+)S(\d+)M$/) {
        print $OUT "$id\t$chr\t$pos\n";
    } elsif ($new_cigar =~ /^(\d+)S(\d+)M(\d+)S$/) {
        if ($3 > $1) {
            $pos = $pos + $2 -1;
        }
        print $OUT "$id\t$chr\t$pos\n";
    } else {
        print "$id\t$cigar\n";
    }
}

close $OUT;
