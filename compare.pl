#!/usr/bin/perl
use Salami::Compare;

use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

sub mymain () {
  use Getopt::Std;

  # Get ref-Proteins
  # from a first string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_ref = split( ',', $ARGV[0] );

  # get test-Proteins
  # from a second string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_test = split( ',', $ARGV[1] );
  my (@result) = Salami::Compare::proteins( @proteins_ref, @proteins_test );

  my $fmt_s = ' %6s';
  my $fmt_q = ' %6.2f';

  #  printf( $fmt_s, ' ' );

  foreach my $i ( keys @result ) {
    my @row = @{ $result[$i] };
    foreach my $j ( keys @row ) {
      printf( $fmt_q, $result[$i][$j] );
    }
    print("\n");
  }

  #    for ( my $i = 0 ; $i < @proteins_test ; $i++ ) {
  #      printf( $fmt_s, Salami::Compare::name( $test_c[$i] ) );
  #    }
  #    print "\n";
  #    for ( my $i = 0 ; $i < @proteins_ref ; $i++ ) {
  #      printf( $fmt_s, Salami::Compare::name( $ref_c[$i] ) );
  #      for ( my $j = 0 ; $j < @proteins_test ; $j++ ) {
  #        printf( $fmt_q, $q_scr[$i][$j] );
  #      }
  #      print "\n";
  #    }

}

exit( mymain() );
