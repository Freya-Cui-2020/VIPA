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
        $hash_config{$1} = $2;
    }
}
$hash_config{sample_suffix} = '' unless exists $hash_config{sample_suffix};
my $sample = $hash_config{sample};
my $output_path = "$hash_config{output_path}/$hash_config{sample}";
my $pipe_path = $hash_config{pipe_path};
my $fq1 = "$sample$hash_config{sample_suffix}1.$hash_config{suffix}";
my $fq2 = "$sample$hash_config{sample_suffix}2.$hash_config{suffix}";
my $picard = $hash_config{picard};
my $threads = $hash_config{threads};
my $method = $hash_config{method};
my $EBV = $hash_config{EBV};
my $mem = $hash_config{mem};
my $mode = $hash_config{mode};
my $depth = $hash_config{depth};
my $coverage = $hash_config{coverage};
my $readcounts = $hash_config{readcounts};
my $flanking = $hash_config{flanking};
`mkdir -p $output_path`;
`mkdir -p $output_path/pre`;

open SH_0, '>', "$output_path/a_pre.sh" or die $!;
print SH_0 "#!/bin/bash\nexport LANG=\"C\"\n\nexport PATH=\$PATH:/Database/GWAS/local/bin\n\n";

#1_align.sh
print SH_0 "cd $output_path/pre\n";
print SH_0 "bwa mem -t $threads -M $hash_config{ref_merge} $hash_config{input_path}/$fq1 $hash_config{input_path}/$fq2 > ${sample}.sam\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/stat_type_distribution.pl $sample $mode $depth $coverage $readcounts $EBV\n";
print SH_0 'awk \'{arr[$1]+=$7;sum+=$7} END{for (i in arr) {print i"\t"arr[i]"\t"arr[i]/sum}}\' '."stat.xls | sort -r -n -k 2 > sort.stat.xls\n\n";
print SH_0 "samtools view -bS -o ${sample}.pick.bam ${sample}.pick.sam\n";
print SH_0 "samtools sort -@ $threads -m $mem -o ${sample}.sort.pick.bam ${sample}.pick.bam\n";
print SH_0 "samtools index ${sample}.sort.pick.bam\n";
print SH_0 "for i in `cut -f 1 sort.stat.xls`;do samtools depth -m 0 -aa -r \$i ${sample}.sort.pick.bam >$sample.virus.\$i.sort.depth;done\n";

print SH_0 "samtools view -bS ${sample}.sam >${sample}.bam\n";
print SH_0 "samtools sort -@ $threads -m $mem -o ${sample}.sorted.bam ${sample}.bam\n";

print SH_0 "samtools depth -b $pipe_path/gene_hg38.bed ${sample}.sorted.bam > ${sample}.depth\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/add_0_in_bed.pl ${sample}\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/depth_SD_exon.pl ${sample}\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/virus_copy_number.pl ${sample}\n\n";
print SH_0 "#sambamba markdup -r -t $threads --tmpdir=./tmp ${sample}.bam ${sample}.dedup.bam\n";
print SH_0 "java -Xmx10G -jar $picard MarkDuplicates TMP_DIR=./tmp CREATE_INDEX=true INPUT=${sample}.sorted.bam OUTPUT=${sample}.dedup.bam M=${sample}.metrics REMOVE_DUPLICATES=true VALIDATION_STRINGENCY=LENIENT MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=4000 ASSUME_SORT_ORDER=coordinate\n";
print SH_0 "samtools view -@ $threads -h ${sample}.dedup.bam >${sample}.dedup.sam\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/stat_type_distribution_dedup.pl $sample.dedup $mode $depth $coverage $readcounts $EBV\n";
print SH_0 'awk \'{arr[$1]+=$7;sum+=$7} END{for (i in arr) {print i"\t"arr[i]"\t"arr[i]/sum}}\' '."dedup.stat.xls | sort -r -n -k 2 > dedup.sort.stat.xls\n\n";
print SH_0 "samtools view -bS -o ${sample}.dedup.pick.bam ${sample}.dedup.pick.sam\n";
print SH_0 "samtools sort -@ $threads -m $mem -o ${sample}.sort.dedup.pick.bam ${sample}.dedup.pick.bam\n";
print SH_0 "samtools index ${sample}.sort.dedup.pick.bam\n";
print SH_0 "for i in `cut -f 1 dedup.sort.stat.xls`;do samtools depth -m 0 -aa -r \$i ${sample}.sort.dedup.pick.bam >$sample.virus.\$i.dedup.depth;done\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=1{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >1X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=4{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >4X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=10{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >10X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=30{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >30X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=500{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >500X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=1000{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >1000X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=2000{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >2000X.coverage\n";
print SH_0 "for i in `cut -f 1 dedup.stat.xls`;do awk '\$3>=5000{sum++}END{print sum/NR*100}' $sample.virus.\$i.dedup.depth;done >5000X.coverage\n";
print SH_0 "paste dedup.stat.xls 1X.coverage 4X.coverage 10X.coverage 30X.coverage 500X.coverage 1000X.coverage 2000X.coverage 5000X.coverage|awk -F \"\\t\" '{OFS=\"\\t\"; print \$1,\$2,\$3,\$4,\$5,\$6,\$7,\$9,\$14,\$15,\$16,\$17,\$18,\$19,\$20,\$21,\$11,\$13}' >dedup.coverage\n";

print SH_0 "samtools sort -@ $threads -m $mem -o ${sample}.dedup.sorted.bam ${sample}.dedup.bam\n";
print SH_0 "samtools depth -b $pipe_path/gene_hg38.bed ${sample}.dedup.sorted.bam > ${sample}.dedup.depth\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/add_0_in_bed.pl ${sample}.dedup\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/depth_SD_exon.pl ${sample}.dedup\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/virus_copy_number.pl ${sample}.dedup\n\n";
print SH_0 "/Database/Software/perl-5.30.1/bin/perl $pipe_path/config.pl $config\n\n";
print SH_0 'echo "========================job finished!========================"'."\n";
close SH_0;
