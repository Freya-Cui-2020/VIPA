#!/usr/bin/perl

use strict;
use warnings;

die "Usage: perl $0 <hsa tab> <virus tab> <oneend sam>" unless @ARGV == 3;

my ($hsa_tab, $virus_tab, $sam_file) = @ARGV;
open HSA, "<", $hsa_tab or die $!;
open VIRUS, "<", $virus_tab or die $!;
open SAM, "<", $sam_file or die $!;

my (%name_hsa, %name_virus, %intersection);
<HSA>;
while (<HSA>) {
    chomp;
    my $name = (split /\t/)[0];
    $name_hsa{$name} = 1;
}
<VIRUS>;
while (<VIRUS>) {
    chomp;
    my $name = (split /\t/)[0];
    $name_virus{$name} = 1;
}

for my $key (keys %name_hsa) {
    if (exists $name_virus{$key}) {
        $intersection{$key} = 1;
    }
}

while (<SAM>) {
    chomp;
    my $name = (split /\t/)[0];
    if (exists $intersection{$name}) {
        print "$_\n";
    }
}
