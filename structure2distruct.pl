#!/usr/bin/perl -w
#jacques revised 10082012
use Time::HiRes qw[gettimeofday tv_interval];
use Scalar::Util qw(looks_like_number);

my $iter=0;
my $pop=0;
my @names=();
my $filename="";
my $ligne="";

my $max_iter=10;
my $min_pop=1;
my $max_pop=22;
my $path="./para_out";
my $path1="./distruct";

my @str_files=();

my $nb_ind=0;
my $nb_pop=0;
my $nb_k=0;

my $my_str="";
my $f_pop="";
my $f_ind="";
my @ap=();
my $thefile="";

#--------------- MUST be adapted to the system and should be view by all nodes --------
my $distruct_path="/usr/local/bin/distructLinux1.1";
#--------------------------------------------------------------------------------------

#################### pass args #################################
if (($#ARGV+1) != 2 ) {
	print "usage:$0 <Full path of structure outputs> <full path of the district output>\n";
	exit 1;
}
###############################################################
$path=$ARGV[0];
$path1=$ARGV[1];

if (!-e "$distruct_path") {die "ERROR: File \"$distruct_path\" does not exist...\n";}
#/////////////////////// get files  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
#@files = </var/www/htdocs/*.html>;
opendir (MYDIR, "$path") || die ("nodirectory: $path\n");
my @contents = grep !/^\.\.?$/, readdir MYDIR;
closedir MYDIR;
$x=0;
foreach my $listitem ( @contents ){
if (! -d $listitem ){
	if ($listitem =~ /\_01\_f$/){
		$bls_files[$x]=$listitem;
		$x++;
	}
}
}
@str_files = sort { $a cmp $b } @bls_files;

print "found $x results files in $path :\n";
 foreach $thefile ( @str_files ){
 	print "$thefile\n";
}

#///////////////////////////////////////////////////////////////////

foreach $thefile ( @str_files ){
     open (RES, "<$path/$thefile") || die ("nofile R: $path/$thefile\n");
     while ($ligne=<RES>){
		if($ligne =~ /^Run parameters\:/){
			$ligne=<RES>; #378 individuals
				$ligne=~ s/[\n\r]//g;
				@ap=split(/ {1,}/,$ligne);
				$nb_ind=$ap[1];
			$ligne=<RES>; #12 loci
			$ligne=<RES>; #2 populations assumed = k
				$ligne=~ s/[\n\r]//g;
				@ap=split(/ {1,}/,$ligne);
				$nb_k=$ap[1];

		}
	       if($ligne =~ /^Inferred ancestry of individuals\:/){
			open (OUT_IND, ">$path1\/$thefile\.ind") || die ("nofile W: $path1\/$thefile\.ind\n");
			print OUT_IND $my_str;
			$ligne=<RES>;
			while ($ligne=<RES>){
				$ligne=~ s/[\n\r]//g;
				print OUT_IND "$ligne\n";
				if(!$ligne){last;}
			}
			close(OUT_IND);
	       }
	       if($ligne =~ /^ Pop /){
			open (OUT_POP, ">$path1\/$thefile\.pop") || die ("nofile W: $path1\/$thefile\.pop\n");
			$ligne=<RES>;
			$nb_pop=0;
			while ($ligne=<RES>){
				$ligne=~ s/[\n\r]//g;
				if($ligne=~ /^\-\-\-\-\-/){last;}
				#@ap=split(/:/,$ligne);
				#$nb_pop=$ap[0];
				$nb_pop++;
				print OUT_POP "$ligne\n";
			}
			close(OUT_POP);
	       }
     }
     close (RES);
	
     &print_mainparameters($thefile,$nb_ind,$nb_pop,$nb_k);
	print "build figue with: $thefile\.drawparams\n";
	`cd $path1; distructLinux1.1 -d $thefile\.drawparams >$thefile\.distruct.out; cd ..`;
}


#-----------------------------------------------------------

sub print_mainparameters{

my $thefile=$_[0];
my $nb_ind=$_[1];
my $nb_pop=$_[2];
my $nb_k=$_[3];

print "$path1\/$thefile\.drawparams\n";
open (OUT_PAR, ">$path1\/$thefile\.drawparams") || die ("nofile W: $path1\/$thefile\.drawparams\n");

print OUT_PAR "

PARAMETERS FOR THE PROGRAM distruct.  YOU WILL NEED TO SET THESE
IN ORDER TO RUN THE PROGRAM.  

\"(int)\" means that this takes an integer value.
\"(B)\"   means that this variable is Boolean 
        (1 for True, and 0 for False)
\"(str)\" means that this is a string (but not enclosed in quotes) 
\"(d)\"   means that this is a double (a real number).

Data settings
#define INFILE_POPQ        $thefile\.pop // (str) input file of population q's
#define INFILE_INDIVQ      $thefile\.ind  // (str) input file of individual q's
//#define INFILE_LABEL_BELOW names // (str) input file of labels for below figure


#define OUTFILE            $thefile\.ps   //(str) name of output file

#define K       $nb_k    // (int) number of clusters
#define NUMPOPS $nb_pop   // (int) number of pre-defined populations
#define NUMINDS $nb_ind  // (int) number of individuals

Main usage options

#define PRINT_INDIVS      1  // (B) 1 if indiv q's are to be printed, 0 if only population q's
#define PRINT_LABEL_ATOP  1  // (B) print labels above figure
#define PRINT_LABEL_BELOW 1  // (B) print labels below figure
#define PRINT_SEP         1  // (B) print lines to separate populations

Figure appearance

#define FONTHEIGHT 6    // (d) size of font
#define DIST_ABOVE 5    // (d) distance above plot to place text
#define DIST_BELOW -7   // (d) distance below plot to place text
#define BOXHEIGHT  36   // (d) height of the figure
#define INDIVWIDTH 1.5  // (d) width of an individual


Extra options

#define ORIENTATION 1        // (int) 0 for horizontal orientation (default)
                             //       1 for vertical orientation
                             //       2 for reverse horizontal orientation
                             //       3 for reverse vertical orientation
#define XORIGIN 72              // (d) lower-left x-coordinate of figure
#define YORIGIN 288             // (d) lower-left y-coordinate of figure
#define XSCALE 0.5              // (d) scale for x direction
#define YSCALE 0.5              // (d) scale for y direction
#define ANGLE_LABEL_ATOP 60     // (d) angle for labels atop figure (in [0,180])
#define ANGLE_LABEL_BELOW 60    // (d) angle for labels below figure (in [0,180])
#define LINEWIDTH_RIM  3        // (d) width of \"pen\" for rim of box
#define LINEWIDTH_SEP 0.3       // (d) width of \"pen\" for separators between pops and for tics
#define LINEWIDTH_IND 0.3       // (d) width of \"pen\" used for individuals 
#define GRAYSCALE 0             // (B) use grayscale instead of colors
#define ECHO_DATA 1             // (B) print some of the data to the screen
#define REPRINT_DATA 1          // (B) print the data as a comment in the ps file

Command line options:

-d drawparams
-K K
-M NUMPOPS
-N NUMINDS
-p input file (population q's)
-i input file (individual q's)
-a input file (labels atop figure)
-b input file (labels below figure)
-c input file (cluster permutation)
-o output file

";
close(OUT_PAR);

}
