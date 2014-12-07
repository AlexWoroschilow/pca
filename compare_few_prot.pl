# 12 Nov 2014
# To be called by the web server. Compare proteins from one set with all members
# of the second set.

=pod

=head1 NAME

compare_few_prot.pl - Given two sets of proteins, compare all in set A with all in set B

=head1 SYNOPSIS

compare_few_prot.pl PROT1[,PROT2,PROT3,..] PROT_X[,PROT_Y,PROT_Z,...]

=head1 DESCRIPTION

We have a set of reference protein (set A). We have a second set
(B). For each protein in B, we want the distance/difference to each
reference protein.

There may be any number (bigger than zero) of reference
proteins. There may be any nubmer of proteins to be compared against
the reference proteins.

All proteins are given in the form of I<1xyzA> where I<1xyz> is the
pdb acquisition code and I<A> is the chain identifier. This
corresponds with our naming convention for .bin files.

Exactly two comma separated lists should be given. No spaces are
allowed within each list. An invocation might look like

 compare_few_prot.pl 1abcD,1efgH,2defG 1pqrA,2qrsB,5ptiA

In this case, the reference proteins would be I<1abcD>, I<1efgH>,
I<2defG> and the second list would be I<1pqrA>, I<2qrsB>, I<5ptiA>.

=head1 OPTIONS

=over

=item There are not any yet.

=back

=head1 RETURN VALUES

=head2 Happy

How do we give results back to the caller ?

=head2 Unhappy

how do we tell the caller something broke ? If run as a free standing
script, we can use the return value. This script should probably
mutate into a module, in which case we shall return
EXIT_SUCCESS/EXIT_FAILURE.

=head1 NOTES

The exact alignment script that this is based on seems to be
F<~torda/c/wurst/optim/scripts/purestruct_adjust_mshift.pl>.

=cut

use strict;
use warnings;
use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

use FindBin;
use lib "$FindBin::Bin/salamiServer";
use Salamisrvini;

#use lib $LIB_LIB;  #initialize in local Salamisrvini.pm;
#use lib $LIB_ARCH; #initialize in local Salamisrvini.pm;
use lib "$FindBin::Bin/../blib/arch"; # This gives us Wurst.so
use lib "$FindBin::Bin/../lib";       # Gives us Wurst.pm
# ./blib/arch/auto/Wurst/Wurst.so
use Wurst;


# ----------------------- Defaults ---------------------------------
# This script should probably become part of the main script or be
# called by it. These parameters should then be taken from and
# consistent with the main script.
use vars qw (
  $align_type
  $sw1_pgap_open
  $sw1_qgap_open
  $sw1_pgap_widen
  $sw1_qgap_widen
  $m_s_scale
  $m_shift
);

# ----------------------- set_params   ------------------------------

sub set_params ()
{
    *sw1_pgap_open  = \1.07;
    *sw1_pgap_widen = \0.855;
    *sw1_qgap_open  = \$sw1_pgap_open;
    *sw1_qgap_widen = \$sw1_pgap_widen;
    *m_shift        = \-0.885;
    *m_s_scale      = \-0.4501
}

# ----------------------- get_dme_thresh ----------------------------
# This is copied from the server script. When they are persuaded to
# work together, this one should be removed.
# Given an alignment and two proteins, return the thresholded DME
# On error, return 0.0.
sub get_dme_thresh ($ $ $) {
    my ( $pair_set, $c1, $c2 ) = @_;

    my $model = make_model( $pair_set, coord_get_seq($c1), $c2 );
    if (! $model) {   # There is no error message here, since the C code
        return 0.0; } # already prints a warning.
    if ( coord_size($model) < 10 ) {
        return 0.0; }
    my $frac;
    if ( !dme_thresh( $frac, $c1, $model, 3.0 ) ) {
        print STDERR "dme_thresh broke.\n"; }
    return ($frac);
}


