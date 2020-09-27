#!/usr/bin/perl 

use strict;
use warnings;

my $org = shift;
open SAM, '<', "oneend.$org.sam" or die $!;
open OUT, '>', "oneend.$org.fa" or die $!;

while (<SAM>) {
    chomp;
    my ($id, $chr, $pos, $cigar, $seq) = (split /\t/)[0,2,3,5,9];
    $cigar =~ s/\d+[HD]//g;
    my @cigar_list = ($cigar =~ /\d+\D/g);
    my $new_seq;
    my ($num, $mark);
    my $new_cigar = '';
    my $temp = 0;
    for my $each (@cigar_list) {
        ($num, $mark) = ($each =~ /(\d+)(\D)/);
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
        $new_seq = substr($seq, 0, $1);
    } elsif ($new_cigar =~ /^(\d+)S(\d+)M$/) {
        $new_seq = substr($seq, $1, $2);
    } elsif ($new_cigar =~ /^(\d+)S(\d+)M(\d+)S$/) {
        $new_seq = substr($seq, $1, $2);
    } else {
        print "$id\t$cigar\n";
    }
    print OUT ">$id ${chr}_$pos\n$new_seq\n";
}
close OUT;
