#!/usr/bin/perl

use strict;
use warnings;

my $config = shift;
open CONFIG, '<', $config or die $!;

my %hash_config;
while (<CONFIG>) {
    chomp;
    next if /^#/;
    if (/\s*(\S+)\s*=\s*(\S+)\s*/) {
        $hash_config{$1} = $2;
    }
}
close CONFIG;

$hash_config{sample_suffix} = '' unless exists $hash_config{sample_suffix};
my $sample = $hash_config{sample};
my $output_path = "$hash_config{output_path}/$hash_config{sample}";

if($hash_config{method} eq "RCA"){
	open STAT, '<', "$output_path/pre/dedup.sort.stat.xls" or die $!;
}elsif($hash_config{method} eq "MIP"){
	open STAT, '<', "$output_path/pre/sort.stat.xls" or die $!;
}
open PIPE_CONFIG, '>', "$output_path/pipe.config" or die $!;

print PIPE_CONFIG "####config####\n\n";
print PIPE_CONFIG "sample=$hash_config{sample}\nsample_suffix=$hash_config{sample_suffix}\n";
print PIPE_CONFIG "bwa_ref_hsa=$hash_config{bwa_ref_path}/$hash_config{hsa_ref_type}.fa\n";
print PIPE_CONFIG "blast_ref_hsa=$hash_config{blast_ref_path}/$hash_config{hsa_ref_type}.fa\n";

my $type;
while (<STAT>) {
	if($hash_config{mode} eq "dominate"){
		$type = (split /\t/)[0];
		print PIPE_CONFIG "virus_ref_type=$type\n";
		last;
	}elsif($hash_config{mode} eq "multi"){
		$type = (split /\t/)[0];
		print PIPE_CONFIG "virus_ref_type=$type\n";
	}
}
close STAT;

print PIPE_CONFIG "bwa_ref_virus=$hash_config{bwa_ref_path}\n";
print PIPE_CONFIG "bwa_ref_merge=$hash_config{bwa_ref_path}\n";
print PIPE_CONFIG "blast_ref_virus=$hash_config{blast_ref_path}\n";
print PIPE_CONFIG "input_path=$hash_config{input_path}\n";
print PIPE_CONFIG "output_path=$hash_config{output_path}\n";
print PIPE_CONFIG "pipe_path=$hash_config{pipe_path}\n";
print PIPE_CONFIG "hsa_ref_type=$hash_config{hsa_ref_type}\n";
print PIPE_CONFIG "suffix=$hash_config{suffix}\n";
print PIPE_CONFIG "sge=$hash_config{sge}\n";
print PIPE_CONFIG "threads=$hash_config{threads}\n";
print PIPE_CONFIG "maxvmem=$hash_config{maxvmem}\n";
print PIPE_CONFIG "mem=$hash_config{mem}\n";
print PIPE_CONFIG "flanking=$hash_config{flanking}\n";
print PIPE_CONFIG "picard=$hash_config{picard}\n";

close PIPE_CONFIG;
