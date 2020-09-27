#!/Database/Software/perl-5.30.1/bin/perl

use warnings;
use strict;
use FindBin qw($Bin);

if (scalar(@ARGV) == 0){
    print help_text();
    exit(0);
}

## mandatory arguments

my $config = "";

## parse command line arguments

while (scalar(@ARGV) > 0){
    my $this_arg = shift @ARGV;
    if($this_arg eq '-h') {print help_text(); exit;}
    elsif ($this_arg eq '-c') {$config = shift @ARGV;}
    elsif ($this_arg =~ m/^-/) {print "unknown flag: $this_arg\n";}
}

if($config eq ""){
    die "you should specify the config file\n";
}

#################################
# read the config file provided #
#################################

open CONFIG, "$config" || die "can not open file: $config\n$!\n";

my $raw_data_path = "";
my $result_path = "";
my $sample_suffix = "";
my $ref_merge = "";
my $bwa_ref_path = "";
my $blast_ref_path = "";
my $pipe_path = $Bin;
my $hsa_ref_type = "";
my $suffix = "";
my $layout = "";
my $threads = "";
my $sge = "";
my $maxvmem = "";
my $mem = "";
my $type = "";
my $method = "";
my $EBV = "";
my $picard = "";
my $mode = "";
my $depth = "";
my $coverage = "";
my $readcounts = "";
my $readsupport = "";
my $flanking = "";

while(<CONFIG>){
    chomp;
    my @F = split(/\=/, $_);
    if($F[0] eq "raw_data_path"){
        $raw_data_path = $F[1];
    }elsif($F[0] eq "result_path"){
        $result_path = $F[1];
    }elsif($F[0] eq "sample_suffix"){
        $sample_suffix = $F[1];
    }elsif($F[0] eq "ref_merge"){
        $ref_merge = $F[1];
    }elsif($F[0] eq "bwa_ref_path"){
        $bwa_ref_path = $F[1];
    }elsif($F[0] eq "blast_ref_path"){
        $blast_ref_path = $F[1];
    }elsif($F[0] eq "hsa_ref_type"){
        $hsa_ref_type = $F[1];
    }elsif($F[0] eq "suffix"){
        $suffix = $F[1];
    }elsif($F[0] eq "layout"){
		$layout = $F[1];
	}elsif($F[0] eq "threads"){
		$threads = $F[1];
	}elsif($F[0] eq "sge"){
		$sge = $F[1];
	}elsif($F[0] eq "maxvmem"){
		$maxvmem = $F[1];
	}elsif($F[0] eq "mem"){
		$mem = $F[1];
	}elsif($F[0] eq "picard"){
        $picard = $F[1];
    }elsif($F[0] eq "type"){
		$type = $F[1];
	}elsif($F[0] eq "method"){
		$method = $F[1];
	}elsif($F[0] eq "EBV"){
		$EBV = $F[1];
	}elsif($F[0] eq "mode"){
		$mode = $F[1];
	}elsif($F[0] eq "depth"){
		$depth = $F[1];
	}elsif($F[0] eq "coverage"){
		$coverage = $F[1];
	}elsif($F[0] eq "readcounts"){
		$readcounts = $F[1];
	}elsif($F[0] eq "readsupport"){
		$readsupport = $F[1];
	}elsif($F[0] eq "flanking"){
		$flanking = $F[1];
	}
}
close CONFIG;

opendir DIR, $raw_data_path or die $!;
open PRE_OUT, '>', "$result_path/1_out_all_pre.sh" or die $!;
open PIPE_OUT, '>', "$result_path/3_out_all_pipe.sh" or die $!;
open PRE_RUN, '>', "$result_path/2_run_all_pre.sh" or die $!;

print PRE_OUT "#!/bin/bash\n\n";
print PIPE_OUT "#!/bin/bash\n\n";
print PRE_RUN "#!/bin/bash\n\n";

print PIPE_OUT "[ -e $result_path/4_run_all_pipe.sh ] && rm $result_path/4_run_all_pipe.sh\n\n";

if($type ne "RNA"){
	open WORK, '>', "$result_path/5_work.sh" or die $!;
	print WORK "#!/bin/bash\n\n";
	print WORK "/Database/Software/perl-5.30.1/bin/perl $pipe_path/extract_info_for_MH.pl $result_path $readsupport\n";
	close WORK;
}

for my $file (readdir DIR) {
    if ($file =~ /${sample_suffix}1\.$suffix/) {
        my $sample = (split /_/, $file)[0];
        `mkdir $result_path/$sample`;
        open CFG, '>', "$result_path/$sample/pre.config" or die $!;
        print CFG "sample=$sample\n";
        print CFG "sample_suffix=$sample_suffix\n";
        print CFG "ref_merge=$ref_merge\n";
        print CFG "bwa_ref_path=$bwa_ref_path\n";
        print CFG "blast_ref_path=$blast_ref_path\n";
        print CFG "input_path=$raw_data_path\n";
        print CFG "output_path=$result_path\n";
        print CFG "pipe_path=$pipe_path\n";
        print CFG "hsa_ref_type=$hsa_ref_type\n";
        print CFG "suffix=$suffix\n";
        print CFG "layout=$layout\n";
        print CFG "threads=$threads\n";
		print CFG "sge=$sge\n";
        print CFG "maxvmem=$maxvmem\n";
        print CFG "method=$method\n";
        print CFG "EBV=$EBV\n";
        print CFG "mem=$mem\n";
        print CFG "mode=$mode\n";
		print CFG "depth=$depth\n";
        print CFG "coverage=$coverage\n";
        print CFG "readcounts=$readcounts\n";
		print CFG "flanking=$flanking\n";
        print CFG "picard=$picard\n";
        close CFG;
        print PRE_OUT "/Database/Software/perl-5.30.1/bin/perl $pipe_path/pre_pipe.pl $result_path/$sample/pre.config\n";
		if($sge eq "True"){
			print PRE_RUN "qsub -cwd -q all.q -l vf=$maxvmem,p=$threads $result_path/$sample/a_pre.sh\n";
		}else{
			print PRE_RUN "nohup sh $result_path/$sample/a_pre.sh >>$sample.pre.log &\n";
		}
        
        if($type eq "RNA"){
            print PIPE_OUT "/Database/Software/perl-5.30.1/bin/perl $pipe_path/out_rnaseq.pl $result_path/$sample/pipe.config\n";
        }else{
            print PIPE_OUT "/Database/Software/perl-5.30.1/bin/perl $pipe_path/out_pipe.pl $result_path/$sample/pipe.config\n";
        }
    }
}

close PRE_OUT;
close PIPE_OUT;
close PRE_RUN;


## help_text - Returns usage syntax and documentation ##

sub help_text {
    return <<HELP;

prepare.pl - Script to prepare the scripts to find the break point for the data in the rawdata directory

SYNOPSIS
perl prepare.pl -c <config file>

OPTIONS
-c Config file for the program to run

DESCRIPTION
This is a command-line interface to prepare.pl

AUTHOURS
Wang Jian

HELP
}
