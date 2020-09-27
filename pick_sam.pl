#!/usr/bin/perl

use strict;
use warnings;

my $sample = shift;
open SITE, '<', "merge.hsa_virus.site.xls" or die $!;
open SOFT_HSA, '<', "../softclip/filter.softclip_pemerge_$sample.site.hsa.sam" or die $!;
open SOFT_VIRUS, '<', "../softclip/filter.softclip_pemerge_$sample.site.virus.sam" or die $!;
open HSA, '<', "../oneend/filter.oneend.hsa.sam" or die $!;
open VIRUS, '<', "../oneend/filter.oneend.virus.sam" or die $!;
open ANNOT, '<', "annot.merge.xls" or die $!;
open OUT, '>', "annot_with_sam.xls" or die $!;
my (%all_of, %site_of);
while (<SITE>) {
    chomp;
    my ($id, $chr, $pos) = (split /\t/)[0..2];
    $all_of{$id} = 1;
    push @{$site_of{"${chr}_$pos"}}, $id;
}

my %sam_of;
while (<SOFT_HSA>) {
    next if /^@/;
    my $id = (split /\t/)[0];
    if (exists $all_of{$id}) {
        $sam_of{$id} .= $_;
    }
}
close SOFT_HSA;
while (<SOFT_VIRUS>) {
    next if /^@/;
    my $id = (split /\t/)[0];
    if (exists $all_of{$id}) {
        $sam_of{$id} .= $_;
    }
}
close SOFT_VIRUS;
while (<HSA>) {
    next if /^@/;
    my $id = (split /\t/)[0];
    if (exists $all_of{$id}) {
        $sam_of{$id} .= $_;
    }
}
while (<VIRUS>) {
    next if /^@/;
    my $id = (split /\t/)[0];
    if (exists $all_of{$id}) {
        $sam_of{$id} .= $_;
    }
}
my $head = <ANNOT>;
print OUT $head;
while (<ANNOT>) {
    chomp;
    my ($chr,$pos) = (split /\t/)[2,3];
    if ($chr ne '') {
        my $key = $chr."_".$pos;
        print OUT "$_\n";
        for my $id (@{$site_of{$key}}) {
            print OUT $sam_of{$id};
        }
        print OUT "\n";

    }
}
close OUT;
