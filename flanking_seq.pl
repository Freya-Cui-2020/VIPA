#!/usr/bin/perl -w 

use strict;
use Bio::DB::Fasta;

if(scalar(@ARGV) == 0){
	print help_text();
	exit(0);
}

## mandatory arguments

my $break_result = "";
my $genome = "";
my $flank = "";
my $sanger_seq = "";
my $output_fname = "";

## parse command line arguments

while (scalar(@ARGV) > 0){
	my $this_arg = shift @ARGV;
	if ($this_arg eq '-h') {print help_text; exit; }
	
	elsif ($this_arg eq '-b') {$break_result = shift @ARGV;}
	elsif ($this_arg eq '-g') {$genome = shift @ARGV;}
	elsif ($this_arg eq '-f') {$flank = shift @ARGV;}
	elsif ($this_arg eq '-s') {$sanger_seq = shift @ARGV;}
	elsif ($this_arg eq '-o') {$output_fname = shift @ARGV}
	elsif ($this_arg =~ m/^-/) {print "unknown flag: $this_arg\n";}
}

if($break_result eq ""){
	die "you should specify the break result file\n";
}
if($genome eq ""){
	die "you should specify the genome file identical with the break result\n";
}
if($flank eq ""){
	die "you should specify the length of upstream/downstream of break site\n";
}
if($sanger_seq eq ""){
	die "you should specify the sanger sequence file or the directory contained the sequence\n";
}
if($output_fname eq ""){
	die "you should specify output filename\n";
}

my $human_db = Bio::DB::Fasta->new("$genome");
my $sanger = "";
my $idflag = 0;
my $flag = "HG_HPV";

#################################
#read break result file provided#
#################################

open FILE, "<$break_result" || die "$!\n";
open OUT, ">$output_fname" || die "$!\n";

