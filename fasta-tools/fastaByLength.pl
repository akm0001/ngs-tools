#!/usr/bin/perl

# Filter multifasta file by min and max sequence lengths
# adapted from http://seqanswers.com/forums/archive/index.php/t-13966.html
#
# Stephane Plaisance, BITS 2015-02-18

use warnings;
use strict;
use Bio::SeqIO;
use Getopt::Std;

my $usage="## Usage: fastaByLength.pl <-i fasta_file (required)>
# Additional optional parameters are:
# <-o outfile_name (filtered_)>
# <-m minsize (undef)>
# <-x maxsize (undef)>
# <-h to display this help>";

####################
# declare variables
####################
getopts('i:o:m:x:h');
our ($opt_i, $opt_o, $opt_m, $opt_x, $opt_h);

my $infile = $opt_i || die $usage."\n";
my $outfile = $opt_o || "filtered_".$infile;
my $minlen = $opt_m || undef;
my $maxlen = $opt_x || undef;
defined($opt_h) && die $usage."\n";

# right limits
if ( defined $minlen && defined $maxlen && $maxlen < $minlen) {
	print $usage;
	exit();
}

# filehandles
my $seq_in = Bio::SeqIO -> new( -format => 'fasta', -file => $infile );
my $seq_out = Bio::SeqIO -> new( -format => 'Fasta', -file => ">$outfile" );

# counters
my $count = 0;
my $kept = 0;
my $shorter =0;
my $longer = 0;

while( my $seq = $seq_in -> next_seq() ) {
	$count++;
	my $lseq = $seq->length;

	# filter by size
	if (defined $minlen && $lseq < $minlen) {
		$shorter++;
		next;
		}

	if (defined $maxlen && $lseq > $minlen){
		$longer++;
		next;
		}

	# otherwise print out
	$kept++;
	$seq_out -> write_seq($seq);
}

# print counts to stderr
print STDERR "# processed: ".$count." sequences\n";
print STDERR "# too short: ".$shorter." sequences\n";
print STDERR "# too long: ".$longer." sequences\n";
print STDERR "# kept: ".$kept." sequences\n";

exit 0;
