#!/usr/bin/perl

use strict;
use warnings;

die "please specify the configuration file:\n\tperl $0 config_file\n" if (scalar @ARGV) < 1;
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
#$hash_config{sample_prefix} = '' unless exists $hash_config{sample_prefix};
$hash_config{sample_suffix} = '' unless exists $hash_config{sample_suffix};
my $sample = $hash_config{sample};
my $output_path = "$hash_config{output_path}/$hash_config{sample}";
my $pipe_path = $hash_config{pipe_path};
#my $fq1 = "$hash_config{sample_prefix}$sample$hash_config{sample_suffix}1.$hash_config{suffix}";
#my $fq2 = "$hash_config{sample_prefix}$sample$hash_config{sample_suffix}2.$hash_config{suffix}";
my $fq1 = "$sample$hash_config{sample_suffix}1.$hash_config{suffix}";
my $fq2 = "$sample$hash_config{sample_suffix}2.$hash_config{suffix}";
my $picard = $hash_config{picard};
`mkdir -p $output_path`;

open SH, '>', "$output_path/1_rnaseq.sh" or die $!;

print SH "#!/bin/bash\nmodule load samtools/1.7-gcc-4.8.5\nmodule load hisat2/2.1.0-gcc-4.8.5\n\n";

my $hisat2_index = "/BIGDATA1/sysu_zhu_1/wangjian/WGS-WES-1/HBV/reference/hisat2";
my $merge=(split(/\//,$hash_config{bwa_ref_merge}))[-1];
my $virus=(split(/\./,(split(/\//,$hash_config{bwa_ref_virus}))[-1]))[0];

#1_rnaseq.sh
print SH "cd $output_path\n";
print SH "hisat2 -p 16 --dta -x $hisat2_index/$merge -1 $hash_config{input_path}/$fq1 -2 $hash_config{input_path}/$fq2 -S ${sample}.sam\n";
print SH "samtools sort -@ 16 -n -o ${sample}.bam ${sample}.sam\n";
print SH "rm ${sample}.sam\n";
print SH "samtools view -F 268 -f 1 ${sample}.bam | awk '{if(((\$3~/$virus/)&&(\$7~/chr/))||((\$3~/chr/)&&(\$7~/$virus/)))print \$0}' >$sample.discordant.sam\n";
print SH "perl /BIGDATA1/sysu_zhu_1/wangjian/HPV_20190215/script/deal_with_discordant.pl $sample.discordant.sam $sample.cluster\n";
close SH;
