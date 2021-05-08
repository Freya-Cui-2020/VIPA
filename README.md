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
## 3.4 statistic
```
perl stat_breakpoints.pl  
cd ../rawdata  
perl data_stat.pl $PWD sample.txt data.stat.xls  
cd ../results  
head */pre/stat.xls|sed ':t;N;s#/pre/stat.xls <==\n#\t#;b t'|sed 's/==> //'|sed '/^$/d'|sed 's/^hpv/\thpv/' >stat.xls  
ls */pre/*metrics|while read l;do a=${l%%/*};echo -ne "\n$a\t";grep "Unknown" $l|awk -F'\t' '{printf $7}';done >dedup.stat  
head */pre/dedup.coverage|sed ':t;N;s#/pre/dedup.coverage <==\n#\t#;b t'|sed 's/==> //'|sed '/^$/d'|sed 's/^hpv/\thpv/' >dedup.coverage  
sed -i 's?/pre/stat.xls <==??g' stat.xls  
sed -i 's?/pre/dedup.coverage <==??g' dedup.coverage  
python statistics.py ../rawdata/data.stat.xls stat.xls dedup.coverage break_stat.xls out.xls 
```
## 3.5 Result file and the format descript
The path of the files of final results:    
The file of data_stat: rawdata/data_stat.xls  
The file of stat:results/stat.xls  
The file of dedup.coverage:results/dedup.coverage  
The file of break_stat:results/break_stat.xls  
The file of all_stat: results/out.xls  

Format description of the data_stat.xls  
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
2th column is the
3th column is the 只比上人的reads  
4th column is the 只比上人的reads占比  
5th column is the unmapped reads  
6th column is the unmapped reads占比   
7th column is the HPV reads  
8th column is the HPV reads  
9th column is the HPV depth  
10th column is the 
11th column is the 
12th column is the 
13th column is the HPV ratio  

Format description of the dedup.coverage  
1th column is the sample id  
2th column is the HPV type
3th column is the Unique reads  
4th column is the 只比上人的reads  
5th column is the 只比上人的reads占比  
6th column is the unmapped reads  
7th column is the unmapped reads占比  
8th column is the HPV reads  
9th column is the HPV depth  
10th column is the HPV 1X覆盖度  
11th column is the HPV 4X覆盖度  
12th column is the HPV 10X覆盖度  
13th column is the HPV 30X覆盖度  
14th column is the HPV 500X覆盖度  
15th column is the HPV 1000X覆盖度  
16th column is the HPV 2000X覆盖度  
17th column is the HPV 5000X覆盖度  
18th column is the 均一性  
19th column is the 捕获效率  
