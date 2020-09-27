#!/usr/bin/perl -w
use strict;

my ($blast, $all, $mh, $html) = @ARGV;

my %hash_blast = ();
open BLAST, "$blast";
while(<BLAST>){
	next if /^Sam/;
	my $id = (split /\t/)[0];
	$id =~ s/^>//;
	$hash_blast{$id} = $_;
}
close BLAST;

my %hash = ();
open MH, "$mh";
while(<MH>){
	chomp;
	my ($id, $s, $l, $seq) = split /\t/;
	$id =~ s/^>//;
	$hash{$id}{$_} = 1;
}
close MH;

my %hash_break = ();
my %hash_dis = ();
foreach my $id (keys %hash){
	foreach my $info (keys %{$hash{$id}}){
		my ($s, $l, $seq) = (split(/\t/, $info))[1,2,3];
		if($s<100){
			my $d = 100-($s+$l);
			if(!$hash_dis{$id}){
				$hash_dis{$id} = $d;
				$hash_break{$id} = $info;
			}else{
				if($d < $hash_dis{$id}){
					$hash_dis{$id} = $d;
					$hash_break{$id} = $info;
				}elsif($d == $hash_dis{$id}){
					$hash_break{$id} .= ";".$info;
				}
			}
		}elsif($s>100){
			my $d = $s-(100+1);
			if(!$hash_dis{$id}){
				$hash_dis{$id} = $d;
				$hash_break{$id} = $info;
			}else{
				if($d < $hash_dis{$id}){
					$hash_dis{$id} = $d;
					$hash_break{$id} = $info;
				}elsif($d == $hash_dis{$id}){
					$hash_break{$id} .= ";".$info;
				}
			}
		}
	}
}

open ALL, "$all";
open HTML, ">$html";
print HTML '<HTML>
<BODY BGCOLOR="#FFFFFF">
<PRE>
';
my $name = "";
my $human = "";
my $hpv = "";
my @mhs = ();
while(<ALL>){
	chomp;
	if($_ =~ />(\S+)/){
		$name = $1;
		print HTML "$_
";
		my ($hpv_start, $hsa_start) = (split(/\t/,$hash_blast{$name}))[1,4];
		if($hpv_start <= $hsa_start){
			$human = "R";
			$hpv = "L";
		}else{
			$human = "L";
			$hpv = "R";
		}
		
		@mhs = ();
		
		if(!$hash_break{$name}){
			next;
		}
		
		my @all_mhs = split(/;/,$hash_break{$name});
		my ($fs, $fe) = (0,0);
		foreach my $each_mh (@all_mhs){
			my ($s, $l) = (split(/\t/,$each_mh))[1,2];
			if($s<100){
				$fs=$s;
				$fe=$s+$l-1;
			}elsif($s>=100){
				$fs=$s;
				$fe=$s+$l-1;
			}
			for (my $i = 10+$fs; $i<=10+$fe; $i++){
				push @mhs, $i;
			}
		}
	}elsif($_ =~ /^Human/){
		my %hash_color = ();
		my $total_len = length($_);
		for (my $i=0;$i<10;$i++){
			$hash_color{$i} = "no";
		}
		if($human eq "L"){
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "green";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "no";
			}
		}else{
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "no";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "green";
			}
		}
		foreach my $i(@mhs){
			$hash_color{$i} = "red";
		}
		
		my $old_color = "";
		my $start = 0;
		my $len = 0;
		my $seQ = "";
		for(my $i=0; $i<=$total_len; $i++){
			my $color = $hash_color{$i};
			if($old_color eq ""){
				$len =1;
				$old_color = $color;
			}else{
				if($color ne $old_color){
					$seQ = substr($_, $start, $len);
					if($old_color eq "no"){
						print HTML "$seQ";
					}else{
						print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
					}
					$old_color = $color;
					$start += $len;
					$len = 1;
				}else{
					$len += 1;
				}
			}
		}
		$seQ = substr($_, $start, $len);
		if($old_color eq "no"){
			print HTML "$seQ";
		}else{
			print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
		}
		print HTML "\n";
	}elsif($_ =~ /^IS/){
		my %hash_color = ();
		my $total_len = length($_);
		for (my $i=0;$i<10;$i++){
			$hash_color{$i} = "no";
		}
		if($human eq "L"){
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "green";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "yellow";
			}
		}else{
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "yellow";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "green";
			}
		}
		foreach my $i(@mhs){
			$hash_color{$i} = "red";
		}
		
		my $old_color = "";
		my $start = 0;
		my $len = 0;
		my $seQ = "";
		for(my $i=0; $i<=$total_len; $i++){
			my $color = $hash_color{$i};
			if($old_color eq ""){
				$len =1;
				$old_color = $color;
			}else{
				if($color ne $old_color){
					$seQ = substr($_, $start, $len);
					if($old_color eq "no"){
						print HTML "$seQ";
					}else{
						print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
					}
					$old_color = $color;
					$start += $len;
					$len = 1;
				}else{
					$len += 1;
				}
			}
		}
		$seQ = substr($_, $start, $len);
		if($old_color eq "no"){
			print HTML "$seQ";
		}else{
			print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
		}
		print HTML "\n";
	}elsif($_ =~ /^HPV/){
		my %hash_color = ();
		my $total_len = length($_);
		for (my $i=0;$i<10;$i++){
			$hash_color{$i} = "no";
		}
		if($human eq "L"){
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "no";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "yellow";
			}
		}else{
			for (my $i=10; $i<110; $i++){
				$hash_color{$i} = "yellow";
			}
			$hash_color{110} = "no"; ## |
			for (my $i=111; $i<=$total_len; $i++){
				$hash_color{$i} = "no";
			}
		}
		foreach my $i(@mhs){
			$hash_color{$i} = "red";
		}
		
		my $old_color = "";
		my $start = 0;
		my $len = 0;
		my $seQ = "";
		for(my $i=0; $i<=$total_len; $i++){
			my $color = $hash_color{$i};
			if($old_color eq ""){
				$len =1;
				$old_color = $color;
			}else{
				if($color ne $old_color){
					$seQ = substr($_, $start, $len);
					if($old_color eq "no"){
						print HTML "$seQ";
					}else{
						print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
					}
					$old_color = $color;
					$start += $len;
					$len = 1;
				}else{
					$len += 1;
				}
			}
		}
		$seQ = substr($_, $start, $len);
		if($old_color eq "no"){
			print HTML "$seQ";
		}else{
			print HTML "<span style=\"background-color: $old_color\">$seQ</span>";
		}
		print HTML "\n";
	}else{
		print HTML "\n";
	}
}

print HTML '</SPAN></PRE>
</BODY>
</HTML>',"\n";
close HTML;