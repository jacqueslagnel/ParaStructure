#!/usr/bin/perl -w
#jacques revised 10082012
$|++;#IMPORTANT: in order to use print with nohup. Flush the stdout
# or to print imediatly after print, write,... even without \n
#or $| =1;
##

use Time::HiRes qw[gettimeofday tv_interval];
use Scalar::Util qw(looks_like_number);

#--------------- MUST be adapted to the system and should be view by all nodes --------
my $struture_path="/usr/local/bin/structure";
#my $struture_path="/usr/local/bin/structure_2.3.2.1";
my $structure_parse_results_path="/usr/local/bin/structure_parse_results.pl";
my $structure2distruct_path="/usr/local/bin/structure2distruct.pl";
#--------------------------------------------------------------------------------------

#################### pass args #################################
if (($#ARGV+1) != 5 ) {
	print "Run Structure in parallel: nb jobs=k*iterations (on a cluster with queuing system (qsub))\n";
	print "1) Run structure\n";
	print "2) Build statistics csv file\n";
	print "3) Run distruct and produce ps grahics\n";
	print "You must provide:\nthe mainparameters file named:'mainparameters'\nthe data file named:'project_data'\nand optionally the extraparams file named:'extraparams')\n";
	print "\nUsage:$0 <k(min)> <k(max)> <nb of runs>  <keep full raw outputs (y=big files) [y|n]> <Full path of mainparameters and data>\n";
	print "\nThe outputs will be in the '<Full path of mainparameters and data>/structure_ddmmyyyy_HHMMSS_run' folder\n";
	exit 1;
}

#foreach $num (0 .. $#ARGV) {
#	print "arg:$num=$ARGV[$num]\n";
#}

###############################################################

my $min_k=$ARGV[0];
my $max_k=$ARGV[1];
my $max_iter=$ARGV[2];
my $save_full_output=0;
if ($ARGV[3] eq 'y'){$save_full_output=1;}
my $inpath=$ARGV[4];

my $iter=0;
my $k=0;
my $max_run=0;
my $poub="";
my $job_name="";
my $qsub="";
my $redir="";
my $datestr='echo \`date\`';
my @qsubids=();
my $list="";
my $seed=0;

my ($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
$yearOffset=1900 + $yearOffset;
my $datetime=sprintf("%02d%02d%04d_%02d%02d%02d",$dayOfMonth,$month+1,$yearOffset,$hour,$minute,$second);
my $random_number = int(rand(1000)) + 100;

my $file_mainparams="${inpath}/mainparams";
my $file_extraparams="${inpath}/extraparams";
my $file_project_data="${inpath}/project_data";

my $out_path="${inpath}/structure_${datetime}_run";
my $jobs_path="${out_path}/structure_jobs";
my $raw_path="${out_path}/structure_raw_outs";
my $logs_path="${out_path}/structure_logs";
my $struct_out_path="${out_path}/structure_outs";
my $distruct_out_path="${out_path}/distruct_outs";

if ($inpath !~ /^\//){die "We said FULL path for the path of mainparameters and data not: \'$inpath\'\n";}
if (! -e $inpath){die "The path: \'$inpath\' doesn't exist....\n";}

$poub = `rm -fr $out_path`;
$poub = `mkdir -p $out_path`;

$poub = `touch $file_extraparams`;
$poub = `dos2unix $file_mainparams`;
$poub = `dos2unix $file_extraparams`;
$poub = `dos2unix $file_project_data`;

#for jobs
$poub = `rm -fr $jobs_path`;
$poub = `mkdir -p $jobs_path`;

$poub = `rm -fr $raw_path`;
$poub = `mkdir -p $raw_path`;

$poub = `rm -fr $logs_path`;
$poub = `mkdir -p $logs_path`;

$poub = `rm -fr $struct_out_path`;
$poub = `mkdir -p $struct_out_path`;

$poub = `rm -fr $distruct_out_path`;
$poub = `mkdir -p $distruct_out_path`;

if (!-e "$file_mainparams") {die "ERROR: File \"$file_mainparams\" does not exist...\n";}
if (!-e "$file_extraparams") {die "ERROR: File \"$file_extraparams\" does not exist...\n";}
if (!-e "$file_project_data") {die "ERROR: File \"$file_project_data\" does not exist...\n";}

if (!-e "$struture_path") {die "ERROR: File \"$struture_path\" does not exist...\n";}
if (!-e "$structure_parse_results_path") {die "ERROR: File \"$structure_parse_results_path\" does not exist...\n";}
if (!-e "$structure2distruct_path") {die "ERROR: File \"$structure2distruct_path\" does not exist...\n";}

print "preparing: ",($max_k - $min_k + 1)*$max_iter," jobs...\n";
#------------ build commands list ---------------------------------------------------------------------------
$redir="/dev/null";
for($k=$max_k;$k>=$min_k;$k--){
	for($iter=1;$iter<=$max_iter;$iter++){
		$job_name= sprintf("struct_%02d_%02d",$k,$iter);
		if($save_full_output==1){$redir="/tmp/${datetime}_${random_number}_Out_${job_name}";}
		$seed=int(rand(10000000))+10000000;
			$qsub="#!/bin/bash
#PBS -l walltime=48:00:00
#PBS -d ${inpath}
#PBS -N ${job_name}
#PBS -o ${logs_path}/$job_name.pbs.out
#PBS -j oe
#PBS -m n

${datestr}

#$struture_path -D ${seed} -m $file_mainparams -e $file_extraparams -i $file_project_data -K $k -o ${struct_out_path}/$job_name > $redir
$struture_path -m $file_mainparams -e $file_extraparams -i $file_project_data -K $k -o ${struct_out_path}/$job_name > $redir

${datestr}

";
#-- to avoid to much NFS trafic (slow the runs by 2 !!!!)
if($save_full_output==1){
$qsub ="$qsub
echo \"moving the raw data file\"
echo \"mv -f /tmp/${datetime}_${random_number}_Out_${job_name} ${raw_path}/Out_${job_name}\"

mv -f /tmp/${datetime}_${random_number}_Out_${job_name} ${raw_path}/Out_${job_name}
rm -f /tmp/${datetime}_${random_number}_Out_${job_name}
${datestr}

exit 0
";

}else{
$qsub ="$qsub

exit 0
";
}

`echo "${qsub}" >${jobs_path}/qsub_${job_name}.sh`;
`chmod +x ${jobs_path}/qsub_${job_name}.sh`;
select(undef, undef, undef, 0.03);
push(@qsubids,`qsub ${jobs_path}/qsub_${job_name}.sh`);

}
}

for ($x=0;$x<scalar(@qsubids);$x++){
	chomp($qsubids[$x]);
	$qsubids[$x]=~ s/\..*//g;
}
$list="";
my $qf=$qsubids[0];
my $ql=$qsubids[$#qsubids];

foreach my $qsubid(@qsubids){
	$list .=":$qsubid";
	print "qsub job id submitted: $qsubid\n";
}



############### start struct_parse_and_distruct job in queue ###############
############## witing until all structure jobs are finished ################

$qsub="#!/bin/bash
#PBS -d ${inpath}
#PBS -l walltime=1:00:00
#PBS -N struct_parse_and_distruct
#PBS -j oe
#PBS -o ${logs_path}/struct_parse_distruct.pbs.out
# PBS -e ${logs_path}/struct_parse_distruct.pbs.error
#PBS -m n

sleep 5
${datestr}

echo \"building stats with delta K in:${out_path}/structure_statistics.csv\"
$structure_parse_results_path $struct_out_path >${out_path}/structure_statistics.csv
echo
echo \"building graphs with distruct.. in: $distruct_out_path\"
$structure2distruct_path $struct_out_path $distruct_out_path
echo
${datestr}

exit 0
";

`echo "${qsub}" >${jobs_path}/qsub_struct_parse_distruct.sh`;
`chmod +x ${jobs_path}/qsub_struct_parse_distruct.sh`;

print "Starting the parser and distruct job:\nqsub -W depend=\"afterok$list\" ${jobs_path}/qsub_struct_parse_distruct.sh\n";
`qsub -W depend=\"afterok$list\" ${jobs_path}/qsub_struct_parse_distruct.sh`;
#print "for i in {$qf..$ql};do qdel \$i;done\n";

exit 0;

