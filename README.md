# VIPA
# 0
The users should install the packages used in perl and python programs,such as Pod::Usage,Getopt::Long,File::Spec,Cwd,Data::Dumper,List::Util,Bio::DB::Fasta,Bio::Seq,etc.  
VIPA process used in the software has a perl,python,fqtools.sh,trimmmatic.sh,bwa,samtools,java,blastn,muscle,cons  
# 1.install
Download all the files into one folder

# 2.Prepare the fq.gz file

Create a rawdata directory to hold fq.gz files

# 3.VIPA pipeline

## 3.1 cleandata
Go to the RAWDATA directory and run the following commands step-by-step
```
ls *.gz|awk '{print $0}'|awk -F '_' '{print ""$1""}'|sort -u >sample.txt
mkdir -p clean unpaired
cat sample.txt|awk '{print "nohup sh trimmomatic.sh "$1" >>"$1".log &"}' >run_trimmomatic.sh
cat sample.txt|awk '{print "nohup sh fqtools.sh "$1" >>"$1".log &"}' >run_fqtools.sh
sh run_trimmomatic.sh &
sh run_fqtools.sh
```
## 3.2 prepare file
```mkdir -p ../results```  
Go to the Results directory and prepare the configuration file config.txt  
Run the command: ```perl prepare.pl-c config.txt ```
#### Description of config.txt file
- raw_data_path:Cleandata path
- result_path:Results the path
- sample_suffix:The suffix of data such as _R data should be in the format _R1.fq.gz or _ data should be in the format _1.fq.gz
- ref_merge:Path to the merged fasta of human and viruses
- bwa_ref_path:bwa reference pathway
- blast_ref_path:blast reference pathway
- hsa_ref_type:human reference versions
- suffix:The suffix format for data is _R1.fastq.gz,_1. Fastq.gz, _R1.fq.gz,_1. Fq.gz
- layout:Read mode and lengthes, e.g. SE100, PE150
- threads:Number of threads required
- sge:job bathch submission requirenment
- maxvmem:The maxvmem states  the node/queue combination can present as the maximum available virtual memory
- mem:the memory requirenment for each thread of bwa software
- type:sequence type
- method:if the library method is based on PCR amplificaion which does no remove duplilcaiton, fill in MIP. Otherwise, fill in RCA, which will remove duplilcaiton after mapping step.
- EBV:Select true or False, the default is False,When false is selected, the shell script will be delivered nohup, and when true, the shell script will be delivered qsub
- mode:multi	multi will generate virus subtypes' integrations, dominate only generate the top one virus subtype's integrations
- depth:The lowest depth for virus detection
- coverage:The lowest coverage for virus detection
- readcounts:The lowest readcounts for virus detection
- readsupport:The lowest readsupport for virus integration sites
- flanking:The flanking lengthes of human-viral junction sequences for integration pattern calculatuions
- picard:The path to the picard jar software
## 3.3 A Step-to-step protocol of the VIPA pipeline

Then 1_out_all_pre.sh 2_run_all_pre.sh 3_out_all_pipe.sh and 5_work.sh are generated in the current directory  
The sh scripts 1 through 5 are executed in order, with 4_run_all_pipe.sh being generated after 3_out_all_pipe.sh is executed  
```
sh 1_out_all_pre.sh  
sh 2_run_all_pre.sh  
sh 3_out_all_pipe.sh  
sh 4_run_all_pipe.sh  
sh 5_work.sh  
```
### The main running contents of the first four steps
- 1_out_all_pre.sh  
perl pre_pipe.pl /results/\*/pre.config    ####  generate a_pre.sh
- 2_run_all_pre.sh  
sh /results/\*/a_pre.sh                    ####  Execute a_pre.sh in each sample file and the generated files are stored in results/\*/pre
- 3_out_all_pipe.sh  
perl out_pipe.pl /results/\*/pipe.config   ####  generate all.sh
- 4_run_all_pipe.sh  
sh /result/\*/hpv*/all.sh                  ####  Execute all.sh in the files where the HPV samples exist in each sample file For example the 168/hpv16/all.sh. The generated files are stored in the same directory as all.sh
- all.sh  
  - sh b_align.sh  
  - sh c_deal.sh  
  - sh d_assemble.sh  
  - sh e_sdej.sh  
  - sh f_mh.sh  

## 3.4 statistic
```
perl stat_breakpoints.pl  
cd ../rawdata  
perl data_stat.pl $PWD sample.txt data.stat.xls  
cd ../results  
head */pre/stat.xls|sed ':t;N;s#/pre/stat.xls <==\n#\t#;b t'|sed 's/==> //'|sed '/^$/d'|sed 's/^hpv/\thpv/' >stat.xls  
ls */pre/*metrics|while read l;do a=${l%%/*};echo -ne "\n$a\t";grep "Unknown" $l|awk -F'\t' '{printf $7}';done >dedup.stat  
head */pre/dedup.coverage|sed ':t;N;s#/pre/dedup.coverage <==\n#\t#;b t'|sed 's/==> //'|sed '/^$/d'|sed 's/^hpv/\thpv/' >dedup.coverage  

```
## 3.5 Result file and the format descript
### The path of the files of final results:    
The file of data_stat: rawdata/data_stat.xls  
The file of stat:results/stat.xls  
The file of dedup.coverage:results/dedup.coverage  
The file of break_stat:results/break_stat.xls  
The file of all_stat: results/out.xls  

### Format description of the data_stat.xls  
1st column is the sample id  
2nd column is the Raw reads  
3rd column is the Raw bases  
4th column is the Raw Q20  
5th column is the Raw Q30  
6th column is the Clean reads  
7th column is the Clean bases  
8th column is the Clean ratio  
9th column is the Clean Q20  
10th column is the Clean Q30  

Format description of the stat.xls  
1th column is the HPV type  
2nd column is the  
3rd column is the reads that only mapped to human references  
4th column is the pecentage of reads that only mapped to human references 
5th column is the unmapped reads  
6th column is the pecentage of unmapped reads
7th column is the HPV reads  
8th column is the HPV reads  
9th column is the HPV depth  
10th column is the HPV mapping coverage of depeth over 1X
11th column is the HPV mapping coverage of depeth over 4X 
12th column is the HPV mapping coverage of depeth over 10X  
13th column is the HPV ratio  

### Format description of the dedup.coverage  
1th column is the sample id  
2nd column is the HPV type
3rd column is the Unique reads  
4th column is the reads that only mapped to human references   
5th column is the pecentage of reads that only mapped to human references  
6th column is the unmapped reads  
7th column is the pecentage of unmapped reads  
8th column is the HPV reads  
9th column is the HPV depth  
10th column is the HPV mapping coverage of depeth over 1X  
11th column is the HPV mapping coverage of depeth over 4X  
12th column is the HPV mapping coverage of depeth over 10X  
13th column is the HPV mapping coverage of depeth over 30X  
14th column is the HPV mapping coverage of depeth over 500X  
15th column is the HPV mapping coverage of depeth over 1000X  
16th column is the HPV mapping coverage of depeth over 2000X  
17th column is the HPV mapping coverage of depeth over 5000X  
18th column is the homogeneity  
19th column is the Capture efficiency  

### Format description of the break_stat.xls  
1th column is the sampleid_hpv type  
2nd column is the HPV break points    
3rd column is the HPV reads  