# ----------------------- compare_prot ------------------------------
# Given two protein names, try to compare them.
# Return EXIT_FAILURE if something breaks.
# Return an array with results if we are happy.
# The two arguments are probability vectors.
# Args vec1, vec2, coord1, coord2
sub compare_prot ($ $ $ $)
{
    my ($v1, $v2, $c1, $c2) = @_;

    use vars qw ($tiny);
    *tiny = \0.00001;
    my $len_1 = coord_size($c1);
    my $len_2 = coord_size($c2);
    my $matrix = score_mat_new ($len_1, $len_2);
    if (! score_pvec($matrix, $v1, $v2)) {
        return undef; }

    my $smallsize = ($len_1 <= $len_2 ? $len_1 : $len_2);

    my $scaler = $m_s_scale * $smallsize * 0.001;

    $matrix = score_mat_shift($matrix, $m_shift + $scaler);

    my $pair_set = score_mat_sum_smpl( my $crap_mat, $matrix,
                                       $sw1_pgap_open, $sw1_pgap_widen,
                                       $sw1_qgap_open, $sw1_qgap_widen, $S_AND_W );

    my $f_dme = get_dme_thresh ($pair_set, $c1, $c2);
    if ($f_dme < $tiny) {
        return 0.0001;}
#   This next bit determines the value we return
    my ( $str1, $crap )  = pair_set_coverage( $pair_set, coord_size($c1), coord_size($c2) );
    my $coverage = ( $str1 =~ tr/1// );    # This is coverage as an integer
    my $q_scr = $f_dme * $coverage / $smallsize;
    return ($q_scr);
}

# ----------------------- check_prot --------------------------------
# Check a protein name for common problems
sub check_prot ($)
{
    my $p = shift;
    if (length ($p) != 5) {
        print STDERR "\"$p is not 5 characters long\n";
        return EXIT_FAILURE;
    }
#   Add in any checks that might be useful. Does the file exist ?
    return EXIT_SUCCESS;
}

# ----------------------- usage   -----------------------------------
sub usage ()
{
    print STDERR "$0: ref1,ref2,..  prot1,prot2,prot3\n";
}
# ----------------------- mymain  -----------------------------------
sub mymain ()
{
    use Getopt::Std;

    my (%opts);
    my (@ref_prot, @test_prot);
    my $just_testing = 1;
    if ($just_testing) {
        @ref_prot  = ('5ptiA', '4nkpA', '3fpvB', '4mn7A', '9ptiA');
        @test_prot = ('5ptiA', '2qybA', '3oovB');
    } else {
        if ($#ARGV != 1) {
            warn "Wrong number of args\n";
            usage();
            return (EXIT_FAILURE);
        }
        @ref_prot  = split (',', $ARGV[0]);
        @test_prot = split (',', $ARGV[1]);
    }

    set_params();
    my (@ref_c, @ref_v, @test_c, @test_v);

#   Get all the vector files and coordinates read up.
    for ( my $i = 0; $i < @ref_prot; $i++) {
        $ref_c[$i] = coord_read("$OUTPUT_BIN_DIR/$ref_prot[$i].bin");
        $ref_v[$i] = prob_vec_read( "$PVEC_STRCT_DIR/$ref_prot[$i].vec");
    }
    for ( my $i = 0; $i < @test_prot; $i++) {
        $test_c[$i] = coord_read("$OUTPUT_BIN_DIR/$test_prot[$i].bin");
        $test_v[$i] = prob_vec_read( "$PVEC_STRCT_DIR/$test_prot[$i].vec");
    }
#   We now have all the coords and vectors that we will need.    
    my @q_scr;
    for ( my $i = 0; $i < @ref_prot; $i++) {
        for ( my $j = 0; $j < @test_prot; $j++) {
            if ( ! ($q_scr[$i][$j] = compare_prot ($ref_v[$i], $test_v[$j], $ref_c[$i], $test_c[$j]))) {
                print STDERR "unhappy i: $i j: $j"; return (EXIT_FAILURE)} } }
    
    my $debug_till_i_puke = 1;
    if ($debug_till_i_puke) {
        my $fmt_s = ' %6s';
        my $fmt_q = ' %6.2f';
        printf ($fmt_s, ' ');
        for ( my $i = 0; $i < @test_prot; $i++) {
            printf ($fmt_s, coord_name($test_c[$i]));}
        print "\n";
        for ( my $i = 0; $i < @ref_prot; $i++) {
            printf ($fmt_s, coord_name($ref_c[$i]));
            for ( my $j = 0; $j < @test_prot; $j++) {
                printf ($fmt_q, $q_scr[$i][$j]); }
            print "\n";
        }
    }
    
}

# ----------------------- main    -----------------------------------
exit( mymain() );
