# VIPA
1.install
=
Download all the files into one folder

2.Prepare the fq.gz file
=
Create a rawdata directory to hold fq.gz files

3.VIPA pipeline
=

3.1 cleandata
-
Go to the RAWDATA directory and run the following commands step-by-step
ls *.gz|awk '{print $0}'|awk -F '_' '{print ""$1""}'|sort -u >sample.txt
mkdir -p clean unpaired

cat sample.txt|awk '{print "nohup sh trimmomatic.sh "$1" >>"$1".log &"}' >run_trimmomatic.sh
cat sample.txt|awk '{print "nohup sh fqtools.sh "$1" >>"$1".log &"}' >run_fqtools.sh
sh run_trimmomatic.sh &
sh run_fqtools.sh
mkdir -p ../results

3.2 prepare file
-
Go to the Results directory and prepare the configuration file config.txt

3.3 statistic
-
Run the command: perl prepare.pl-c config.txt

Then 1_OUT_ALL_PRER.SH 2_RUN_ALL_PRER.SH 3_OUT_ALL_PIPE. SH and 5_WORK.SH are generated in the current directory
