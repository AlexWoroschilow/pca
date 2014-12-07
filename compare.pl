#!/usr/bin/perl
use Salami::PCA;
use Salami::Compare;
use FindBin qw($Bin);
use Text::Xslate;

use POSIX qw(EXIT_SUCCESS EXIT_FAILURE);

sub mymain () {

  # Replace 1 to 0
  # for production use
  my $testing = 1;

  use Getopt::Std;

  # Get ref-Proteins
  # from a first string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_ref = split( ',', $ARGV[0] );

  # get test-Proteins
  # from a second string
  # like a "4mn7A,3oovB,5ptiA"
  my @proteins_test = split( ',', $ARGV[1] );

  # Replace found proteins
  # with a test proteins
  if ($testing) {
    @proteins_ref = ( '5ptiA', '4nkpA', '3fpvB', '4mn7A', '9ptiA' );
    @proteins_test = ( '5ptiA', '2qybA', '3oovB' );
  }

  # compare proteins all to all
  # get a result as a multidimensional array
  my (@matrix) = Salami::Compare::proteins( @proteins_ref, @proteins_test );

  my $fmt_s = ' %6s';
  my $fmt_q = ' %6.2f';

  printf( $fmt_s, ' ' );
  for ( my $i = 0 ; $i < @proteins_test ; $i++ ) {
    printf( $fmt_s, @proteins_test[$i] );
  }
  print("\n");

  foreach my $i ( keys @matrix ) {
    my @row = @{ $matrix[$i] };
    printf( $fmt_s, @proteins_ref[$i] );
    foreach my $j ( keys @row ) {
      printf( $fmt_q, $matrix[$i][$j] );
    }
    print("\n");
  }

  # Apply PCA to given matrix
  ( my $raw, my $matrix, my $matrixP, my $matrixT ) =
    Salami::PCA::normalized(@matrix);

  #  $raw->print("-->Raw:\n");
  #  $matrix->print("-->Rest:\n");
  #  $matrixP->print("Matrix P: \n");
  #  $matrixT->print("Matrix T: \n");
  my $result = {};
  my ( $m, $n ) = $matrixT->size;
  foreach my $i ( 0 ... ( $m - 1 ) ) {
    $result->{"@proteins_ref[$i]"} = {
      "x" => $matrixT->[$i]->[0],
      "y" => $matrixT->[$i]->[1],
      "z" => $matrixT->[$i]->[2],
    };
  }

  my $xslate = Text::Xslate->new( path => ["$Bin/template"], );
  my $content =
    $xslate->render( "matrix.xslate.xml", { collection => $result } );

  print $content;

}

exit( mymain() );
