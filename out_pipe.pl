#!/Database/Software/perl-5.30.1/bin/perl

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
my $sge = $hash_config{sge};
my $threads = $hash_config{threads};
my $maxvmem = $hash_config{maxvmem};
my $EBV = $hash_config{EBV};
my $mem = $hash_config{mem};
my $flanking = $hash_config{flanking};
my $picard = $hash_config{picard};

if(-e "$hash_config{output_path}/4_run_all_pipe.sh"){
	open PIPE_RUN, '>>', "$hash_config{output_path}/4_run_all_pipe.sh" or die $!;
}else{
	open PIPE_RUN, '>', "$hash_config{output_path}/4_run_all_pipe.sh" or die $!;
	print PIPE_RUN "#!/bin/bash\n\n";
}

my @array = split(/;/, $hash_config{virus_ref_type});
foreach my $virus_ref_type(@array){
	my $output_path1 = "$output_path/$virus_ref_type";
	`mkdir -p $output_path1`;
	`mkdir -p $output_path1/oneend`;
	`mkdir -p $output_path1/softclip`;
	`mkdir -p $output_path1/discordant`;
	`mkdir -p $output_path1/summary`;
	`mkdir -p $output_path1/tmp`;

	open SH, '>', "$output_path1/all.sh" or die $1;
	open SH_1, '>', "$output_path1/b_align.$virus_ref_type.sh" or die $!;
	open SH_2, '>', "$output_path1/c_deal.$virus_ref_type.sh" or die $!;
	open SH_3, '>', "$output_path1/d_assemble.$virus_ref_type.sh" or die $!;
	open SH_4, '>', "$output_path1/e_sdej.sh" or die $!;
	open SH_5, '>', "$output_path1/f_mh.sh" or die $!;
	open SH_6, '>', "$output_path1/g_clear.sh" or die $!;
	
	if($sge eq "True"){
		print PIPE_RUN "sleep 3s\n";
		print PIPE_RUN "qsub -cwd -q all.q -l vf=$maxvmem,p=$threads  $output_path1/all.sh\n";
	}else{
		print PIPE_RUN "nohup sh $output_path1/all.sh >>$sample.$virus_ref_type.pipe.log &\n";
	}
	
	print SH "#!/bin/bash\n\nexport PATH=\$PATH:/Database/GWAS/local/bin\n\n";
	print SH_1 "#!/bin/bash\n\n";
	print SH_2 "#!/bin/bash\n\n";
	print SH_3 "#!/bin/bash\n\n";
	print SH_4 "#!/bin/bash\n\n";
	
	# 1_align.sh
	print SH_1 "cd $output_path1\n";
	print SH_1 "bwa mem -t $threads -M $hash_config{bwa_ref_hsa} $hash_config{input_path}/$fq1 $hash_config{input_path}/$fq2 > ${sample}.hsa.sam\n";
	print SH_1 "bwa mem -t $threads -M $hash_config{bwa_ref_virus}/$virus_ref_type.fa $hash_config{input_path}/$fq1 $hash_config{input_path}/$fq2 > ${sample}.virus.sam\n";
	print SH_1 "bwa mem -t $threads -M $hash_config{bwa_ref_merge}/${hsa_ref_type}_${virus_ref_type}.fa $hash_config{input_path}/$fq1 $hash_config{input_path}/$fq2 | samtools view -bS - > ${sample}.bam\n";
	print SH_1 "samtools sort -o ${sample}.sorted.bam -@ $threads -m $mem ${sample}.bam\n";
	print SH_1 "java -Xmx10G -jar $picard MarkDuplicates TMP_DIR=./tmp CREATE_INDEX=true INPUT=${sample}.sorted.bam OUTPUT=${sample}.dedup.bam M=${sample}.metrics REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=LENIENT MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=4000 ASSUME_SORT_ORDER=coordinate\n";
	print SH_1 "samtools view -@ $threads ${sample}.dedup.bam | sort -k 1 -T $output_path1/tmp > ${sample}.dedup.sam\n";
	print SH_1 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/out_dedup.pl $sample\n";
	print SH_1 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/uniq_map.pl $sample\n";
	close SH_1;
	
	#2_deal.sh
	print SH_2 "cd $output_path1\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/filter_sam.pl $sample\n";
	print SH_2 "cd oneend\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/deal_oneend.pl $sample\n";
	print SH_2 "cat normal.hsa.sam left.hsa.sam > oneend.hsa.sam\n";
	print SH_2 "cat normal.virus.sam left.virus.sam > oneend.virus.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/extract_oneend_fa.pl hsa\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/extract_oneend_fa.pl virus\n";
	print SH_2 "/Bigdata/xuwei/local/app/anaconda3/bin/blastn -num_threads 8 -query oneend.hsa.fa -db $hash_config{blast_ref_hsa} -num_descriptions 1 -num_alignments 1 -max_hsps 1 > blast_oneend.hsa.txt\n";
	print SH_2 "/Bigdata/xuwei/local/app/anaconda3/bin/blastn -num_threads 8 -query oneend.virus.fa -db $hash_config{blast_ref_virus}/$virus_ref_type.fa -num_descriptions 1 -num_alignments 1 -max_hsps 1 > blast_oneend.virus.txt\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_parser_new.pl -tophit 1 -topmatch 1 blast_oneend.hsa.txt > blast_oneend.hsa.tab\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_parser_new.pl -tophit 1 -topmatch 1 blast_oneend.virus.txt > blast_oneend.virus.tab\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_filter.pl blast_oneend.hsa.tab blast_oneend.virus.tab oneend.hsa.sam > filter.oneend.hsa.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_filter.pl blast_oneend.hsa.tab blast_oneend.virus.tab oneend.virus.sam > filter.oneend.virus.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site.pl filter.oneend.hsa.sam filter.oneend.site.hsa.xls\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site.pl filter.oneend.virus.sam filter.oneend.site.virus.xls\n";
	print SH_2 "cd ../softclip\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/filter_softclip.pl $sample\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/extract_softclip_seq.pl $sample $fq1 $fq2 $hash_config{input_path} $hash_config{suffix}\n";
	print SH_2 "bwa pemerge -m -T 5 softclip_${sample}_1.fq softclip_${sample}_2.fq > softclip_pemerge_$sample.fq\n";
	print SH_2 "bwa mem -t 8 $hash_config{bwa_ref_merge}/${hsa_ref_type}_${virus_ref_type}.fa softclip_pemerge_$sample.fq > softclip_pemerge_$sample.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/deal_pemerge_sam.pl $sample\n";
	print SH_2 'awk \'{print ">"$1" "$3"_"$4"\n"$10}\' '."softclip_pemerge_$sample.site.hsa.sam > softclip.fa\n";
	print SH_2 "/Bigdata/xuwei/local/app/anaconda3/bin/blastn -num_threads 8 -query softclip.fa -db $hash_config{blast_ref_hsa} -num_descriptions 1 -num_alignments 1 -max_hsps 1 > blast_softclip.hsa.txt\n";
	print SH_2 "/Bigdata/xuwei/local/app/anaconda3/bin/blastn -num_threads 8 -query softclip.fa -db $hash_config{blast_ref_virus}/$virus_ref_type.fa -num_descriptions 1 -num_alignments 1 -max_hsps 1 > blast_softclip.virus.txt\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_parser_new.pl -tophit 1 -topmatch 1 blast_softclip.hsa.txt > blast_softclip.hsa.tab\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_parser_new.pl -tophit 1 -topmatch 1 blast_softclip.virus.txt > blast_softclip.virus.tab\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_filter.pl blast_softclip.hsa.tab blast_softclip.virus.tab softclip_pemerge_$sample.site.hsa.sam > filter.softclip_pemerge_$sample.site.hsa.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/blast_filter.pl blast_softclip.hsa.tab blast_softclip.virus.tab softclip_pemerge_$sample.site.virus.sam > filter.softclip_pemerge_$sample.site.virus.sam\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site.pl filter.softclip_pemerge_$sample.site.hsa.sam filter.softclip_pemerge_$sample.site.hsa.xls\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site.pl filter.softclip_pemerge_$sample.site.virus.sam filter.softclip_pemerge_$sample.site.virus.xls\n";
	print SH_2 "cd ../summary\n";
	print SH_2 "cat ../oneend/filter.oneend.site.hsa.xls ../softclip/filter.softclip_pemerge_$sample.site.hsa.xls > hsa.site.xls\n";
	print SH_2 "cat ../oneend/filter.oneend.site.virus.xls ../softclip/filter.softclip_pemerge_$sample.site.virus.xls > virus.site.xls\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site_stat.pl hsa.site.xls hsa.stat.xls\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/merge.pl\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/site_stat.pl merge.hsa.site.xls merge.hsa.stat.xls\n";
	print SH_2 'awk \'f==1{arr[$1]=$2"\t"$3} f==2{print $0"\t"arr[$1]}\' f=1 virus.site.xls f=2 merge.hsa.site.xls > merge.hsa_virus.site.xls'."\n";
	print SH_2 'cut -f 1,2 merge.hsa.stat.xls | awk -F\'\t\' -vOFS=\'\t\'  \'NR>1{print $1,$2,$2,"0\t0"}\' > merge.annovar'."\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/annotate_variation.pl -buildver $hash_config{hsa_ref_type} -out integration.gene -neargene 10000 merge.annovar $pipe_path/humandb\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/edit_hsa_virus.site.pl\n";
	print SH_2 "awk -F\'\\t\' -vOFS=\'\\t\'  \'f==1{arr[\$3\"\\t\"\$4]=\$1\"\\t\"\$2} f==2&&FNR==1{print \"Annotation\\tGene\\thsa_chr\\thsa_pos\\thsa_num\\tvirus_pos\\tvirus_num\\tvirus_type\"} f==2&&FNR>1&&/^chr/{print arr[\$1\"\\t\"\$2]\"\\t\"\$0\"\\t$virus_ref_type\"} f==2&&FNR>1&&!/^chr/{print \"\\t\\t\"\$0\"\\t$virus_ref_type\"}\' f=1 integration.gene.variant_function f=2 merge.edit_hsa_virus.site.xls > annot.merge.xls"."\n";
	print SH_2 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/pick_sam.pl $sample\n";
	close SH_2;

	#3_assemble.sh
	print SH_3 "cd $output_path1/summary\n";
	print SH_3 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/get_softclip_seq.pl $hash_config{blast_ref_hsa} $hash_config{blast_ref_virus}/$virus_ref_type $flanking $EBV\n";
	close SH_3;
	
	#4_SDEJ.sh
	print SH_4 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/flanking_seq.pl -b blast.filter.txt -g $hash_config{blast_ref_hsa} -s all.fa -f $flanking -o flank.$flanking.txt\n";
	print SH_4 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/sdmmej_classification.pl -s flank.$flanking.txt -o flank.$flanking.html\n";
	
	#5_MH.sh
	print SH_5 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/Get_MHseq.pl -h $hash_config{blast_ref_hsa} -v $hash_config{blast_ref_virus}/$virus_ref_type.fa -m all.fa -i blast.filter.txt > mh.info.seq\n";
	print SH_5 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/changeMH.pl mh.info.seq >50bp.info\n";
	print SH_5 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/MHs2.pl 50bp.info ./\n";
	print SH_5 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/changeMH2html.pl blast_filter.txt mh.info.seq 10.mh.txt mh.info.html\n";
	
	#6_clear.sh
	print SH_6 "cd $output_path1\n";
	print SH_6 "rm -f pre/$sample.sam\n";
	print SH_6 "rm -f $sample.sorted.bam  $sample.dedup.bam $sample.dedup.sam\n";
	print SH_6 "rm -f oneend/blast_oneend.hsa.txt oneend/blast_oneend.virus.txt softclip/blast_softclip.hsa.txt softclip/blast_softclip.virus.txt\n";
	print SH_6 "rm -f $sample.dedup.sam $sample.hsa.dedup.sam $sample.virus.dedup.sam $sample.hsa.dedup.uniq.sam $sample.virus.dedup.uniq.sam\n";
	close SH_6;
	
	print SH "sh $output_path1/b_align.$virus_ref_type.sh\n";
	print SH "sh $output_path1/c_deal.$virus_ref_type.sh\n";
	print SH "sh $output_path1/d_assemble.$virus_ref_type.sh\n";
	print SH "#sh $output_path1/e_clear.sh\n";
	close SH;
}
close PIPE_RUN;
