#!/bin/usr/perl

use warnings;
use strict;

die "Usage: perl $0 <info file> <output dir> <prefix>\neg: perl $0 path/to/50bp.info dir/of/output\n" if @ARGV < 2;

my ($info_file, $out_dir, $prefix) = @ARGV;
$prefix ||= "";
open my $in, "<", $info_file or die $!;

open my $out_10, ">", "$out_dir/${prefix}10.mh.txt" or die $!;
open my $out_20, ">", "$out_dir/${prefix}20.mh.txt" or die $!;
open my $out_30, ">", "$out_dir/${prefix}30.mh.txt" or die $!;
open my $out_40, ">", "$out_dir/${prefix}40.mh.txt" or die $!;
open my $out_50, ">", "$out_dir/${prefix}50.mh.txt" or die $!;

while (<$in>) {
    chomp;
    my ($id, @seq) = split /\t/;
    my $break = $seq[-1];
    @seq = @seq[0 .. 2];
    my @mh = &MHS(\@seq);
    for (my $i=0; $i<$#mh; $i+=2) {
        my $xa = abs($mh[$i]-$break+1);
        my $xb = abs($mh[$i+1]-$break+1);
        my $l = $mh[$i+1] - $mh[$i] + 1;
        my $s = substr($seq[0], $mh[$i], $l);
        if ($xa <= 10 || $xb <= 10) {
            print $out_10 "$id\t$mh[$i]\t$l\t$s\n";
        }
        if ($xa <= 20 || $xb <= 20) {
            print $out_20 "$id\t$mh[$i]\t$l\t$s\n";
        }
        if ($xa <= 30 || $xb <= 30) {
            print $out_30 "$id\t$mh[$i]\t$l\t$s\n";
        }
        if ($xa <= 40 || $xb <= 40) {
            print $out_40 "$id\t$mh[$i]\t$l\t$s\n";
        }
        if ($xa <= 50 || $xb <= 50) {
            print $out_50 "$id\t$mh[$i]\t$l\t$s\n";
        }
    }
}
close $out_10;
close $out_20;
close $out_30;
close $out_40;
close $out_50;

sub MHS {
    my $array = shift;
    my $len = length($array->[0]);
    my (@result, %hash);
    for (my $i=20; $i<$len-50; $i++) {
        for (my $j=$len-20; $j>$i; $j--) {
            my $tmp_seq = substr($array->[0], $i, $j-$i+1);
            next if $tmp_seq =~ /\|/;
            undef %hash;
            for my $seq (@$array) {
                $seq = uc $seq;
                my $key = substr($seq, $i, $j-$i+1);
                $hash{$key} = 1;
            }
            next if scalar(keys %hash) != 1;
            push @result, ($i, $j);
            $i = $j+1;
        }
    }
    return @result;
}
