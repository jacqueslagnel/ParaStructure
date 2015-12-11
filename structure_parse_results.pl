#!/usr/bin/perl -w
#jacques revised 10082012
use Time::HiRes qw[gettimeofday tv_interval];
use Scalar::Util qw(looks_like_number);


my $iter=0;
my $pop=0;
my @names=();
my $filename="";
my $ligne="";

my $max_iter=0;
my $min_pop=0;
my $max_pop=0;
my $path="";

my $prefix="Run_";
my @str_files=();
my %k2file=();
my %k2lnp=();
my %k2lnp_max=();
my %k2mlnp=();
my %k2mlnp_max=();
my %k2varlnp=();
my $val_max=0;
my $kt_max=0;

my %k2ml=();
my %k2varl=();
my %k2lprime=();
my %k2varlprime=();
my %k2lsecond=();
my %k2varlsecond=();
my %k2deltaK=();

my $k=0;
my $k_max=0;
my $k_min=99999999;
my $k_old=0;
my $repeats=0;
my $r=0;

#################### pass args #################################
if (($#ARGV+1) != 1 ) {
	print "usage:$0 <Full path of structure outputs>\n";
	exit 1;
}
###############################################################
$path=$ARGV[0];
#/////////////////////// get files  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#@files = </var/www/htdocs/*.html>;
opendir (MYDIR, "$path") || die ("nodirectory: $path\n");
my @contents = grep !/^\.\.?$/, readdir MYDIR;
closedir MYDIR;
$x=0;
foreach my $listitem ( @contents ){
	if (! -d $listitem ){
		if ($listitem =~ /\_f$/){
			$bls_files[$x]=$listitem;
			$x++;
		}
	}
}
@str_files = sort { $a cmp $b } @bls_files;
#print "found $x results files in $path :\n";
# foreach my $thefile ( @str_files ){
# 	print "$thefile\n";
# }

#///////////////////////////////////////////////////////////////////
$repeats=1;
foreach my $thefile ( @str_files ){
     open (RES, "<$path/$thefile") || die ("nofile R: $path/$thefile\n");
     while ($ligne=<RES>){
	       if($ligne =~ / populations assumed$/){
		    $ligne=~ s/[\n\r]//g;
		    my @splitted=split(/ +/,$ligne);
		    $splitted[1]=~ s/ //g;
		    $k=$splitted[1];
		    if(!looks_like_number($k)){die ("K is not numeric....\n");}
		    if($k!=$k_old){$repeats=1;}
		    $k_old=$k;
		    if($k_min>$k){$k_min=$k;}
		    if($k_max<$k){$k_max=$k;}
		    $k2file{$k}{$repeats}=$thefile;
	       }
	       if($ligne =~ /^Estimated Ln Prob of Data/){
		    $ligne=~ s/[\n\r]//g;
		    my @splitted=split(/=/,$ligne);
		    $splitted[1]=~ s/ //g;
		    if(!looks_like_number($splitted[1])){die ("lnP is not numeric....\n");}
		    $k2lnp{$k}{$repeats}=$splitted[1];
	       }
       	       if($ligne =~ /^Mean value of ln likelihood/){
		    $ligne=~ s/[\n\r]//g;
		    my @splitted=split(/=/,$ligne);
		    $splitted[1]=~ s/ //g;
		    if(!looks_like_number($splitted[1])){die ("Mean value of ln likelihood is not numeric....\n");}
		    $k2mlnp{$k}{$repeats}=$splitted[1];
	       }

	       if($ligne =~ /^Variance of ln likelihood/){
		    $ligne=~ s/[\n\r]//g;
		    my @splitted=split(/=/,$ligne);
		    $splitted[1]=~ s/ //g;
		    if(!looks_like_number($splitted[1])){die ("VarlnP is not numeric....\n");}
		    $k2varlnp{$k}{$repeats}=$splitted[1];
	       }
     }
     close (RES);
     #print "K=$k\tfile=$k2file{$k}{$repeats}\tlnP=$k2lnp{$k}{$repeats}\tvarlnP=$k2varlnp{$k}{$repeats}\n";
     $repeats++;
}
#print "K min=$k_min\tK max=$k_max\n";

###################### based on Ln P(D) #########################################
#-------------- means mL(K) and varL(K)
$k=0;
%k2ml=();
%k2varl=();
%k2lprime=();
%k2varlprime=();
%k2lsecond=();
%k2varlsecond=();
%k2deltaK=();
$val_max=-99999999999999999;
$kt_max=0;

foreach $k (sort { $a <=> $b } keys %k2file){
     $k2ml{$k}=0.0;
     $k2varl{$k}=0.0;
     $r=0;
     $repeats=0;
     foreach $r (sort { $a <=> $b } keys %{$k2lnp{$k}}){
	  #print "k:$k\trep:$r\n";
	  $k2ml{$k} +=$k2lnp{$k}{$r};
	  $k2varl{$k} +=$k2varlnp{$k}{$r};
	  $repeats=$r;
     }
     $k2ml{$k} = $k2ml{$k}/$repeats;
     $k2varl{$k} =$k2varl{$k}/$repeats;
     if($val_max<$k2ml{$k}){
	  $val_max=$k2ml{$k};
	  $kt_max=$k;
     }
}
$k=0;
#------------ L'(K) and var L'(K) from k=min +1 to k=n
for ($k=$k_min+1;$k<=$k_max;$k++){
     $k2lprime{$k} = $k2ml{$k} - $k2ml{$k-1};
     $k2varlprime{$k} = $k2varl{$k} - $k2varl{$k-1};
}
#------------ L"(K) and var L"(K)
for ($k=$k_min+1;$k<$k_max;$k++){
     $k2lsecond{$k} = abs($k2lprime{$k+1} - $k2lprime{$k});
     $k2varlsecond{$k} = abs($k2varlprime{$k+1} - $k2varlprime{$k});
}
#------------ Delta K
for ($k=$k_min+1;$k<$k_max;$k++){
     $k2deltaK{$k} = $k2lsecond{$k} / $k2varl{$k};
}

#------------------- print all ----------------------------------
print "max LnP(D)\tfor K\n";
print "$val_max\t$kt_max\n";
print "K\tmeans L(K)\tmeans var L(K)\tL\'(K)\tvar L\'(K)\tL\"(K)\tvar L\"(K)\tK\tdelta Κ\n";
$k=0;
for ($k=$k_min;$k<=$k_max;$k++){
     print "$k\t$k2ml{$k}\t$k2varl{$k}\t";
     if(exists($k2lprime{$k})){print "$k2lprime{$k}\t$k2varlprime{$k}\t";}else{print "\t\t";}
     if(exists($k2lsecond{$k})){print "$k2lsecond{$k}\t$k2varlsecond{$k}\t";}else{print "\t\t";}
     print "$k\t";
     if(exists($k2deltaK{$k})){print "$k2deltaK{$k}\n";}else{print "\n";}
}
###################### end based on Ln P(D) #########################################

###################### based on mean  ln likelihood #########################################
#-------------- means mL(K) and varL(K)
$k=0;
%k2ml=();
%k2varl=();
%k2lprime=();
%k2varlprime=();
%k2lsecond=();
%k2varlsecond=();
%k2deltaK=();
$val_max=-999999999999999999;
$kt_max=0;

foreach $k (sort { $a <=> $b } keys %k2file){
     $k2ml{$k}=0.0;
     $k2varl{$k}=0.0;
     $r=0;
     $repeats=0;
     foreach $r (sort { $a <=> $b } keys %{$k2mlnp{$k}}){
	  $k2ml{$k} +=$k2mlnp{$k}{$r}-$k2varlnp{$k}{$r}/2;
	  #$k2ml{$k} +=$k2mlnp{$k}{$r};
	  $k2varl{$k} +=$k2varlnp{$k}{$r};
	  $repeats=$r;
     }
     $k2ml{$k} = $k2ml{$k}/$repeats;
     $k2varl{$k} =$k2varl{$k}/$repeats;
     if($val_max<$k2ml{$k}){
	  $val_max=$k2ml{$k};
	  $kt_max=$k;
     }
}
$k=0;
#------------ L'(K) and var L'(K) from k=min +1 to k=n
for ($k=$k_min+1;$k<=$k_max;$k++){
     $k2lprime{$k} = $k2ml{$k} - $k2ml{$k-1};
     $k2varlprime{$k} = $k2varl{$k} - $k2varl{$k-1};
}
#------------ L"(K) and var L"(K)
for ($k=$k_min+1;$k<$k_max;$k++){
     $k2lsecond{$k} = abs($k2lprime{$k+1} - $k2lprime{$k});
     $k2varlsecond{$k} = abs($k2varlprime{$k+1} - $k2varlprime{$k});
}
#------------ Delta K
for ($k=$k_min+1;$k<$k_max;$k++){
     $k2deltaK{$k} = $k2lsecond{$k} / $k2varl{$k};
}

#------------------- print all ----------------------------------
print "max mean ln L\tfor K\n";
print "$val_max\t$kt_max\n";
print "K\tmean m(ln L)\tmeans var L(K)\tL\'(K)\tvar L\'(K)\tL\"(K)\tvar L\"(K)\tK\tdelta Κ\n";
$k=0;
for ($k=$k_min;$k<=$k_max;$k++){
     print "$k\t$k2ml{$k}\t$k2varl{$k}\t";
     if(exists($k2lprime{$k})){print "$k2lprime{$k}\t$k2varlprime{$k}\t";}else{print "\t\t";}
     if(exists($k2lsecond{$k})){print "$k2lsecond{$k}\t$k2varlsecond{$k}\t";}else{print "\t\t";}
     print "$k\t";
     if(exists($k2deltaK{$k})){print "$k2deltaK{$k}\n";}else{print "\n";}
}
###################### end based on mean  ln likelihood  #########################################


print "K\tfile Run name\trepeat\tLnP(D)\tmln L\tVar[LnP(D)]\n";
$k=0;
foreach $k (sort { $a <=> $b } keys %k2file){
     $r=0;
     foreach $r (sort { $a <=> $b } keys %{$k2file{$k}}){
	  print "$k\t$k2file{$k}{$r}\t$r\t$k2lnp{$k}{$r}\t$k2mlnp{$k}{$r}\t$k2varlnp{$k}{$r}\n";

     }
}

exit 0;
################ end main #################################################################

###########################################
#no executed...
open (SUM, ">summary") || die ("nofile W: summary\n");

print SUM "Parameter Set   Run Name   K   Ln P(D)   Var[LnP(D)]    ?1";
for ($x=$min_pop;$x<=$max_pop;$x++){print SUM "   Fst_$x";}
print SUM "\n\n\n";

for ($pop=$min_pop;$pop<=$max_pop;$pop++){
     for ($iter=1;$iter<=$max_iter;$iter++){
	  $filename= sprintf("%s%02d_%02d_f",$prefix,$pop,$iter);
	  print "$filename\n";
	  open (RES, "<$path/$filename") || die ("nofile R: $path/$filename\n");
	  print SUM "30000_1000000  $filename  $pop";
	  while ($ligne=<RES>){
	       if($ligne =~ /^Estimated Ln Prob of Data/){
		    $ligne=~ s/[\n\r]//g;
		    my @splitted=split(/=/,$ligne);
		    $splitted[1]=~ s/ //g;
		    print SUM "  $splitted[1]";
		    $ligne=<RES>;
		    $ligne=<RES>;
		    $ligne=~ s/[\n\r]//g;
		    if($ligne =~ /^Variance of ln likelihood/){
			 my @splitted=split(/=/,$ligne);
			 $splitted[1]=~ s/ //g;
			 print SUM "  $splitted[1]";
		    }else {die "NO Variance of ln likelihood for results:$filename\n";}
		    $ligne=<RES>;
		    $ligne=~ s/[\n\r]//g;
		    if($ligne =~ /^Mean value of alpha/){
			 my @splitted=split(/=/,$ligne);
			 $splitted[1]=~ s/ //g;
			 print SUM "  $splitted[1]";
			 $ligne=<RES>;
		    }else{print SUM "  -";}
		    for ($x=$min_pop;$x<=$max_pop;$x++){
			 $ligne=<RES>;
			 if($ligne =~ /^Mean value of Fst_/){
			      $ligne=~ s/[\n\r]//g;
			      my @splitted=split(/=/,$ligne);
			      $splitted[1]=~ s/ //g;
			      print SUM "  $splitted[1]";
			 }else {print SUM "  -";}
		    }
		    last;
	       }
	  }
	  close (RES);
	  print SUM "\n";
     }
}

close(SUM);

