#!/usr/bin/perl 

use strict;
use warnings;

my $path = shift;
my $readsupport = shift;

opendir DIR, $path or die $!;
open OUT, '>', 'INT_for_MH.xls' or die $!;
open ALL, '>', 'all_result.xls' or die $!;
open LEFT, '>', 'not_assemble.xls' or die $!;
print OUT "Sample\tAnnotation\tGene\thsa_chr\thsa_pos\thsa_num\tvirus_pos\tvirus_num\tvirus_type\tbreakpoint\tassembly_seq_length\tquery_start\tquery_end\thsa_start\thsa_end\tquery_start\tquery_end\tvirus_start\tvirus_end\tseq\n";
my $count = 0;
for my $name (readdir DIR) {
    next if $name eq '.' or $name eq '..';
    my $full_name = "$path/$name";
    next unless -d $full_name;
    #my $hpv_type;
    #open CFG, '<', "$full_name/pipe.config" or die $!;
    #while (<CFG>) {
    #    chomp;
    #    if (/^bwa_ref_virus/) {
    #        $hpv_type = (split /\./, (split /\//)[-1])[0];
    #    }
    #}
	#print "$full_name\n";
	opendir DIR1, $full_name or die $!;
	for my $type (readdir DIR1){
		next if $type eq '.' or $type eq '..';
		next if $type eq 'pre' or $type eq 'discordant' or $type eq 'oneend' or $type eq 'softclip' or $type eq 'tmp' or $type eq 'summary';
		next if($type =~ /\.bak/);
		my $virus = "$full_name/$type";
		next unless -d $virus;
		#print "$virus\n";
		
		if (-s "$virus/summary/annot.merge.xls") {
			my %result_info_of;
			open ANNOT, '<', "$virus/summary/annot.merge.xls" or die $!;
			my $head_annot = <ANNOT>;
			if (-s "$virus/summary/filter_result.xls") {
				open RESULT, '<', "$virus/summary/filter_result.xls" or die $!;
				my $head_result = <RESULT>;
				while (<RESULT>) {
					chomp;
					my $id = (split /\t/)[0];
					$result_info_of{$id} = $_;
					$count += 1;
				}
				close RESULT;
			}
			while (<ANNOT>) {
				chomp;
				next if /^\s/;
				my ($chr, $pos, $num) = (split /\t/)[2..4];
				next if $num < $readsupport;
				my $id = "${chr}_$pos";
				if (exists $result_info_of{$id}) {
					print OUT "$name\t$_\t$result_info_of{$id}\n";
					print ALL "$name\t$_\t$result_info_of{$id}\n";
				} else {
					print ALL "$name\t$_\n";
					print LEFT "$name\t$_\n";
				}
			}
			close ANNOT;
		} else {
			print "$name\t$type\n";
		}
	}
}
print $count;
closedir DIR;
close OUT;
close ALL;
close LEFT;