while(<FILE>){
	chomp;
	next if(/Sam/);
	my ($id,$hpvS,$hpvE,$hgS,$hgE,$hgmap,$break_pos) = (split(/\s+/,$_))[0..2,4,5..7];
	my $tmp = $id;
	$tmp=~s/\(/\\(/g; #specify the id in the first column in the break result file(blast)
	$tmp=~s/\)/\\)/g;
	
	##read sanger sequence
	if(-e "$sanger_seq/$id.seq"){ #sanger sequence in $seq directory
		$idflag = 1;
		open SN , "$sanger_seq/$id.seq" || die "$!";
		while (<SN>){
			chomp;
			next if (/\>/);
			s/\s+//g;
			$sanger .= $_;
		}
		close SN;
	}else{ #sanger sequence in $seq file
		open SN , "$sanger_seq" || die "$!";
		$/ = ">";
		<SN>;
		while (<SN>){
			chomp;
			my $id1 = $1 if($_ =~ /^(\S+)\n/);
			if($id1 eq $tmp){ ##SRR**.1 SRR**.19
				$idflag=1;
				$sanger = (split(/\n/,$_,2))[1];
				$sanger =~ s/\n//g;
			}
		}
		close SN;
		$/ = "\n";
	}
	
	if($idflag == 0){
		print "$id not in $sanger_seq\n";
		die;
	}
	
	my ($chr,$break) = split(/:|_/,$break_pos);
	my @maps = split(/:|-/,$hgmap);
	my $insert_len = 0;
	my $insert = "";
	my $hpv_seq = "";
	my $hg_seq = "";
	my $hg_seq1 = "";
	my $hg_seq2 = "";
	my $total_seq = "";
	
	# calculate the insert length and get the insert sequence
	if($hpvS < $hgS){
		$insert_len = $hgS -$hpvE - 1; 

		if($insert_len<0){ #junctional microhomologies
			$insert = uc(substr($sanger, ($hgS - 1), ($hpvE - $hgS + 1)));
			$insert = ".".$insert.".";
		}elsif($insert_len==0){ #apparent blunt joins
			$insert = "-";
		}else{ #short insertion
			$insert = lc(substr($sanger, $hpvE, $insert_len)); 
		}
		
		if($insert_len<0){
			if(($hgS-1)-$hpvS+1>=$flank){
				$hpv_seq = substr($sanger, ($hgS-$flank-1), $flank);
			}else{
				$hpv_seq = substr($sanger, $hpvS-1, ($hgS - $hpvS));
			}
			
			if($hgE - ($hpvE+1) + 1 >= $flank){ 
				$hg_seq = uc(substr($sanger, $hpvE, $flank)); 
			}else{ 
				$hg_seq1 = uc(substr($sanger, $hpvE, ($hgE-$hpvE))); 
				if($maps[2] < $maps[1]){ 
					if($break-$hgE-1+$hgS <= $flank - ($hgE-$hpvE+1)){
						$hg_seq2 = uc($human_db->seq($chr, $break+$hgS-1-$hgE, 1));
					}else{
						$hg_seq2 = uc($human_db->seq($chr, $break+$hgS-1-$hgE, ($break-$flank-$hpvE+$hgS)));
					}
				}else{
					$hg_seq2 = uc($human_db->seq($chr, $break+$hgE+1-$hgS, $break+$flank+($hpvE-$hgS)));
				}
				$hg_seq = $hg_seq1.$hg_seq2;
			}
		}else{
			if($hpvE-$hpvS+1>=$flank){
				$hpv_seq = substr($sanger, $hpvE-$flank,$flank);
			}else{
				$hpv_seq = substr($sanger, $hpvS-1, $hpvE-$hpvS+1);
			}
			
			if($hgE-$hgS+1>=$flank){
				$hg_seq = substr($sanger,$hgS-1,$flank);
			}else{
				$hg_seq1 = substr($sanger,$hgS-1,$hgE-$hgS+1);
				if($maps[2] < $maps[1]){
					if($break+$hgS-$hgE -1 <= $flank-($hgE-$hgS+1)){
						$hg_seq2 = uc($human_db->seq($chr,$break-$hgE-1+$hgS,1));
					}else{
						$hg_seq2 = uc($human_db->seq($chr,$break-($hgE-$hgS+1),$break-$flank+1));
					}
				}else{
					$hg_seq2 = uc($human_db->seq($chr,$hgE+1-$hgS+$break,($break+$flank-1)));
				}
				$hg_seq = $hg_seq1.$hg_seq2;
			}
		}
		
		$total_seq = $hpv_seq.$insert.$hg_seq;
		$break = length($hpv_seq);
		$flag = "HPV_HG";
	}else{
		$insert_len = $hpvS - $hgE-1;
		
		if($insert_len<0){ #junctional microhomologies
			$insert = uc(substr($sanger, ($hpvS - 1), ($hgE - $hpvS + 1)));
			$insert = ".".$insert.".";
		}elsif($insert_len==0){ #apparent blunt joins
			$insert = "-";
		}else{ #short insertion
			$insert = lc(substr($sanger, $hgE, $insert_len)); 
		}
		
		if($insert_len<0){
			if($hpvE-($hgE+1)+1>=$flank){
				$hpv_seq = substr($sanger,$hgE,$flank);
			}else{
				$hpv_seq = substr($sanger, $hgE, ($hpvE - $hgE));
			}
			
			if($hpvS-1-$hgS+1>=$flank){
				$hg_seq = substr($sanger,$hpvS-$flank-1,$flank);
			}else{
				$hg_seq2 = substr($sanger,$hgS-1,$hpvS-1-$hgS+1);
				if($maps[2]<$maps[1]){
					$hg_seq1 = uc($human_db->seq($chr,($break+$flank+$hgE-$hpvS),($break+($hgE-$hgS+1))));
				}else{
					if($break - ($hgE-$hgS+1) <= $flank+$hgS-$hpvS){
						$hg_seq1 = uc($human_db->seq($chr,1,($break - ($hgE-$hgS+1))));
					}else{
						$hg_seq1 = uc($human_db->seq($chr,($break-$flank-$hgE+$hpvS),($break - ($hgE-$hgS+1))));
					}
				}
				$hg_seq = $hg_seq1.$hg_seq2;
			}
		}else{
			if($hpvE-$hpvS+1>=$flank){
				$hpv_seq = substr($sanger,$hpvS-1,$flank);
			}else{
				$hpv_seq = substr($sanger,$hpvS-1,$hpvE - $hpvS + 1);
			}
			
			if($hgE-$hgS+1>=$flank){
				$hg_seq = substr($sanger,($hgE-$flank),$flank);
			}else{
				$hg_seq2 = substr($sanger,($hgS-1),($hgE-$hgS+1));
				if($maps[2]<$maps[1]){
					$hg_seq1 = uc($human_db->seq($chr,($break+$flank-1),($break+$hgE-$hgS+1)));
				}else{
					if($break-($hgE-$hgS+1)<=$flank-($hgE-$hgS+1)){
						$hg_seq1 = uc($human_db->seq($chr,1,$break-($hgE-$hgS+1)));
					}else{
						$hg_seq1 = uc($human_db->seq($chr,($break-$flank+1),($break-($hgE-$hgS+1))));
					}
				}
				$hg_seq = $hg_seq1.$hg_seq2;
			}
		}

		$total_seq = $hg_seq.$insert.$hpv_seq;
		$break = length($hg_seq); 
		$flag = "HG_HPV";
	}

	print OUT "$id\t",$break,"\t",$insert_len,"\t$flag\t$total_seq\n";
	$sanger = "";
	$idflag = 0;
}

close FILE;
close OUT;

## help_text - Returns usage syntax and documentation ##

sub help_text {
	return <<HELP;

flanking_seq.pl - Script to get the flanking sequence around the break site

SYNOPSIS
perl flanking_seq.pl -b <breakresult> -g <fa> -f <flank> -s <fqdir or fafile> -o <output file>

OPTIONS
-b Break result from 
-g Human genome
-f The length of flanking sequence around the break site
-s A directory or a fasta file contians the sanger sequences or assembled sequences
-o Output file name
-h Show this message

DESCRIPTION
This is a command-line interface to flanking_seq.pl

AUTHOURS
Hu Zheng <lt>email<gt>

HELP
}