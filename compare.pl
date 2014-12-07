#!/usr/bin/perl
use Salami::Compare;

use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

sub mymain () {
  use Getopt::Std;

  my $proteins_ref  = $ARGV[0];
  my $proteins_test = $ARGV[1];

  Salami::Compare::proteins( $proteins_ref, $proteins_test );
}

exit( mymain() );
