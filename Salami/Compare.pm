package Salami::Compare;

use strict;
use warnings;
use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

use FindBin;
use lib "$FindBin::Bin/salamiServer";
use Salamisrvini;

#use lib $LIB_LIB;  #initialize in local Salamisrvini.pm;
#use lib $LIB_ARCH; #initialize in local Salamisrvini.pm;
use lib "$FindBin::Bin/../blib/arch";    # This gives us Wurst.so
use lib "$FindBin::Bin/../lib";          # Gives us Wurst.pm

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

sub set_params () {
  *sw1_pgap_open  = \1.07;
  *sw1_pgap_widen = \0.855;
  *sw1_qgap_open  = \$sw1_pgap_open;
  *sw1_qgap_widen = \$sw1_pgap_widen;
  *m_shift        = \-0.885;
  *m_s_scale      = \-0.4501;
}

# ----------------------- get_dme_thresh ----------------------------
# This is copied from the server script. When they are persuaded to
# work together, this one should be removed.
# Given an alignment and two proteins, return the thresholded DME
# On error, return 0.0.
sub get_dme_thresh ($ $ $) {
  my ( $pair_set, $c1, $c2 ) = @_;

  my $model = make_model( $pair_set, coord_get_seq($c1), $c2 );
  if ( !$model ) {    # There is no error message here, since the C code
    return 0.0;
  }    # already prints a warning.
  if ( coord_size($model) < 10 ) {
    return 0.0;
  }
  my $frac;
  if ( !dme_thresh( $frac, $c1, $model, 3.0 ) ) {
    print STDERR "dme_thresh broke.\n";
  }
  return ($frac);
}

# ----------------------- compare_prot ------------------------------
# Given two protein names, try to compare them.
# Return EXIT_FAILURE if something breaks.
# Return an array with results if we are happy.
# The two arguments are probability vectors.
# Args vec1, vec2, coord1, coord2
sub compare_prot ($ $ $ $) {
  my ( $v1, $v2, $c1, $c2 ) = @_;

  use vars qw ($tiny);
  *tiny = \0.00001;
  my $len_1  = coord_size($c1);
  my $len_2  = coord_size($c2);
  my $matrix = score_mat_new( $len_1, $len_2 );
  if ( !score_pvec( $matrix, $v1, $v2 ) ) {
    return undef;
  }

  my $smallsize = ( $len_1 <= $len_2 ? $len_1 : $len_2 );

  my $scaler = $m_s_scale * $smallsize * 0.001;

  $matrix = score_mat_shift( $matrix, $m_shift + $scaler );

  my $pair_set = score_mat_sum_smpl(
    my $crap_mat,   $matrix,         $sw1_pgap_open, $sw1_pgap_widen,
    $sw1_qgap_open, $sw1_qgap_widen, $S_AND_W
  );

  my $f_dme = get_dme_thresh( $pair_set, $c1, $c2 );
  if ( $f_dme < $tiny ) {
    return 0.0001;
  }

  #   This next bit determines the value we return
  my ( $str1, $crap ) =
    pair_set_coverage( $pair_set, coord_size($c1), coord_size($c2) );
  my $coverage = ( $str1 =~ tr/1// );    # This is coverage as an integer
  my $q_scr = $f_dme * $coverage / $smallsize;
  return ($q_scr);
}

# ----------------------- check_prot --------------------------------
# Check a protein name for common problems
sub check_prot ($) {
  my $p = shift;
  if ( length($p) != 5 ) {
    print STDERR "\"$p is not 5 characters long\n";
    return EXIT_FAILURE;
  }

  #   Add in any checks that might be useful. Does the file exist ?
  return EXIT_SUCCESS;
}

# ----------------------- usage   -----------------------------------
sub usage () {
  print STDERR "$0: ref1,ref2,..  prot1,prot2,prot3\n";
}

sub name {
  my ($id) = @_;
  return coord_name($id);
}

#
# Method to compare Proteins
#
sub proteins (@) {
  my ( $string1, $string2 ) = @_;

  use Getopt::Std;

  my (%opts);

  # Get ref-Proteins
  # from a first string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_ref = split( ',', $string1 );

  # get test-Proteins
  # from a second string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_test = split( ',', $string2 );

  # Replace 1 to 0
  # for production use
  my $testing = 1;

  # Replace found proteins
  # with a test proteins
  if ($testing) {
    @proteins_ref = ( '5ptiA', '4nkpA', '3fpvB', '4mn7A', '9ptiA' );
    @proteins_test = ( '5ptiA', '2qybA', '3oovB' );
  }

  set_params();
  my ( @ref_c, @ref_v, @test_c, @test_v );

  # Get all the vector files and coordinates read up.
  for ( my $i = 0 ; $i < @proteins_ref ; $i++ ) {
    $ref_c[$i] = coord_read("$OUTPUT_BIN_DIR/$proteins_ref[$i].bin");
    $ref_v[$i] = prob_vec_read("$PVEC_STRCT_DIR/$proteins_ref[$i].vec");
  }
  for ( my $i = 0 ; $i < @proteins_test ; $i++ ) {
    $test_c[$i] = coord_read("$OUTPUT_BIN_DIR/$proteins_test[$i].bin");
    $test_v[$i] = prob_vec_read("$PVEC_STRCT_DIR/$proteins_test[$i].vec");
  }

  #   We now have all the coords and vectors that we will need.
  my @q_scr;
  for ( my $i = 0 ; $i < @proteins_ref ; $i++ ) {
    for ( my $j = 0 ; $j < @proteins_test ; $j++ ) {
      if (
        !(
          $q_scr[$i][$j] =
          compare_prot( $ref_v[$i], $test_v[$j], $ref_c[$i], $test_c[$j] )
        )
        )
      {
        print STDERR "unhappy i: $i j: $j";
        return (EXIT_FAILURE);
      }
    }
  }

  return @q_scr;

#  my $debug_till_i_puke = 1;
#  if ($debug_till_i_puke) {
#    my $fmt_s = ' %6s';
#    my $fmt_q = ' %6.2f';
#    printf( $fmt_s, ' ' );
#    for ( my $i = 0 ; $i < @proteins_test ; $i++ ) {
#      printf( $fmt_s, name( $test_c[$i] ) );
#    }
#    print "\n";
#    for ( my $i = 0 ; $i < @proteins_ref ; $i++ ) {
#      printf( $fmt_s, name( $ref_c[$i] ) );
#      for ( my $j = 0 ; $j < @proteins_test ; $j++ ) {
#        printf( $fmt_q, $q_scr[$i][$j] );
#      }
#      print "\n";
#    }
#  }
}

1;
