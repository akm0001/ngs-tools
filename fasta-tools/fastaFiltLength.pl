#!/usr/bin/perl

# Filter multifasta file by min and max sequence lengths
# adapted from http://seqanswers.com/forums/archive/index.php/t-13966.html
#
# Stephane Plaisance (VIB-NC+BITS) 2015/02/18; v1.0
# 2015/06/21; v1.1
# supports compressed files (zip, gzip, bgzip)
# 2015/09/29; v1.2
# add total and filtered lengths
#
# 2016/06/01; v2.0
# add bgzipped output and corrected errors
# 2016/08/18; v2.0.1
# add create log file
# 2016/10/13; v2.0.2
# minlen undef small issue l.77
#
# visit our Git: https://github.com/BITS-VIB

use warnings;
use strict;
use Bio::SeqIO;
use Getopt::Std;
use File::Basename;
use File::Which;
use POSIX qw(strftime);

my $version = "2.0.2";
my $date = strftime "%m/%d/%Y", localtime;

my $usage="## Usage: fastaFiltLength.pl <-i fasta_file (required)>
# script version:".$version."
# Additional optional parameters are:
# <-o outfile_name (filtered_)>
# <-m minsize (undef)>
# <-x maxsize (undef)>
# <-z zip results (default OFF)>
# <-h to display this help>";

####################
# declare variables
####################
getopts('i:o:m:x:zh');
our ($opt_i, $opt_o, $opt_m, $opt_x, $opt_z, $opt_h);

my $infile = $opt_i || die $usage."\n";
my $outname = $opt_o || undef;
my $outfile;
my $minlen = $opt_m || undef;
my $maxlen = $opt_x || undef;
my $zipit = defined($opt_z) || undef;
defined($opt_h) && die $usage."\n";

# right limits
if ( defined $minlen && defined $maxlen && $maxlen < $minlen) {
	print $usage;
	exit();
}

# bioperl filehandles
my $in = OpenArchiveFile($infile);
my $out;

# remove possible suffixes from filename
my @sufx = (
	".fa", ".fasta", ".fsa", ".fna",
	".fa.gz", ".fasta.gz", ".fsa.gz", ".fna.gz",
	".fa.zip", ".fasta.zip", ".fsa.zip", ".fna.zip",
	".fa.bz2", ".fasta.bz2", ".fsa.bz2", ".fna.bz2", 
	);
my $outpath = dirname($infile);
my $outbase = basename($infile, @sufx);

# include size limits in file names
if ( defined($outname)) {
	$outfile = $outpath."/".$outname;
} else {
	$outfile = $outpath."/filtered"
		.(defined($minlen) ? "_gt".(int($minlen/1000)) : "")
		.(defined($maxlen) ? "_lt".(int($maxlen/1000)) : "")
		."-".$outbase.".fa";
}

if ( defined($zipit) ) {
	my $bgzip = `which bgzip`;
	die "No bgzip command available\n" unless ( $bgzip );
	chomp($bgzip);
	my $fh;
	open $fh,  " | $bgzip -c >  $outfile\.gz" || die $!;
	$out = Bio::SeqIO->new( -format => 'Fasta', -fh => $fh);
} else {
	$out = Bio::SeqIO -> new( -format => 'Fasta', -file => ">$outfile" );
}
	
# counters
my $count = 0;
my $totlen = 0;
my $kept = 0;
my $keptlen = 0;
my $shorter = 0;
my $longer = 0;

while( my $seq = $in -> next_seq() ) {
	$count++;
	my $lseq = $seq->length;
	$totlen += $lseq;

	# filter by size
	if (defined $minlen && $lseq < $minlen) {
		$shorter++;
		next;
		}

	if (defined $maxlen && $lseq > $maxlen){
		$longer++;
		next;
		}

	# otherwise print out
	$kept++;
	$keptlen += $lseq;
	$out->write_seq($seq);
}

# print counts to stderr
my $summary = "# Fasta length filtering (fastaFiltLength.pl v".$version."), ".$date."\n";
$summary .= "# InputFile: ".basename($infile)."\n";
$summary .= "# OutputFile: ".basename($outfile)."\n";
$summary .= "# processed: ".$count." sequences\n";
$summary .= "# total length: ".$totlen." bps\n";
$summary .= "# too short: ".$shorter." sequences\n";
$summary .= "# too long: ".$longer." sequences\n";
$summary .= "# kept: ".$kept." sequences\n";
$summary .= "# kept length: ".$keptlen." bps\n";

print STDERR $summary;

# also print to log file
open (LOG, ">".$outfile."-log.txt") or die "Can't write to ".$outfile."_fastaFiltLength-log.txt: $!\n";
print LOG $summary;
close LOG;

# cleanup
undef $in;
undef $out;
exit 0;

#### Subs ####
sub OpenArchiveFile {
    my $infile = shift;
    my $FH;
    if ($infile =~ /.fa$|.fasta$|.fna$/) {
    $FH = Bio::SeqIO -> new(-file => "$infile", -format => 'Fasta');
    }
    elsif ($infile =~ /.gz$/) {
    $FH = Bio::SeqIO -> new(-file => "bgzip -cd $infile| ", -format => 'Fasta');
    }
    elsif ($infile =~ /.bz2$/) {
    $FH = Bio::SeqIO -> new(-file => "bzip2 -c $infile| ", -format => 'Fasta');
    }
    elsif ($infile =~ /.zip$/) {
    $FH = Bio::SeqIO -> new(-file => "unzip -p $infile| ", -format => 'Fasta');
    } else {
	die ("$!: do not recognise file type $infile");
	# if this happens, add the file type with correct opening proc
    }
    return $FH;
}
