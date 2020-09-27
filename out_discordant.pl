#!/usr/bin/perl

use strict;
use warnings;

die "please specify the configuration:\n\tperl $0 config_file\n" if (scalar @ARGV ) < 1;
my $config = shift;
open CONFIG, "$config" or die $!;

my %hash_config;
while(<CONFIG>){
	chomp;
	next if /^#/;
	if(/\s*(\S+)\s*=\s*(\S+)\s*/){
		if(!$hash_config{$1}){
			$hash_config{$1} = $2;
		}else{
			$hash_config{$1} = "$hash_config{$1};$2";
		}
	}
}

$hash_config{sample_suffix} = '' unless exists $hash_config{sample_suffix};
my $sample = $hash_config{sample};
my $output_path = "$hash_config{output_path}/$hash_config{sample}";
my $pipe_path = $hash_config{pipe_path};
my $fq1 = "$sample$hash_config{sample_suffix}1.$hash_config{suffix}";
my $fq2 = "$sample$hash_config{sample_suffix}2.$hash_config{suffix}";
my $hsa_ref_type = $hash_config{hsa_ref_type};
my $human_genome = $hash_config{bwa_ref_hsa};
my $picard = $hash_config{picard};
`mkdir -p $output_path`;

open SH, '>', "$output_path/discordant_all.sh" or die $!;
print SH "#!/bin/bash\n\n";

my @array = split(/;/, $hash_config{virus_ref_type});
foreach my $virus_ref_type(@array){
	my $output_path1 = "$output_path/$virus_ref_type";
	my $virus_genome = "$hash_config{bwa_ref_virus}/$virus_ref_type.fa";
	
	open SH_1, '>', "$output_path1/discordant.sh" or die $!;
	print SH_1 "#!/bin/bash\n\n";
	
	print SH_1 "cd $output_path1/discordant\n";
	print SH_1 "cat discordant_candidate_*.sam | awk '{if(\$6 !~ /*/) print \$0}' >$sample.discordant.sam\n";
	print SH_1 "perl /BIGDATA1/sysu_zhu_1/script/INT/script/deal_with_discordant.pl $sample $sample.discordant.sam $sample.cluster\n";
	print SH_1 "perl /BIGDATA1/sysu_zhu_1/script/INT/script/deal_with_cluster.pl $human_genome $virus_genome $sample.cluster $sample.break.xls\n";
	close SH_1;
	
	print SH "sh $output_path1/discordant.sh\n";
}
close SH;
