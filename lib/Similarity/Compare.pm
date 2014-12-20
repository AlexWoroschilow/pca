package Similarity::Compare;
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

sub name {
  my ($id) = @_;
  return coord_name($id);
}

# ----------------------- get_path  ---------------------------------
# Copy-paste from salami_2.pl
# We have a filename and a list of directories where it could
# be. Return the path if we can find it, otherwise return undef.
sub get_path (\@ $) {
  my ( $dirs, $fname ) = @_;
  foreach my $d (@$dirs) {
    my $p = "$d/$fname";
    if ( -f $p ) {
      return $p;
    }
  }
  return undef;
}

# Method to get output folder
# using global var with
# folders or global var with a single one
sub get_path_output ($) {
  my ($file) = @_;
  if ( $DFLT_STRUCT_DIRS and ref($DFLT_STRUCT_DIRS) eq 'ARRAY' ) {
    return get_path( @DFLT_STRUCT_DIRS, $file );
  }
  if ( defined($OUTPUT_BIN_DIR) ) {
    return get_path( ($OUTPUT_BIN_DIR), $file );
  }
  print STDERR ": No global output folder has been defined";
  return (EXIT_FAILURE);
}

# Method to get verctor folder
# using global var with
# folders or global var with a single one
sub get_path_vector ($) {
  my ($file) = @_;
  if ( $DFLT_STRUCT_DIRS and ref($DFLT_STRUCT_DIRS) eq 'ARRAY' ) {
    return get_path( @PVEC_CA_DIRS, $file );
  }
  if ( defined($PVEC_STRCT_DIR) ) {
    return get_path( ($PVEC_STRCT_DIR), $file );
  }
  print STDERR ": No global vector folder has been defined";
  return (EXIT_FAILURE);
}

#
# Method to compare Proteins
#
sub all_to_all (\@\@) {
  my ( $proteins_ref, $proteins_test ) = @_;
  my @proteins_ref  = @$proteins_ref;
  my @proteins_test = @$proteins_test;
  use Getopt::Std;
  my (%opts);
  set_params();
  my ( @ref_c, @ref_v, @test_c, @test_v );

  # Get all the vector files and coordinates read up.
  for ( my $i = 0 ; $i < @proteins_ref ; $i++ ) {
    $ref_c[$i] = coord_read( get_path_output("$proteins_ref[$i].bin") );
    $ref_v[$i] = prob_vec_read( get_path_vector("$proteins_ref[$i].vec") );
  }
  for ( my $i = 0 ; $i < @proteins_test ; $i++ ) {
    $test_c[$i] = coord_read( get_path_output("$proteins_test[$i].bin") );
    $test_v[$i] = prob_vec_read( get_path_vector("$proteins_test[$i].vec") );
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
}
1;
